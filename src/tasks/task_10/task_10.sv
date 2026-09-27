`timescale 1ns / 1ps
// =============================================================================
// task_10 -- Memory-Mapped Device Controller
//
//   0x0..0x7  register file (8x16 LUTRAM, async read)
//   0x8       serial-in shift register (WRITE shifts wdata[0] into LSB)
//   0x9       latch (parallel write / read)
//   0xA       timer count  (WRITE loads start value and starts counting)
//   0xB       timer target (WRITE sets match value)
//   0xC       status {8'h0, hidden_addr[3:0], serin_done, secret_rdy,
//                     tmr_match, tmr_en}
//
// Command sample: READ is a no-op (nothing observable), WRITE arms the data
// phase for the next sample, OUTPUT registers bus_read(addr) to o_data.
// The timer counts every cycle; on count == target it stops, sets the sticky
// match flag and pulses fire, which latches serin[3:0] as hidden_addr.
// =============================================================================
module task_10 #(
    parameter int TASK_INPUT_WIDTH  = 16,
    parameter int TASK_OUTPUT_WIDTH = 16
)(
    input  wire                          i_clk,
    input  wire                          i_rst,

    input  wire                          i_valid,
    input  wire                          i_first,
    input  wire                          i_last,
    input  wire  [TASK_INPUT_WIDTH-1:0]  i_data,

    output logic                         o_valid,
    output logic                         o_last,
    output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  (* ram_style = "distributed" *) logic [15:0] rf [8];
  initial for (int i = 0; i < 8; i++) rf[i] = '0;

  logic        wd;
  logic [3:0]  waddr;
  logic [15:0] serin, latch, tcnt, ttgt;
  logic        serin_done, ten, tfire, tmatch, secret_rdy;
  logic [3:0]  hidden;

  wire [3:0] raddr  = i_data[9:6];
  wire       is_cmd = i_valid & ~wd;
  wire       is_dat = i_valid & ~is_cmd;
  wire       tload  = is_dat & (waddr == 4'hA);
  wire       thit   = ten & (tcnt == ttgt);

  always @(posedge i_clk)
    if (is_dat & ~waddr[3]) rf[waddr[2:0]] <= i_data[15:0];

  always_ff @(posedge i_clk)
    if (is_cmd) waddr <= raddr;

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      wd         <= 1'b0;
      serin      <= '0;
      serin_done <= 1'b0;
      latch      <= '0;
      tcnt       <= '0;
      ttgt       <= '1;
      ten        <= 1'b0;
      tfire      <= 1'b0;
      tmatch     <= 1'b0;
      hidden     <= '0;
      secret_rdy <= 1'b0;
    end else begin
      if (i_valid) wd <= is_cmd & (i_data[15:14] == 2'b01);

      if (is_dat & (waddr == 4'h8)) begin
        serin      <= {serin[14:0], i_data[0]};
        serin_done <= 1'b1;
      end
      if (is_dat & (waddr == 4'h9)) latch <= i_data[15:0];
      if (is_dat & (waddr == 4'hB)) ttgt  <= i_data[15:0];

      tfire <= 1'b0;
      if (tload) begin
        tcnt <= i_data[15:0];
        ten  <= 1'b1;
      end else if (thit) begin
        ten    <= 1'b0;
        tfire  <= 1'b1;
        tmatch <= 1'b1;
      end else if (ten) begin
        tcnt <= tcnt + 16'd1;
      end

      if (tfire) begin
        hidden     <= serin[3:0];
        secret_rdy <= 1'b1;
      end
    end
  end

  logic [15:0] rdata;
  always_comb begin
    unique case (raddr)
      4'h8:    rdata = serin;
      4'h9:    rdata = latch;
      4'hA:    rdata = tcnt;
      4'hB:    rdata = ttgt;
      4'hC:    rdata = {8'h0, hidden, serin_done, secret_rdy, tmatch, ten};
      4'hD, 4'hE, 4'hF: rdata = '0;
      default: rdata = rf[raddr[2:0]];
    endcase
  end

  always_ff @(posedge i_clk) begin
    if (i_rst) o_valid <= 1'b0;
    else       o_valid <= is_cmd & (i_data[15:14] == 2'b11);
    if (is_cmd & (i_data[15:14] == 2'b11)) o_data <= rdata;
  end

  assign o_last = o_valid;

endmodule
