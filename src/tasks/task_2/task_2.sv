`timescale 1ns / 1ps
// Self-calibration: x = a + b*T + g*M, T = triangle(+-100, slope 10000/32768).
// M = LPF((x - a - b*T)) / g, output as float32.
module task_2
#(
  parameter int TASK_INPUT_WIDTH  = 16,
  parameter int TASK_OUTPUT_WIDTH = 32
)(
  input wire                          i_clk,
  input wire                          i_rst,
  input wire                          i_valid,
  input wire                          i_first,
  input wire                          i_last,
  input wire  [TASK_INPUT_WIDTH-1:0]  i_data0,
  input wire  [TASK_INPUT_WIDTH-1:0]  i_data1,
  output logic                         o_valid,
  output logic                         o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  localparam logic [31:0]        HDR_FLOAT = 32'h01006666;
  localparam logic signed [31:0] A12       = 32'sd9173256;    // a * 2^12
  localparam logic signed [25:0] BK        = 26'sd14677277;   // b * 2^17
  localparam logic signed [28:0] GI        = 29'sd98189429;   // 2^42 / g
  localparam logic [23:0]        TSTEP     = 24'd10000;
  localparam logic [23:0]        THALF     = 24'd6553600;
  localparam logic [23:0]        TPER      = 24'd13107200;
  localparam int                 HT        = 31;

  function automatic logic signed [25:0] coef_rom(input logic [5:0] k);
    case (k)
      6'd0: coef_rom = 26'sd689;
      6'd1: coef_rom = -26'sd1670;
      6'd2: coef_rom = -26'sd1442;
      6'd3: coef_rom = 26'sd9840;
      6'd4: coef_rom = -26'sd10412;
      6'd5: coef_rom = -26'sd6451;
      6'd6: coef_rom = 26'sd15723;
      6'd7: coef_rom = 26'sd9186;
      6'd8: coef_rom = -26'sd28506;
      6'd9: coef_rom = -26'sd10403;
      6'd10: coef_rom = 26'sd46747;
      6'd11: coef_rom = 26'sd11305;
      6'd12: coef_rom = -26'sd72845;
      6'd13: coef_rom = -26'sd11458;
      6'd14: coef_rom = 26'sd108989;
      6'd15: coef_rom = 26'sd10844;
      6'd16: coef_rom = -26'sd158314;
      6'd17: coef_rom = -26'sd9469;
      6'd18: coef_rom = 26'sd225331;
      6'd19: coef_rom = 26'sd7450;
      6'd20: coef_rom = -26'sd317297;
      6'd21: coef_rom = -26'sd4980;
      6'd22: coef_rom = 26'sd447433;
      6'd23: coef_rom = 26'sd2346;
      6'd24: coef_rom = -26'sd643854;
      6'd25: coef_rom = 26'sd139;
      6'd26: coef_rom = 26'sd979909;
      6'd27: coef_rom = -26'sd2184;
      6'd28: coef_rom = -26'sd1725923;
      6'd29: coef_rom = 26'sd3524;
      6'd30: coef_rom = 26'sd5322071;
      6'd31: coef_rom = 26'sd8384580;
      6'd32: coef_rom = 26'sd5322071;
      6'd33: coef_rom = 26'sd3524;
      6'd34: coef_rom = -26'sd1725923;
      6'd35: coef_rom = -26'sd2184;
      6'd36: coef_rom = 26'sd979909;
      6'd37: coef_rom = 26'sd139;
      6'd38: coef_rom = -26'sd643854;
      6'd39: coef_rom = 26'sd2346;
      6'd40: coef_rom = 26'sd447433;
      6'd41: coef_rom = -26'sd4980;
      6'd42: coef_rom = -26'sd317297;
      6'd43: coef_rom = 26'sd7450;
      6'd44: coef_rom = 26'sd225331;
      6'd45: coef_rom = -26'sd9469;
      6'd46: coef_rom = -26'sd158314;
      6'd47: coef_rom = 26'sd10844;
      6'd48: coef_rom = 26'sd108989;
      6'd49: coef_rom = -26'sd11458;
      6'd50: coef_rom = -26'sd72845;
      6'd51: coef_rom = 26'sd11305;
      6'd52: coef_rom = 26'sd46747;
      6'd53: coef_rom = -26'sd10403;
      6'd54: coef_rom = -26'sd28506;
      6'd55: coef_rom = 26'sd9186;
      6'd56: coef_rom = 26'sd15723;
      6'd57: coef_rom = -26'sd6451;
      6'd58: coef_rom = -26'sd10412;
      6'd59: coef_rom = 26'sd9840;
      6'd60: coef_rom = -26'sd1442;
      6'd61: coef_rom = -26'sd1670;
      6'd62: coef_rom = 26'sd689;
      default: coef_rom = 26'sd0;
    endcase
  endfunction

  function automatic logic [31:0] to_float(input logic signed [31:0] v);
    logic [31:0] m;
    logic [7:0]  e;
    int          p;
    m = v[31] ? -v : v;
    p = 0;
    for (int i = 0; i < 32; i++) if (m[i]) p = i;
    if (m == 0) return 32'd0;
    m = m << (31 - p);
    e = 8'(127 + p - 30);
    return {v[31], e, m[30:8]};
  endfunction

  (* ram_style = "block" *) logic [31:0]        mem_in [0:2047];
  (* ram_style = "block" *) logic signed [31:0] mem_w  [0:2047];

  typedef enum logic [2:0] {S_CAP, S_HDR, S_SEG, S_EV, S_W, S_F, S_OUT} state_t;
  state_t state;

  logic [11:0] cnt;         // samples captured
  logic [11:0] n;           // current sample
  logic [23:0] ph;          // triangle phase accumulator
  logic        mism;        // temperature does not follow the model
  logic [3:0]  wstep;

  // triangle model
  wire  [23:0]        ph_ref = (ph < THALF) ? ph : (TPER - ph);
  wire signed [24:0]  tq     = $signed({1'b0, ph_ref}) - 25'sd3276800;
  wire  [23:0]        ph_nxt = (ph + TSTEP >= TPER) ? ph + TSTEP - TPER : ph + TSTEP;
  wire signed [24:0]  ti_q   = $signed({{9{i_data1[15]}}, i_data1}) <<< 15;
  wire signed [25:0]  tdiff  = ti_q - tq;

  // W pass
  logic [31:0]        rd_in;
  logic signed [24:0] tsel;
  logic signed [50:0] bprod;
  logic signed [15:0] xr;
  logic [11:0]        rdi;
  logic [3:0]         jv, j1, j2;
  logic               p1, p2;
  logic signed [19:0] tsum;
  logic signed [43:0] tavg;
  wire  signed [13:0] widx = $signed({2'b0, n}) - 14'sd4 + $signed({10'b0, jv});
  wire  [11:0]        cidx = (widx < 0) ? 12'd0 :
                             (widx > $signed({2'b0, cnt - 12'd1})) ? cnt - 12'd1 : widx[11:0];


  // piecewise-linear temperature fit: T(n) = (c[k] + sgn[k]*s*n) / 2^F on monotonic segment k
  localparam int F      = 28;
  localparam int MAXSEG = 16;
  localparam int NIT    = 44;
  logic [11:0]        sst  [0:MAXSEG-1];
  logic               ssg  [0:MAXSEG-1];   // 1: rising
  logic signed [15:0] stf  [0:MAXSEG-1];
  logic signed [15:0] stl  [0:MAXSEG-1];
  logic signed [47:0] scc  [0:MAXSEG-1];
  logic               svv  [0:MAXSEG-1];
  logic [4:0]         nseg;
  logic               sovf;
  logic signed [1:0]  sd;
  logic signed [15:0] t0, extv, extp, tprv;
  logic [11:0]        sext;
  logic               fitok;
  // stream reader
  logic [11:0]        ai, i1, i2;
  logic               q1, q2;
  wire  signed [15:0] tr = $signed(rd_in[31:16]);
  // search
  logic [28:0]        slo, shi, m1, m2;
  logic [5:0]         it;
  logic               fin;
  logic [40:0]        acc1, acc2;
  // eval pipeline
  logic [3:0]         ks;
  logic               a_v, a_ex, a_end, b_end;
  logic [3:0]         a_k, b_k, c_k;
  logic signed [47:0] a_u1, a_u2;
  logic signed [47:0] mx1, mn1, mx2, mn2, hx1, hn1, hx2, hn2;
  logic [2:0]         nv, hnv;
  logic               c_v;
  logic signed [47:0] gk1, gk2, cc;
  logic signed [47:0] G1, G2;
  logic               drain;
  logic [3:0]         dcnt;
  // W pass line evaluation
  logic [3:0]         kw;
  logic [40:0]        accw;
  logic signed [47:0] lk, lp, ln, lv;
  wire  [3:0]         kp = kw - 4'd1;
  wire  [3:0]         kn = kw + 4'd1;
  wire                hp = (kw != 4'd0) && svv[kp];
  wire                hn = ({1'b0, kw} + 5'd1 < nseg) && svv[kn];
  wire signed [47:0]  u1w = ($signed({{16{tr[15]}}, tr, 16'd0}) <<< (F - 16));
  wire                sg_s = ssg[ks];
  wire                sbnd = !((sd > 0 && tr >= extv) || (sd < 0 && tr <= extv)) &&
                             ((sd > 0 && tr <= extv - 16'sd2) || (sd < 0 && tr >= extv + 16'sd2));
  wire signed [47:0]  u1 = sg_s ? u1w - $signed({7'd0, acc1}) : u1w + $signed({7'd0, acc1});
  wire signed [47:0]  u2 = sg_s ? u1w - $signed({7'd0, acc2}) : u1w + $signed({7'd0, acc2});
  wire                is_end = (i2 == cnt - 12'd1) || ({1'b0, ks} + 5'd1 < nseg && i2 + 12'd1 == sst[ks + 4'd1]);
  wire signed [47:0]  nmx1 = (!a_v) ? mx1 : (nv == 0 || a_u1 > mx1) ? a_u1 : mx1;
  wire signed [47:0]  nmn1 = (!a_v) ? mn1 : (nv == 0 || a_u1 < mn1) ? a_u1 : mn1;
  wire signed [47:0]  nmx2 = (!a_v) ? mx2 : (nv == 0 || a_u2 > mx2) ? a_u2 : mx2;
  wire signed [47:0]  nmn2 = (!a_v) ? mn2 : (nv == 0 || a_u2 < mn2) ? a_u2 : mn2;
  wire [2:0]          nnv  = (a_v && nv != 3'd4) ? nv + 3'd1 : nv;

  // filter pass
  logic [11:0]        raddr;
  logic signed [31:0] rd_w;
  logic [6:0]         k;
  logic [5:0]         k1, k2;
  logic               v1, v2, v3;
  logic signed [25:0] c2;
  logic signed [57:0] prod3;
  logic signed [63:0] acc;
  logic               edge_s;
  logic signed [31:0] wf;
  logic signed [60:0] rprod;
  logic [2:0]         ostep;

  always_ff @(posedge i_clk) begin
    if (state == S_CAP && i_valid) mem_in[cnt] <= {i_data1, i_data0};
    rd_in <= mem_in[rdi];
    if (state == S_W && wstep == 4'd5)
      mem_w[n] <= ($signed({{4{xr[15]}}, xr, 12'd0}) - A12) - 32'(bprod >>> 20);
    rd_w <= mem_w[raddr];
  end

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      state   <= S_CAP;
      cnt     <= '0;
      n       <= '0;
      ph      <= '0;
      mism    <= 1'b0;
      wstep   <= '0;
      o_valid <= 1'b0;
      o_last  <= 1'b0;
      o_data  <= '0;
      k       <= '0;
      v1 <= 1'b0; v2 <= 1'b0; v3 <= 1'b0;
      acc     <= '0;
      ostep   <= '0;
    end else begin
      o_valid <= 1'b0;
      o_last  <= 1'b0;
      case (state)
        S_CAP: begin
          if (i_valid) begin
            if (tdiff > 26'sd16384 || tdiff < -26'sd16384) mism <= 1'b1;
            ph  <= ph_nxt;
            cnt <= cnt + 12'd1;
            if (i_last) state <= S_HDR;
          end
        end
        S_HDR: begin
          o_valid <= 1'b1;
          o_data  <= HDR_FLOAT;
          n       <= '0;
          ph      <= '0;
          wstep   <= '0;
          jv      <= '0;
          tsum    <= '0;
          p1      <= 1'b0;
          p2      <= 1'b0;
          ai      <= '0;
          q1      <= 1'b0;
          q2      <= 1'b0;
          fitok   <= 1'b0;
          kw      <= '0;
          accw    <= '0;
          state   <= mism ? S_SEG : S_W;
        end
        S_SEG: begin
          if (ai != cnt) begin
            rdi <= ai;
            ai  <= ai + 12'd1;
          end
          q1 <= (ai != cnt);
          i1 <= ai;
          q2 <= q1;
          i2 <= i1;
          if (q2) begin
            tprv <= tr;
            if (i2 == 12'd0) begin
              t0 <= tr; extv <= tr; extp <= tr; sext <= '0; sd <= 2'sd0;
              sst[0] <= '0; stf[0] <= tr; nseg <= 5'd1; sovf <= 1'b0;
            end else if (sd == 2'sd0) begin
              if (tr >= t0 + 16'sd2 || tr <= t0 - 16'sd2) begin
                sd <= (tr > t0) ? 2'sd1 : -2'sd1;
                ssg[0] <= (tr > t0);
                sext <= i2; extv <= tr; extp <= tprv;
              end
            end else if ((sd > 0 && tr >= extv) || (sd < 0 && tr <= extv)) begin
              sext <= i2; extv <= tr; extp <= tprv;
            end else if (sbnd) begin
              if (nseg == 5'(MAXSEG)) sovf <= 1'b1;
              else begin
                stl[nseg[3:0] - 4'd1] <= extp;
                sst[nseg[3:0]] <= sext;
                stf[nseg[3:0]] <= extv;
                ssg[nseg[3:0]] <= (sd < 0);
                nseg <= nseg + 5'd1;
              end
              sd <= -sd;
              sext <= i2; extv <= tr; extp <= tprv;
            end
            if (i2 == cnt - 12'd1) begin
              if (sbnd && i2 != 12'd0 && sd != 2'sd0 && nseg != 5'(MAXSEG)) stl[nseg[3:0]] <= tr;
              else stl[nseg[3:0] - 4'd1] <= tr;
            end
          end
          if (ai == cnt && !q1 && !q2) begin
            slo   <= '0;
            shi   <= 29'h1fffffff;
            m1    <= 29'h0bfffffe;
            m2    <= 29'h14000001;
            dcnt  <= '0;
            it    <= '0;
            fin   <= 1'b0;
            state <= S_EV;
            ai    <= '0;
            acc1  <= '0; acc2 <= '0; ks <= '0;
            nv    <= '0; G1 <= {1'b0, {47{1'b1}}}; G2 <= {1'b0, {47{1'b1}}};
            a_v <= 1'b0; a_end <= 1'b0; b_end <= 1'b0; c_v <= 1'b0; drain <= 1'b0;
          end
        end
        S_EV: begin
          // pass over the packet evaluating feasibility gap for slopes m1, m2
          if (!drain) begin
            if (ai != cnt) begin
              rdi <= ai;
              ai  <= ai + 12'd1;
            end
            q1 <= (ai != cnt);
            i1 <= ai;
            q2 <= q1;
            i2 <= i1;
          end else begin
            q1 <= 1'b0; q2 <= 1'b0;
          end
          // stage A
          a_v   <= q2 && !(tr == stf[ks] || tr == stl[ks]);
          a_end <= q2 && is_end;
          a_k   <= ks;
          a_u1  <= u1;
          a_u2  <= u2;
          if (q2) begin
            acc1 <= acc1 + 41'(m1);
            acc2 <= acc2 + 41'(m2);
            if (is_end && i2 != cnt - 12'd1) ks <= ks + 4'd1;
          end
          // stage B
          if (a_end) begin
            hx1 <= nmx1; hn1 <= nmn1; hx2 <= nmx2; hn2 <= nmn2; hnv <= nnv;
            nv  <= '0;
          end else begin
            mx1 <= nmx1; mn1 <= nmn1; mx2 <= nmx2; mn2 <= nmn2; nv <= nnv;
          end
          b_end <= a_end;
          b_k   <= a_k;
          // stage C
          c_v <= b_end && (hnv == 3'd4);
          c_k <= b_k;
          gk1 <= hn1 - hx1 + (48'sd1 <<< F);
          gk2 <= hn2 - hx2 + (48'sd1 <<< F);
          cc  <= (hx1 + hn1) >>> 1;
          if (b_end && fin) begin
            svv[b_k] <= (hnv == 3'd4);
          end
          // stage D
          if (c_v) begin
            if (gk1 < G1) G1 <= gk1;
            if (gk2 < G2) G2 <= gk2;
            if (fin) scc[c_k] <= cc;
          end
          if (ai == cnt && !q1 && !q2) begin
            drain <= 1'b1;
            dcnt  <= dcnt + 4'd1;
          end else
            dcnt  <= '0;
          if (drain && dcnt == 4'd6) begin
            drain <= 1'b0;
            ai    <= '0;
            acc1  <= '0; acc2 <= '0; ks <= '0; nv <= '0;
            G1 <= {1'b0, {47{1'b1}}}; G2 <= {1'b0, {47{1'b1}}};
            if (fin) begin
              fitok <= !sovf && (sd != 2'sd0) && (G1 >= -(48'sd1 <<< (F - 3))) &&
                       (G1 != {1'b0, {47{1'b1}}});
              accw  <= '0;
              kw    <= '0;
              state <= S_W;
            end else if (it == 6'(NIT)) begin
              fin <= 1'b1;
              m1  <= 29'((30'(slo) + 30'(shi)) >> 1);
              m2  <= 29'((30'(slo) + 30'(shi)) >> 1);
            end else begin
              it <= it + 6'd1;
              if (G1 < G2) begin
                slo <= m1;
                m1  <= m1 + (((shi - m1) >> 2) + ((shi - m1) >> 3));
                m2  <= shi - (((shi - m1) >> 2) + ((shi - m1) >> 3));
              end else begin
                shi <= m2;
                m1  <= slo + (((m2 - slo) >> 2) + ((m2 - slo) >> 3));
                m2  <= m2 - (((m2 - slo) >> 2) + ((m2 - slo) >> 3));
              end
            end
          end
        end
        S_W: begin
          // 9-sample window of i_data1 around n (edge-clamped), then calibrate sample n
          if (jv < 4'd9) begin
            rdi <= cidx;
            jv  <= jv + 4'd1;
          end
          p1 <= (jv < 4'd9);
          j1 <= jv;
          p2 <= p1;
          j2 <= j1;
          if (p2) begin
            tsum <= tsum + $signed(rd_in[31:16]);
            if (j2 == 4'd4) xr <= $signed(rd_in[15:0]);
          end
          if (jv == 4'd9 && !p1 && !p2) begin
            wstep <= wstep + 4'd1;
            case (wstep)
              4'd0: begin
                tavg <= tsum * 24'sd3728270;
                lk   <= ssg[kw] ? scc[kw] + $signed({7'd0, accw}) : scc[kw] - $signed({7'd0, accw});
                lp   <= ssg[kp] ? scc[kp] + $signed({7'd0, accw}) : scc[kp] - $signed({7'd0, accw});
                ln   <= ssg[kn] ? scc[kn] + $signed({7'd0, accw}) : scc[kn] - $signed({7'd0, accw});
              end
              4'd1: begin
                // rising: max with previous line, min with next; falling: the reverse
                if (ssg[kw]) lv <= (hp && lp > lk) ? lp : lk;
                else         lv <= (hp && lp < lk) ? lp : lk;
              end
              4'd2: begin
                if (ssg[kw]) begin if (hn && ln < lv) lv <= ln; end
                else         begin if (hn && ln > lv) lv <= ln; end
              end
              4'd3: tsel <= !mism ? tq : (fitok && svv[kw]) ? 25'(lv >>> (F - 15)) : 25'(tavg >>> 10);
              4'd4: bprod <= tsel * BK;
              4'd5: begin
                wstep <= '0;
                accw  <= accw + 41'(m1);
                if ({1'b0, kw} + 5'd1 < nseg && n + 12'd1 == sst[kn]) kw <= kn;
                jv    <= '0;
                tsum  <= '0;
                ph    <= ph_nxt;
                if (n == cnt - 12'd1) begin
                  n     <= '0;
                  k     <= '0;
                  acc   <= '0;
                  state <= S_F;
                end else
                  n <= n + 12'd1;
              end
              default: ;
            endcase
          end
        end
        S_F: begin
          // pipelined MAC over 63 taps (or pass-through at the edges)
          edge_s <= (n < 12'(HT)) || (n > cnt - 12'd1 - 12'(HT));
          if (k < 7'd63) begin
            raddr <= n - 12'(HT) + 12'(k);
            k     <= k + 7'd1;
          end
          v1 <= (k < 7'd63);
          k1 <= k[5:0];
          v2 <= v1;
          k2 <= k1;
          c2 <= coef_rom(k1);
          v3 <= v2;
          prod3 <= rd_w * c2;
          if (v3) acc <= acc + prod3;
          if (k == 7'd63 && !v1 && !v2 && !v3) begin
            if (edge_s) begin
              raddr <= n;
              state <= S_OUT;
              ostep <= 3'd0;
            end else begin
              wf    <= 32'((acc + 64'sd8388608) >>> 24);
              state <= S_OUT;
              ostep <= 3'd2;
            end
          end
        end
        S_OUT: begin
          ostep <= ostep + 3'd1;
          case (ostep)
            3'd1: wf <= rd_w;
            3'd2: rprod <= wf * GI;
            3'd3: begin
              o_valid <= 1'b1;
              o_data  <= to_float(32'(rprod >>> 24));
              if (n == cnt - 12'd1) begin
                o_last <= 1'b1;
                state  <= S_CAP;
                cnt    <= '0;
                ph     <= '0;
                mism   <= 1'b0;
              end else begin
                n     <= n + 12'd1;
                k     <= '0;
                acc   <= '0;
                state <= S_F;
              end
            end
            default: ;
          endcase
        end
        default: state <= S_CAP;
      endcase
    end
  end

endmodule
