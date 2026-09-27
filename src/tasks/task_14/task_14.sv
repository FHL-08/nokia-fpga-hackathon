`timescale 1ns / 1ps
module task_14
#(
  parameter int TASK_INPUT_WIDTH  = 16,
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

  localparam logic [4:0] OP_NOP  = 5'd0,  OP_CLRC = 5'd2,  OP_SETC = 5'd3,
                         OP_JMP  = 5'd4,  OP_JNC  = 5'd5,  OP_JC   = 5'd6,
                         OP_LDRM = 5'd8,  OP_STRM = 5'd9,  OP_LDRI = 5'd10,
                         OP_ADD  = 5'd11, OP_SUB  = 5'd12, OP_ROL  = 5'd13,
                         OP_ROR  = 5'd14, OP_SHR  = 5'd15, OP_SHL  = 5'd16,
                         OP_ASHR = 5'd17, OP_NAND = 5'd18, OP_XOR  = 5'd19;

  // Program memory split into even/odd byte banks so the byte stream is written directly
  (* ram_style = "block" *) logic [7:0] pm_lo [512];
  (* ram_style = "block" *) logic [7:0] pm_hi [512];
  (* ram_style = "block" *) logic [7:0] dm    [1024];

  logic        run, dump, ld, c;
  logic [7:0]  r0, r1;
  logic [10:0] cnt;          // load byte address / program counter / dump address
  logic [7:0]  pm_lo_q, pm_hi_q, dma_q, dmb_q;

  wire [7:0]  din  = i_data[7:0];
  wire [15:0] ins  = {pm_hi_q, pm_lo_q};
  wire [4:0]  op   = ins[15:11];
  wire [7:0]  rx   = ins[10] ? r1 : r0;
  wire [7:0]  ry   = ins[9]  ? r1 : r0;

  wire load      = ~run & ~dump;
  wire load_we   = load & i_valid;
  wire load_end  = load_we & i_last;
  wire dump_end  = dump & (&cnt[9:0]);

  logic [7:0] res;
  logic       cn, wr, jmp, halt, stall;

  always_comb begin
    res = rx; cn = c; wr = 1'b0; jmp = 1'b0; halt = 1'b0; stall = 1'b0;
    case (op)
      OP_NOP:  ;
      OP_CLRC: cn = 1'b0;
      OP_SETC: cn = 1'b1;
      OP_JMP:  jmp = 1'b1;
      OP_JNC:  jmp = ~c;
      OP_JC:   jmp = c;
      OP_LDRM: begin stall = ~ld; wr = ld; res = dmb_q; end
      OP_STRM: ;
      OP_LDRI: begin wr = 1'b1; res = ins[7:0]; end
      OP_ADD:  begin wr = 1'b1; {cn, res} = {1'b0, rx} + {1'b0, ry} + {8'd0, c}; end
      OP_SUB:  begin wr = 1'b1; {cn, res} = {1'b0, rx} - {1'b0, ry} - {8'd0, c}; end
      OP_ROL:  begin wr = 1'b1; {cn, res} = {rx, rx[7]}; end
      OP_ROR:  begin wr = 1'b1; {res, cn} = {rx[0], rx}; end
      OP_SHR:  begin wr = 1'b1; {res, cn} = {1'b0, rx}; end
      OP_SHL:  begin wr = 1'b1; {cn, res} = {rx, 1'b0}; end
      OP_ASHR: begin wr = 1'b1; {res, cn} = {rx[7], rx}; end
      OP_NAND: begin wr = 1'b1; res = ~(rx & ry); end
      OP_XOR:  begin wr = 1'b1; res = rx ^ ry; end
      default: halt = 1'b1;
    endcase
  end

  wire        stop    = run & halt;
  wire        cnt_clr = load_end | stop | dump_end;
  wire [10:0] cnt_nxt = cnt_clr ? 11'd0 : (run & jmp) ? {2'b00, ins[8:0]} : cnt + 11'd1;
  wire        cnt_en  = load_we | (run & ~stall) | dump;
  wire        pm_en   = ~(run & stall);

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      run <= 1'b0; dump <= 1'b0; ld <= 1'b0; cnt <= '0;
    end else begin
      ld <= run & stall;
      if (cnt_en) cnt <= cnt_nxt;
      if (load_end)      run <= 1'b1;
      else if (stop)     run <= 1'b0;
      if (stop)          dump <= 1'b1;
      else if (dump_end) dump <= 1'b0;
    end
  end

  always_ff @(posedge i_clk) begin
    if (load_end) begin
      r0 <= '0; r1 <= '0; c <= 1'b0;
    end else if (run) begin
      c <= cn;
      if (wr & ~ins[10]) r0 <= res;
      if (wr &  ins[10]) r1 <= res;
    end
  end

  always_ff @(posedge i_clk) begin
    o_valid <= dump;
    o_last  <= dump_end;
  end

  always @(posedge i_clk) begin
    if (load_we & ~cnt[10] & ~cnt[0]) pm_lo[cnt[9:1]] <= din;
    if (load_we & ~cnt[10] &  cnt[0]) pm_hi[cnt[9:1]] <= din;
    if (pm_en) begin
      pm_lo_q <= pm_lo[cnt_nxt[8:0]];
      pm_hi_q <= pm_hi[cnt_nxt[8:0]];
    end
  end

  always @(posedge i_clk) begin
    if (load_we & cnt[10]) dm[cnt[9:0]] <= din;
    dma_q <= dm[cnt[9:0]];
  end

  always @(posedge i_clk) begin
    if (run & (op == OP_STRM)) dm[ins[9:0]] <= rx;
    dmb_q <= dm[ins[9:0]];
  end

  assign o_data = dma_q;

endmodule
