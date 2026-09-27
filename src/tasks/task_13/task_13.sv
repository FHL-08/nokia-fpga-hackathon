`timescale 1ns / 1ps
module task_13
#(
  parameter int TASK_INPUT_WIDTH  = 16,
  parameter int TASK_OUTPUT_WIDTH = 16
)(
  input  wire                         i_clk,
  input  wire                         i_rst,
  input  wire                         i_valid,
  input  wire                         i_first,
  input  wire                         i_last,
  input  wire [TASK_INPUT_WIDTH-1:0]  i_data,
  output logic                        o_valid,
  output logic                        o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  logic [15:0] sine_rom [0:512];
  logic [10:0] phase;
  logic [10:0] period_step;
  logic [10:0] sample_count;
  logic [1:0] shape;
  logic config_pending;
  logic running;

  logic [9:0] sine_address;
  logic sine_negative;
  logic [11:0] triangle_distance;
  logic [15:0] triangle_value;
  logic [15:0] nonsine_value;

  logic [15:0] sine_magnitude_pipe;
  logic sine_negative_pipe;
  logic [1:0] shape_pipe;
  logic [15:0] nonsine_pipe;
  logic valid_pipe;
  logic last_pipe;

  initial begin
    sine_rom[0] = 16'd0;
    sine_rom[1] = 16'd101;
    sine_rom[2] = 16'd201;
    sine_rom[3] = 16'd302;
    sine_rom[4] = 16'd402;
    sine_rom[5] = 16'd503;
    sine_rom[6] = 16'd603;
    sine_rom[7] = 16'd704;
    sine_rom[8] = 16'd804;
    sine_rom[9] = 16'd905;
    sine_rom[10] = 16'd1005;
    sine_rom[11] = 16'd1106;
    sine_rom[12] = 16'd1206;
    sine_rom[13] = 16'd1307;
    sine_rom[14] = 16'd1407;
    sine_rom[15] = 16'd1507;
    sine_rom[16] = 16'd1608;
    sine_rom[17] = 16'd1708;
    sine_rom[18] = 16'd1809;
    sine_rom[19] = 16'd1909;
    sine_rom[20] = 16'd2009;
    sine_rom[21] = 16'd2110;
    sine_rom[22] = 16'd2210;
    sine_rom[23] = 16'd2310;
    sine_rom[24] = 16'd2410;
    sine_rom[25] = 16'd2511;
    sine_rom[26] = 16'd2611;
    sine_rom[27] = 16'd2711;
    sine_rom[28] = 16'd2811;
    sine_rom[29] = 16'd2911;
    sine_rom[30] = 16'd3012;
    sine_rom[31] = 16'd3112;
    sine_rom[32] = 16'd3212;
    sine_rom[33] = 16'd3312;
    sine_rom[34] = 16'd3412;
    sine_rom[35] = 16'd3512;
    sine_rom[36] = 16'd3612;
    sine_rom[37] = 16'd3712;
    sine_rom[38] = 16'd3811;
    sine_rom[39] = 16'd3911;
    sine_rom[40] = 16'd4011;
    sine_rom[41] = 16'd4111;
    sine_rom[42] = 16'd4210;
    sine_rom[43] = 16'd4310;
    sine_rom[44] = 16'd4410;
    sine_rom[45] = 16'd4509;
    sine_rom[46] = 16'd4609;
    sine_rom[47] = 16'd4708;
    sine_rom[48] = 16'd4808;
    sine_rom[49] = 16'd4907;
    sine_rom[50] = 16'd5007;
    sine_rom[51] = 16'd5106;
    sine_rom[52] = 16'd5205;
    sine_rom[53] = 16'd5305;
    sine_rom[54] = 16'd5404;
    sine_rom[55] = 16'd5503;
    sine_rom[56] = 16'd5602;
    sine_rom[57] = 16'd5701;
    sine_rom[58] = 16'd5800;
    sine_rom[59] = 16'd5899;
    sine_rom[60] = 16'd5998;
    sine_rom[61] = 16'd6096;
    sine_rom[62] = 16'd6195;
    sine_rom[63] = 16'd6294;
    sine_rom[64] = 16'd6393;
    sine_rom[65] = 16'd6491;
    sine_rom[66] = 16'd6590;
    sine_rom[67] = 16'd6688;
    sine_rom[68] = 16'd6786;
    sine_rom[69] = 16'd6885;
    sine_rom[70] = 16'd6983;
    sine_rom[71] = 16'd7081;
    sine_rom[72] = 16'd7179;
    sine_rom[73] = 16'd7277;
    sine_rom[74] = 16'd7375;
    sine_rom[75] = 16'd7473;
    sine_rom[76] = 16'd7571;
    sine_rom[77] = 16'd7669;
    sine_rom[78] = 16'd7767;
    sine_rom[79] = 16'd7864;
    sine_rom[80] = 16'd7962;
    sine_rom[81] = 16'd8059;
    sine_rom[82] = 16'd8157;
    sine_rom[83] = 16'd8254;
    sine_rom[84] = 16'd8351;
    sine_rom[85] = 16'd8448;
    sine_rom[86] = 16'd8545;
    sine_rom[87] = 16'd8642;
    sine_rom[88] = 16'd8739;
    sine_rom[89] = 16'd8836;
    sine_rom[90] = 16'd8933;
    sine_rom[91] = 16'd9030;
    sine_rom[92] = 16'd9126;
    sine_rom[93] = 16'd9223;
    sine_rom[94] = 16'd9319;
    sine_rom[95] = 16'd9416;
    sine_rom[96] = 16'd9512;
    sine_rom[97] = 16'd9608;
    sine_rom[98] = 16'd9704;
    sine_rom[99] = 16'd9800;
    sine_rom[100] = 16'd9896;
    sine_rom[101] = 16'd9992;
    sine_rom[102] = 16'd10087;
    sine_rom[103] = 16'd10183;
    sine_rom[104] = 16'd10278;
    sine_rom[105] = 16'd10374;
    sine_rom[106] = 16'd10469;
    sine_rom[107] = 16'd10564;
    sine_rom[108] = 16'd10659;
    sine_rom[109] = 16'd10754;
    sine_rom[110] = 16'd10849;
    sine_rom[111] = 16'd10944;
    sine_rom[112] = 16'd11039;
    sine_rom[113] = 16'd11133;
    sine_rom[114] = 16'd11228;
    sine_rom[115] = 16'd11322;
    sine_rom[116] = 16'd11417;
    sine_rom[117] = 16'd11511;
    sine_rom[118] = 16'd11605;
    sine_rom[119] = 16'd11699;
    sine_rom[120] = 16'd11793;
    sine_rom[121] = 16'd11886;
    sine_rom[122] = 16'd11980;
    sine_rom[123] = 16'd12074;
    sine_rom[124] = 16'd12167;
    sine_rom[125] = 16'd12260;
    sine_rom[126] = 16'd12353;
    sine_rom[127] = 16'd12446;
    sine_rom[128] = 16'd12539;
    sine_rom[129] = 16'd12632;
    sine_rom[130] = 16'd12725;
    sine_rom[131] = 16'd12817;
    sine_rom[132] = 16'd12910;
    sine_rom[133] = 16'd13002;
    sine_rom[134] = 16'd13094;
    sine_rom[135] = 16'd13187;
    sine_rom[136] = 16'd13279;
    sine_rom[137] = 16'd13370;
    sine_rom[138] = 16'd13462;
    sine_rom[139] = 16'd13554;
    sine_rom[140] = 16'd13645;
    sine_rom[141] = 16'd13736;
    sine_rom[142] = 16'd13828;
    sine_rom[143] = 16'd13919;
    sine_rom[144] = 16'd14010;
    sine_rom[145] = 16'd14101;
    sine_rom[146] = 16'd14191;
    sine_rom[147] = 16'd14282;
    sine_rom[148] = 16'd14372;
    sine_rom[149] = 16'd14462;
    sine_rom[150] = 16'd14553;
    sine_rom[151] = 16'd14643;
    sine_rom[152] = 16'd14732;
    sine_rom[153] = 16'd14822;
    sine_rom[154] = 16'd14912;
    sine_rom[155] = 16'd15001;
    sine_rom[156] = 16'd15090;
    sine_rom[157] = 16'd15180;
    sine_rom[158] = 16'd15269;
    sine_rom[159] = 16'd15358;
    sine_rom[160] = 16'd15446;
    sine_rom[161] = 16'd15535;
    sine_rom[162] = 16'd15623;
    sine_rom[163] = 16'd15712;
    sine_rom[164] = 16'd15800;
    sine_rom[165] = 16'd15888;
    sine_rom[166] = 16'd15976;
    sine_rom[167] = 16'd16063;
    sine_rom[168] = 16'd16151;
    sine_rom[169] = 16'd16238;
    sine_rom[170] = 16'd16325;
    sine_rom[171] = 16'd16413;
    sine_rom[172] = 16'd16499;
    sine_rom[173] = 16'd16586;
    sine_rom[174] = 16'd16673;
    sine_rom[175] = 16'd16759;
    sine_rom[176] = 16'd16846;
    sine_rom[177] = 16'd16932;
    sine_rom[178] = 16'd17018;
    sine_rom[179] = 16'd17104;
    sine_rom[180] = 16'd17189;
    sine_rom[181] = 16'd17275;
    sine_rom[182] = 16'd17360;
    sine_rom[183] = 16'd17445;
    sine_rom[184] = 16'd17530;
    sine_rom[185] = 16'd17615;
    sine_rom[186] = 16'd17700;
    sine_rom[187] = 16'd17784;
    sine_rom[188] = 16'd17869;
    sine_rom[189] = 16'd17953;
    sine_rom[190] = 16'd18037;
    sine_rom[191] = 16'd18121;
    sine_rom[192] = 16'd18204;
    sine_rom[193] = 16'd18288;
    sine_rom[194] = 16'd18371;
    sine_rom[195] = 16'd18454;
    sine_rom[196] = 16'd18537;
    sine_rom[197] = 16'd18620;
    sine_rom[198] = 16'd18703;
    sine_rom[199] = 16'd18785;
    sine_rom[200] = 16'd18868;
    sine_rom[201] = 16'd18950;
    sine_rom[202] = 16'd19032;
    sine_rom[203] = 16'd19113;
    sine_rom[204] = 16'd19195;
    sine_rom[205] = 16'd19276;
    sine_rom[206] = 16'd19357;
    sine_rom[207] = 16'd19438;
    sine_rom[208] = 16'd19519;
    sine_rom[209] = 16'd19600;
    sine_rom[210] = 16'd19680;
    sine_rom[211] = 16'd19761;
    sine_rom[212] = 16'd19841;
    sine_rom[213] = 16'd19921;
    sine_rom[214] = 16'd20000;
    sine_rom[215] = 16'd20080;
    sine_rom[216] = 16'd20159;
    sine_rom[217] = 16'd20238;
    sine_rom[218] = 16'd20317;
    sine_rom[219] = 16'd20396;
    sine_rom[220] = 16'd20475;
    sine_rom[221] = 16'd20553;
    sine_rom[222] = 16'd20631;
    sine_rom[223] = 16'd20709;
    sine_rom[224] = 16'd20787;
    sine_rom[225] = 16'd20865;
    sine_rom[226] = 16'd20942;
    sine_rom[227] = 16'd21019;
    sine_rom[228] = 16'd21096;
    sine_rom[229] = 16'd21173;
    sine_rom[230] = 16'd21250;
    sine_rom[231] = 16'd21326;
    sine_rom[232] = 16'd21403;
    sine_rom[233] = 16'd21479;
    sine_rom[234] = 16'd21554;
    sine_rom[235] = 16'd21630;
    sine_rom[236] = 16'd21705;
    sine_rom[237] = 16'd21781;
    sine_rom[238] = 16'd21856;
    sine_rom[239] = 16'd21930;
    sine_rom[240] = 16'd22005;
    sine_rom[241] = 16'd22079;
    sine_rom[242] = 16'd22154;
    sine_rom[243] = 16'd22227;
    sine_rom[244] = 16'd22301;
    sine_rom[245] = 16'd22375;
    sine_rom[246] = 16'd22448;
    sine_rom[247] = 16'd22521;
    sine_rom[248] = 16'd22594;
    sine_rom[249] = 16'd22667;
    sine_rom[250] = 16'd22739;
    sine_rom[251] = 16'd22812;
    sine_rom[252] = 16'd22884;
    sine_rom[253] = 16'd22956;
    sine_rom[254] = 16'd23027;
    sine_rom[255] = 16'd23099;
    sine_rom[256] = 16'd23170;
    sine_rom[257] = 16'd23241;
    sine_rom[258] = 16'd23311;
    sine_rom[259] = 16'd23382;
    sine_rom[260] = 16'd23452;
    sine_rom[261] = 16'd23522;
    sine_rom[262] = 16'd23592;
    sine_rom[263] = 16'd23662;
    sine_rom[264] = 16'd23731;
    sine_rom[265] = 16'd23801;
    sine_rom[266] = 16'd23870;
    sine_rom[267] = 16'd23938;
    sine_rom[268] = 16'd24007;
    sine_rom[269] = 16'd24075;
    sine_rom[270] = 16'd24143;
    sine_rom[271] = 16'd24211;
    sine_rom[272] = 16'd24279;
    sine_rom[273] = 16'd24346;
    sine_rom[274] = 16'd24413;
    sine_rom[275] = 16'd24480;
    sine_rom[276] = 16'd24547;
    sine_rom[277] = 16'd24613;
    sine_rom[278] = 16'd24680;
    sine_rom[279] = 16'd24746;
    sine_rom[280] = 16'd24811;
    sine_rom[281] = 16'd24877;
    sine_rom[282] = 16'd24942;
    sine_rom[283] = 16'd25007;
    sine_rom[284] = 16'd25072;
    sine_rom[285] = 16'd25137;
    sine_rom[286] = 16'd25201;
    sine_rom[287] = 16'd25265;
    sine_rom[288] = 16'd25329;
    sine_rom[289] = 16'd25393;
    sine_rom[290] = 16'd25456;
    sine_rom[291] = 16'd25519;
    sine_rom[292] = 16'd25582;
    sine_rom[293] = 16'd25645;
    sine_rom[294] = 16'd25708;
    sine_rom[295] = 16'd25770;
    sine_rom[296] = 16'd25832;
    sine_rom[297] = 16'd25893;
    sine_rom[298] = 16'd25955;
    sine_rom[299] = 16'd26016;
    sine_rom[300] = 16'd26077;
    sine_rom[301] = 16'd26138;
    sine_rom[302] = 16'd26198;
    sine_rom[303] = 16'd26259;
    sine_rom[304] = 16'd26319;
    sine_rom[305] = 16'd26378;
    sine_rom[306] = 16'd26438;
    sine_rom[307] = 16'd26497;
    sine_rom[308] = 16'd26556;
    sine_rom[309] = 16'd26615;
    sine_rom[310] = 16'd26674;
    sine_rom[311] = 16'd26732;
    sine_rom[312] = 16'd26790;
    sine_rom[313] = 16'd26848;
    sine_rom[314] = 16'd26905;
    sine_rom[315] = 16'd26962;
    sine_rom[316] = 16'd27019;
    sine_rom[317] = 16'd27076;
    sine_rom[318] = 16'd27133;
    sine_rom[319] = 16'd27189;
    sine_rom[320] = 16'd27245;
    sine_rom[321] = 16'd27300;
    sine_rom[322] = 16'd27356;
    sine_rom[323] = 16'd27411;
    sine_rom[324] = 16'd27466;
    sine_rom[325] = 16'd27521;
    sine_rom[326] = 16'd27575;
    sine_rom[327] = 16'd27629;
    sine_rom[328] = 16'd27683;
    sine_rom[329] = 16'd27737;
    sine_rom[330] = 16'd27790;
    sine_rom[331] = 16'd27843;
    sine_rom[332] = 16'd27896;
    sine_rom[333] = 16'd27949;
    sine_rom[334] = 16'd28001;
    sine_rom[335] = 16'd28053;
    sine_rom[336] = 16'd28105;
    sine_rom[337] = 16'd28157;
    sine_rom[338] = 16'd28208;
    sine_rom[339] = 16'd28259;
    sine_rom[340] = 16'd28310;
    sine_rom[341] = 16'd28360;
    sine_rom[342] = 16'd28411;
    sine_rom[343] = 16'd28460;
    sine_rom[344] = 16'd28510;
    sine_rom[345] = 16'd28560;
    sine_rom[346] = 16'd28609;
    sine_rom[347] = 16'd28658;
    sine_rom[348] = 16'd28706;
    sine_rom[349] = 16'd28755;
    sine_rom[350] = 16'd28803;
    sine_rom[351] = 16'd28850;
    sine_rom[352] = 16'd28898;
    sine_rom[353] = 16'd28945;
    sine_rom[354] = 16'd28992;
    sine_rom[355] = 16'd29039;
    sine_rom[356] = 16'd29085;
    sine_rom[357] = 16'd29131;
    sine_rom[358] = 16'd29177;
    sine_rom[359] = 16'd29223;
    sine_rom[360] = 16'd29268;
    sine_rom[361] = 16'd29313;
    sine_rom[362] = 16'd29358;
    sine_rom[363] = 16'd29403;
    sine_rom[364] = 16'd29447;
    sine_rom[365] = 16'd29491;
    sine_rom[366] = 16'd29534;
    sine_rom[367] = 16'd29578;
    sine_rom[368] = 16'd29621;
    sine_rom[369] = 16'd29664;
    sine_rom[370] = 16'd29706;
    sine_rom[371] = 16'd29749;
    sine_rom[372] = 16'd29791;
    sine_rom[373] = 16'd29832;
    sine_rom[374] = 16'd29874;
    sine_rom[375] = 16'd29915;
    sine_rom[376] = 16'd29956;
    sine_rom[377] = 16'd29997;
    sine_rom[378] = 16'd30037;
    sine_rom[379] = 16'd30077;
    sine_rom[380] = 16'd30117;
    sine_rom[381] = 16'd30156;
    sine_rom[382] = 16'd30195;
    sine_rom[383] = 16'd30234;
    sine_rom[384] = 16'd30273;
    sine_rom[385] = 16'd30311;
    sine_rom[386] = 16'd30349;
    sine_rom[387] = 16'd30387;
    sine_rom[388] = 16'd30424;
    sine_rom[389] = 16'd30462;
    sine_rom[390] = 16'd30498;
    sine_rom[391] = 16'd30535;
    sine_rom[392] = 16'd30571;
    sine_rom[393] = 16'd30607;
    sine_rom[394] = 16'd30643;
    sine_rom[395] = 16'd30679;
    sine_rom[396] = 16'd30714;
    sine_rom[397] = 16'd30749;
    sine_rom[398] = 16'd30783;
    sine_rom[399] = 16'd30818;
    sine_rom[400] = 16'd30852;
    sine_rom[401] = 16'd30885;
    sine_rom[402] = 16'd30919;
    sine_rom[403] = 16'd30952;
    sine_rom[404] = 16'd30985;
    sine_rom[405] = 16'd31017;
    sine_rom[406] = 16'd31050;
    sine_rom[407] = 16'd31082;
    sine_rom[408] = 16'd31113;
    sine_rom[409] = 16'd31145;
    sine_rom[410] = 16'd31176;
    sine_rom[411] = 16'd31206;
    sine_rom[412] = 16'd31237;
    sine_rom[413] = 16'd31267;
    sine_rom[414] = 16'd31297;
    sine_rom[415] = 16'd31327;
    sine_rom[416] = 16'd31356;
    sine_rom[417] = 16'd31385;
    sine_rom[418] = 16'd31414;
    sine_rom[419] = 16'd31442;
    sine_rom[420] = 16'd31470;
    sine_rom[421] = 16'd31498;
    sine_rom[422] = 16'd31526;
    sine_rom[423] = 16'd31553;
    sine_rom[424] = 16'd31580;
    sine_rom[425] = 16'd31607;
    sine_rom[426] = 16'd31633;
    sine_rom[427] = 16'd31659;
    sine_rom[428] = 16'd31685;
    sine_rom[429] = 16'd31710;
    sine_rom[430] = 16'd31736;
    sine_rom[431] = 16'd31760;
    sine_rom[432] = 16'd31785;
    sine_rom[433] = 16'd31809;
    sine_rom[434] = 16'd31833;
    sine_rom[435] = 16'd31857;
    sine_rom[436] = 16'd31880;
    sine_rom[437] = 16'd31903;
    sine_rom[438] = 16'd31926;
    sine_rom[439] = 16'd31949;
    sine_rom[440] = 16'd31971;
    sine_rom[441] = 16'd31993;
    sine_rom[442] = 16'd32014;
    sine_rom[443] = 16'd32036;
    sine_rom[444] = 16'd32057;
    sine_rom[445] = 16'd32077;
    sine_rom[446] = 16'd32098;
    sine_rom[447] = 16'd32118;
    sine_rom[448] = 16'd32137;
    sine_rom[449] = 16'd32157;
    sine_rom[450] = 16'd32176;
    sine_rom[451] = 16'd32195;
    sine_rom[452] = 16'd32213;
    sine_rom[453] = 16'd32232;
    sine_rom[454] = 16'd32250;
    sine_rom[455] = 16'd32267;
    sine_rom[456] = 16'd32285;
    sine_rom[457] = 16'd32302;
    sine_rom[458] = 16'd32318;
    sine_rom[459] = 16'd32335;
    sine_rom[460] = 16'd32351;
    sine_rom[461] = 16'd32367;
    sine_rom[462] = 16'd32382;
    sine_rom[463] = 16'd32397;
    sine_rom[464] = 16'd32412;
    sine_rom[465] = 16'd32427;
    sine_rom[466] = 16'd32441;
    sine_rom[467] = 16'd32455;
    sine_rom[468] = 16'd32469;
    sine_rom[469] = 16'd32482;
    sine_rom[470] = 16'd32495;
    sine_rom[471] = 16'd32508;
    sine_rom[472] = 16'd32521;
    sine_rom[473] = 16'd32533;
    sine_rom[474] = 16'd32545;
    sine_rom[475] = 16'd32556;
    sine_rom[476] = 16'd32567;
    sine_rom[477] = 16'd32578;
    sine_rom[478] = 16'd32589;
    sine_rom[479] = 16'd32599;
    sine_rom[480] = 16'd32609;
    sine_rom[481] = 16'd32619;
    sine_rom[482] = 16'd32628;
    sine_rom[483] = 16'd32637;
    sine_rom[484] = 16'd32646;
    sine_rom[485] = 16'd32655;
    sine_rom[486] = 16'd32663;
    sine_rom[487] = 16'd32671;
    sine_rom[488] = 16'd32678;
    sine_rom[489] = 16'd32685;
    sine_rom[490] = 16'd32692;
    sine_rom[491] = 16'd32699;
    sine_rom[492] = 16'd32705;
    sine_rom[493] = 16'd32711;
    sine_rom[494] = 16'd32717;
    sine_rom[495] = 16'd32722;
    sine_rom[496] = 16'd32728;
    sine_rom[497] = 16'd32732;
    sine_rom[498] = 16'd32737;
    sine_rom[499] = 16'd32741;
    sine_rom[500] = 16'd32745;
    sine_rom[501] = 16'd32748;
    sine_rom[502] = 16'd32752;
    sine_rom[503] = 16'd32755;
    sine_rom[504] = 16'd32757;
    sine_rom[505] = 16'd32759;
    sine_rom[506] = 16'd32761;
    sine_rom[507] = 16'd32763;
    sine_rom[508] = 16'd32765;
    sine_rom[509] = 16'd32766;
    sine_rom[510] = 16'd32766;
    sine_rom[511] = 16'd32767;
    sine_rom[512] = 16'd32767;
  end

  always_comb begin
    case (phase[10:9])
      2'b00: begin
        sine_address = {1'b0, phase[8:0]};
        sine_negative = 1'b0;
      end
      2'b01: begin
        sine_address = 10'd512 - {1'b0, phase[8:0]};
        sine_negative = 1'b0;
      end
      2'b10: begin
        sine_address = {1'b0, phase[8:0]};
        sine_negative = 1'b1;
      end
      default: begin
        sine_address = 10'd512 - {1'b0, phase[8:0]};
        sine_negative = 1'b1;
      end
    endcase

    if (phase[10])
      triangle_distance = 12'd2048 - {1'b0, phase};
    else
      triangle_distance = phase;

    if (triangle_distance == 0)
      triangle_value = 16'd0;
    else
      triangle_value = (triangle_distance << 5) - 1'b1;

    if (shape == 2'd2)
      nonsine_value = triangle_value;
    else if (shape == 2'd3)
      nonsine_value = phase[10] ? 16'd32767 : 16'd0;
    else
      nonsine_value = 16'd0;
  end

  always_comb begin
    if (shape_pipe == 2'd1) begin
      if (sine_negative_pipe)
        o_data = TASK_OUTPUT_WIDTH'(-$signed(sine_magnitude_pipe));
      else
        o_data = TASK_OUTPUT_WIDTH'(sine_magnitude_pipe);
    end else begin
      o_data = TASK_OUTPUT_WIDTH'(nonsine_pipe);
    end
    o_valid = valid_pipe;
    o_last = last_pipe;
  end

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      phase <= 11'd0;
      period_step <= 11'd0;
      sample_count <= 11'd0;
      shape <= 2'd0;
      config_pending <= 1'b0;
      running <= 1'b0;
      sine_magnitude_pipe <= 16'd0;
      sine_negative_pipe <= 1'b0;
      shape_pipe <= 2'd0;
      nonsine_pipe <= 16'd0;
      valid_pipe <= 1'b0;
      last_pipe <= 1'b0;
    end else begin
      valid_pipe <= 1'b0;
      last_pipe <= 1'b0;

      if (running) begin
        sine_magnitude_pipe <= sine_rom[sine_address];
        sine_negative_pipe <= sine_negative;
        shape_pipe <= shape;
        nonsine_pipe <= nonsine_value;
        valid_pipe <= 1'b1;
        last_pipe <= sample_count == 11'd2047;
        phase <= phase + period_step;

        if (sample_count == 11'd2047) begin
          sample_count <= 11'd0;
          running <= 1'b0;
        end else begin
          sample_count <= sample_count + 1'b1;
        end
      end else if (i_valid) begin
        if (i_first) begin
          period_step <= i_data[10:0];
          config_pending <= 1'b1;
        end else if (config_pending || i_last) begin
          shape <= i_data[1:0];
          phase <= 11'd0;
          sample_count <= 11'd0;
          config_pending <= 1'b0;
          running <= 1'b1;
        end
      end
    end
  end

endmodule

