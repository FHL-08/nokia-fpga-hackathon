`timescale 1ns / 1ps

// Cracovian multiplier on 2x2 block-floating-point subcracovians.
// C = A * B (cracovian): C[k][l] = sum_j A[j][l] * B[j][k]
// Blocks arrive column-major; C is emitted column-major (col = A col, row = B col).
// Whole packet is buffered in BRAM, then two row-blocks of one output block are MACed per cycle.
module task_9
#(
  parameter int TASK_INPUT_WIDTH  = 32,
  parameter int TASK_OUTPUT_WIDTH = 32
)(
  input wire                          i_clk,
  input wire                          i_rst,

  input wire                          i_valid,
  input wire                          i_first,
  input wire                          i_last,
  input wire  [TASK_INPUT_WIDTH-1:0]  i_data,

  output logic                         o_valid,
  output logic                         o_first,
  output logic                         o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  localparam int AW = 12;          // up to 4096 buffered samples
  localparam int SW = 15;          // raw 2-term block sum
  localparam int XW = SW + 30;     // exponent-aligned term
  localparam int CW = XW + 6;      // accumulator (up to 32 block terms)

  // sample exponent is a signed 4-bit field: element value = mant * 2^exp
  function automatic logic signed [4:0] sexp(input logic [3:0] e);
    return {e[3], e};
  endfunction

  typedef enum logic [1:0] {S_IN, S_HDR, S_RUN, S_WAIT} state_t;
  state_t st;

  // two copies of the packet: one serves factor A reads, the other factor B;
  // each copy delivers two consecutive row-blocks (j, j+1) per cycle
  logic [31:0] mem_a [0:(1<<AW)-1];
  logic [31:0] mem_b [0:(1<<AW)-1];
  logic [31:0] rd_a, rd_a1, rd_b, rd_b1;
  logic [AW-1:0] wa, ra, rb;
  logic          we;

  always_ff @(posedge i_clk) begin
    if (we) mem_a[wa] <= i_data[31:0];
    rd_a <= mem_a[ra];
  end
  always_ff @(posedge i_clk) rd_a1 <= mem_a[ra + 1'b1];
  always_ff @(posedge i_clk) begin
    if (we) mem_b[wa] <= i_data[31:0];
    rd_b <= mem_b[rb];
  end
  always_ff @(posedge i_clk) rd_b1 <= mem_b[rb + 1'b1];

  // configuration
  logic [7:0] n_pair, n_rows, n_ca, n_cb;
  logic [6:0] R, PA, PB;           // block counts
  logic [AW-1:0] par;              // PA*R: size of factor A in samples

  // loop state
  logic [7:0]    pr;
  logic [6:0]    jb, kb, lb;
  logic [AW-1:0] a_col, b_col, b_base;

  wire last_j = (jb + 2 >= R);
  wire last_k = (kb == PB - 1);
  wire last_l = (lb == PA - 1);
  wire last_p = (pr == n_pair - 1);

  // pipeline tags: issue -> ram -> mul -> acc -> norm -> out
  logic [3:0] v_p, f_p, l_p, e_p;
  logic       h1;                // second row-block lane valid (stage 1) // valid/first-term/last-term/final per stage

  assign we = (st == S_IN) && i_valid;

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      st <= S_IN; wa <= '0; v_p[0] <= 1'b0; f_p[0] <= 1'b0; l_p[0] <= 1'b0; e_p[0] <= 1'b0;
    end else begin
      v_p[0] <= 1'b0; f_p[0] <= 1'b0; l_p[0] <= 1'b0; e_p[0] <= 1'b0;
      case (st)
        S_IN: if (i_valid) begin
          if (i_first) begin
            {n_pair, n_rows, n_ca, n_cb} <= i_data[31:0];
            wa <= '0;
          end else begin
            wa <= wa + 1'b1;
            if (i_last) st <= S_HDR;
          end
        end
        S_HDR: begin
          R  <= n_rows[7:1];
          PA <= n_ca[7:1];
          PB <= n_cb[7:1];
          par <= AW'(n_rows[7:1]) * AW'(n_ca[7:1]);
          pr <= '0; jb <= '0; kb <= '0; lb <= '0;
          a_col <= '0;
          st <= (n_pair == 0 || n_rows[7:1] == 0 || n_ca[7:1] == 0 || n_cb[7:1] == 0) ? S_WAIT : S_RUN;
        end
        S_RUN: begin
          v_p[0] <= 1'b1;
          f_p[0] <= (jb == 0);
          l_p[0] <= last_j;
          e_p[0] <= last_j && last_k && last_l && last_p;
          h1     <= (jb + 1 < R);
          if (!last_j) jb <= jb + 2'd2;
          else begin
            jb <= '0;
            if (!last_k) begin
              kb <= kb + 1'b1; b_col <= b_col + R;
            end else begin
              kb <= '0;
              if (!last_l) begin
                lb <= lb + 1'b1; a_col <= a_col + R; b_col <= b_base;
              end else begin
                lb <= '0;
                // next pair starts right after the last B column
                a_col <= b_col + R; b_base <= b_col + R + par; b_col <= b_col + R + par;
                pr <= pr + 1'b1;
                if (last_p) st <= S_WAIT;
              end
            end
          end
        end
        S_WAIT: if (o_valid && o_last) st <= S_IN;
      endcase
      if (st == S_HDR) begin
        b_base <= AW'(n_rows[7:1]) * AW'(n_ca[7:1]);
        b_col  <= AW'(n_rows[7:1]) * AW'(n_ca[7:1]);
      end
    end
  end

  assign ra = we ? wa : a_col + jb;
  assign rb = we ? wa : b_col + jb;

  // stage 1: RAM output registered; forward tags
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      v_p[3:1] <= '0; f_p[3:1] <= '0; l_p[3:1] <= '0; e_p[3:1] <= '0;
    end else begin
      v_p[3:1] <= v_p[2:0]; f_p[3:1] <= f_p[2:0]; l_p[3:1] <= l_p[2:0]; e_p[3:1] <= e_p[2:0];
    end
  end

  function automatic logic signed [6:0] mant(input logic [31:0] w, input int r, input int c);
    return w[4 + 7*(2*r + c) +: 7];
  endfunction

  // stage 2: products, block sum per output element (shared exponent)
  // Cblk[r][c] = A[0][c]*B[0][r] + A[1][c]*B[1][r]
  logic signed [SW-1:0] s2 [0:3];
  logic signed [SW-1:0] t2 [0:3];
  logic signed [5:0]    e2, g2;
  always_ff @(posedge i_clk) begin
    for (int r = 0; r < 2; r++)
      for (int c = 0; c < 2; c++) begin
        s2[2*r+c] <= mant(rd_a,0,c) * mant(rd_b,0,r) + mant(rd_a,1,c) * mant(rd_b,1,r);
        t2[2*r+c] <= h1 ? SW'(mant(rd_a1,0,c) * mant(rd_b1,0,r) + mant(rd_a1,1,c) * mant(rd_b1,1,r)) : SW'(0);
      end
    e2 <= sexp(rd_a[3:0]) + sexp(rd_b[3:0]);
    g2 <= h1 ? 6'(sexp(rd_a1[3:0]) + sexp(rd_b1[3:0])) : 6'sd0;
  end

  // stage 3: align and accumulate
  logic signed [CW-1:0] acc [0:3];
  always_ff @(posedge i_clk) begin
    for (int i = 0; i < 4; i++) begin
      if (v_p[1])
        acc[i] <= (f_p[1] ? CW'(0) : acc[i])
                + (e2 >= 0 ? CW'(s2[i]) <<< e2  : CW'(s2[i]) >>> (-e2))
                + (g2 >= 0 ? CW'(t2[i]) <<< g2  : CW'(t2[i]) >>> (-g2));
    end
  end

  // stage 4: block exponent = smallest shift so every element fits signed 7 bits
  logic signed [CW-1:0] n4 [0:3];
  logic [5:0]           sh4;
  logic                 v4, e4;
  always_ff @(posedge i_clk) begin
    logic [CW-1:0] m;
    logic [5:0]    n;
    m = '0;
    for (int i = 0; i < 4; i++) m = m | (acc[i][CW-1] ? ~acc[i] : acc[i]);
    n = 0;
    for (int b = 0; b < CW; b++) if (m[b]) n = 6'(b + 1);
    sh4 <= (n > 6) ? n - 6'd6 : 6'd0;
    for (int i = 0; i < 4; i++) n4[i] <= acc[i];
    v4 <= !i_rst && v_p[2] && l_p[2];
    e4 <= e_p[2];
  end

  // stage 5: output
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      o_valid <= 1'b0; o_first <= 1'b0; o_last <= 1'b0; o_data <= '0;
    end else if (st == S_HDR) begin
      o_valid <= 1'b1; o_first <= 1'b1;
      o_last  <= (n_pair == 0 || n_rows[7:1] == 0 || n_ca[7:1] == 0 || n_cb[7:1] == 0);
      o_data  <= {n_pair, n_cb, 8'h00, n_ca};
    end else begin
      o_valid <= v4; o_first <= 1'b0; o_last <= v4 && e4;
      if (sh4 > 15) begin
        for (int i = 0; i < 4; i++) o_data[4 + 7*i +: 7] <= n4[i][CW-1] ? 7'h40 : 7'h3f;
        o_data[3:0] <= 4'd15;
      end else begin
        for (int i = 0; i < 4; i++) o_data[4 + 7*i +: 7] <= 7'(n4[i] >>> sh4);
        o_data[3:0] <= sh4[3:0];
      end
    end
  end

endmodule
