`timescale 1ns / 1ps
// Inverse kinematics via a single time-shared double-rotation CORDIC (arcsine/target-y mode)
// and a serial shift-add multiplier. Packet stored in-place in a 16x32 distributed RAM.
module task_7
#(
  parameter int TASK_INPUT_WIDTH  = 8,
  parameter int TASK_OUTPUT_WIDTH = 8
)(
  input wire                          i_clk,
  input wire                          i_rst,
  input wire                          i_valid,
  input wire                          i_first,
  input wire                          i_last,
  input wire  [TASK_INPUT_WIDTH-1:0]  i_data,
  output logic                         o_valid,
  output logic                         o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);
  localparam int W  = 36;  // Q5.30 datapath, angles Q19.16 degrees
  localparam int F  = 30;
  localparam int MW = 33;  // multiplier operand width
  localparam int N  = 20;  // CORDIC iterations

  localparam logic signed [W-1:0] C_D4  = 36'sd186992139;
  localparam logic signed [W-1:0] C_D5S = 36'sd38725700;
  localparam logic signed [W-1:0] C_K0S = 36'sd30437722;
  localparam logic signed [W-1:0] C_AS  = 36'sd68265842;
  localparam logic signed [W-1:0] C_X2  = 36'sd68101192;
  localparam logic signed [W-1:0] C_X4  = 36'sd1073741824;
  localparam logic signed [W-1:0] C_D90 = 36'sd5898240;
  localparam logic signed [W-1:0] C_D270= 36'sd17694720;
  localparam logic [MW-1:0]       C_C1  = 33'd119151766;
  localparam logic [MW-1:0]       C_C2  = 33'd323118065;

  typedef enum logic [2:0] {S_IN, S_LD, S_PRE, S_ROT, S_END, S_MUL, S_MEND, S_OUT} state_t;
  state_t st;

  logic [31:0] mem [0:15];
  logic [3:0]  cnt, base;
  logic [1:0]  pt, ps, ms;
  logic [5:0]  it;
  logic        ph, dr;
  logic signed [W-1:0] x, y, z, t, u, v, acc;
  logic signed [W:0]   h;
  logic [MW-1:0]       l;

  function automatic logic signed [W-1:0] sx(input logic [31:0] d);
    return {d[17:0], 18'b0};
  endfunction

  logic signed [W-1:0] atan_i;
  always_comb begin
    case (it)
      6'd0:  atan_i = 36'h2d0000;  6'd1:  atan_i = 36'h1a90a7;
      6'd2:  atan_i = 36'h0e0947;  6'd3:  atan_i = 36'h072001;
      6'd4:  atan_i = 36'h03938b;  6'd5:  atan_i = 36'h01ca38;
      6'd6:  atan_i = 36'h00e52a;  6'd7:  atan_i = 36'h007297;
      6'd8:  atan_i = 36'h00394c;  6'd9:  atan_i = 36'h001ca6;
      6'd10: atan_i = 36'h000e53;  6'd11: atan_i = 36'h000729;
      6'd12: atan_i = 36'h000395;  6'd13: atan_i = 36'h0001ca;
      6'd14: atan_i = 36'h0000e5;  6'd15: atan_i = 36'h000073;
      6'd16: atan_i = 36'h000039;  6'd17: atan_i = 36'h00001d;
      6'd18: atan_i = 36'h00000e;  default: atan_i = 36'h000007;
    endcase
  end

  wire signed [W-1:0] xs = x >>> it;
  wire signed [W-1:0] ys = y >>> it;
  wire signed [W-1:0] ts = t >>> {it, 1'b0};
  wire d_now = ph ? dr : (x[W-1] ? (y > 0) : (y > t));

  wire               mlast = (it == MW-1);
  wire signed [W:0]  hs = h + (l[0] ? (mlast ? -{x[W-1], x} : {x[W-1], x}) : '0);
  wire signed [W-1:0] r = {h[W+F-MW-1:0], l[MW-1:F]};

  wire [3:0] a1 = base + 4'd1, a2 = base + 4'd2, a3 = base + 4'd3, a4 = base + 4'd4;
  wire [31:0] zq = z[W-1:4];

  logic        we;
  logic [3:0]  wa;
  logic [31:0] wd;
  always_ff @(posedge i_clk) if (we) mem[wa] <= wd;

  always_comb begin
    we = 1'b0; wa = a1; wd = zq;
    if (st == S_IN) begin we = i_valid; wa = i_first ? 4'd0 : cnt; wd = i_data; end
    else if (st == S_END) begin
      we = 1'b1;
      case (ps) 2'd0: wa = a1; 2'd1: wa = a3; 2'd2: wa = a2; default: wa = a4; endcase
    end
  end

  always_ff @(posedge i_clk) begin
    o_valid <= 1'b0;
    o_last  <= 1'b0;
    if (i_rst) begin
      st <= S_IN; cnt <= '0;
    end else begin
      case (st)
        S_IN: if (i_valid) begin
          cnt <= (i_first ? 4'd0 : cnt) + 4'd1;
          if (i_last) begin st <= S_LD; pt <= '0; base <= '0; end
        end
        S_LD: begin
          x <= sx(mem[a1]); y <= sx(mem[a2]); z <= '0; t <= C_D4; ps <= 2'd0; st <= S_PRE;
        end
        S_PRE: begin
          if (x[W-1]) begin
            if (!y[W-1]) begin x <= y;  y <= -x; z <= z + C_D90; end
            else         begin x <= -y; y <= x;  z <= z - C_D90; end
          end
          it <= '0; ph <= 1'b0; st <= S_ROT;
        end
        S_ROT: begin
          dr <= d_now;
          if (d_now) begin x <= x + ys; y <= y - xs; z <= z + atan_i; end
          else       begin x <= x - ys; y <= y + xs; z <= z - atan_i; end
          ph <= ~ph;
          if (ph) begin
            t <= t + ts; it <= it + 6'd1;
            if (it == N-1) st <= S_END;
          end
        end
        S_END: begin
          case (ps)
            2'd0: begin l <= C_C1; h <= '0; it <= '0; ms <= 2'd0; st <= S_MUL; end
            2'd1: begin acc <= C_D270 - z; t <= x; x <= u; y <= v; z <= '0; ps <= 2'd2; st <= S_PRE; end
            2'd2: begin z <= acc - z; x <= C_X4; y <= '0; t <= -sx(mem[a4]); ps <= 2'd3; st <= S_PRE; end
            default: begin
              if (pt == 2'd2) begin st <= S_OUT; cnt <= '0; end
              else begin pt <= pt + 2'd1; base <= base + 4'd5; st <= S_LD; end
            end
          endcase
        end
        S_MUL: begin
          h <= hs >>> 1; l <= {hs[0], l[MW-1:1]}; it <= it + 6'd1;
          if (mlast) st <= S_MEND;
        end
        S_MEND: begin
          h <= '0; it <= '0; ms <= ms + 2'd1; st <= S_MUL;
          case (ms)
            2'd0: begin u <= r - C_D5S; x <= sx(mem[a3]); l <= C_C2; end
            2'd1: begin v <= C_K0S - r; x <= u; l <= u[MW-1:0]; end
            2'd2: begin t <= r - C_AS;  x <= v; l <= v[MW-1:0]; end
            default: begin t <= t + r; x <= C_X2; y <= '0; z <= C_D90; ps <= 2'd1; st <= S_PRE; end
          endcase
        end
        S_OUT: begin
          o_valid <= 1'b1; o_data <= mem[cnt]; o_last <= (cnt == 4'd14);
          cnt <= cnt + 4'd1;
          if (cnt == 4'd14) begin st <= S_IN; cnt <= '0; end
        end
        default: st <= S_IN;
      endcase
    end
  end
endmodule
