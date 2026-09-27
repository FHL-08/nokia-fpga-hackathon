`timescale 1ns / 1ps
module task_16
#(
  parameter int TASK_INPUT_WIDTH  = 32,
  parameter int TASK_OUTPUT_WIDTH = 32
)(
  input wire                              i_clk,
  input wire                              i_rst,

  input wire                              i_valid,
  output logic                            i_ready,
  input wire                              i_last,
  input wire  [TASK_INPUT_WIDTH-1:0]      i_data,
  input wire  [TASK_INPUT_WIDTH/8-1:0]    i_keep,

  input wire                              o_ready,
  output logic                            o_valid,
  output logic                            o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0]    o_data,
  output logic [TASK_OUTPUT_WIDTH/8-1:0]  o_keep
);

  localparam int INPUT_BYTES = TASK_INPUT_WIDTH / 8;
  localparam int OUTPUT_BYTES = TASK_OUTPUT_WIDTH / 8;
  localparam int BUFFER_BYTES = INPUT_BYTES + OUTPUT_BYTES;
  localparam int BUFFER_WIDTH = BUFFER_BYTES * 8;
  localparam int COUNT_WIDTH = $clog2(BUFFER_BYTES + 1);

  // Valid bytes are packed at the low end; all unused byte lanes are zero.
  // At the default widths this is the same storage as two 32-bit registers.
  logic [BUFFER_WIDTH-1:0] r_data, next_data;
  logic [COUNT_WIDTH-1:0] r_count, next_count;
  logic r_last, next_last;
  logic [COUNT_WIDTH-1:0] input_bytes;
  logic [BUFFER_WIDTH-1:0] input_data;

  always_comb begin
    // Decode keep into a byte count: 0001 -> 1, 0011 -> 2,
    // 0111 -> 3, 1111 -> 4. Padding data must not enter the buffer.
    input_bytes = '0;
    input_data = '0;
    for (int lane = 0; lane < INPUT_BYTES; lane = lane + 1) begin
      if (i_keep[lane]) begin
        input_bytes = input_bytes + 1'b1;
        input_data[lane*8 +: 8] = i_data[lane*8 +: 8];
      end
    end
  end

  always_comb begin
    o_data = r_data[TASK_OUTPUT_WIDTH-1:0];
    o_valid = (r_count >= OUTPUT_BYTES) || (r_last && r_count != 0);
    o_last = o_valid && r_last && (r_count <= OUTPUT_BYTES);
    o_keep = '0;
    for (int lane = 0; lane < OUTPUT_BYTES; lane = lane + 1) begin
      if (lane < r_count)
        o_keep[lane] = 1'b1;
    end
  end

  always_comb begin
    next_data = r_data;
    next_count = r_count;
    next_last = r_last;

    // Remove a word only when the receiver accepts it.
    if (o_valid && o_ready) begin
      next_data = r_data >> TASK_OUTPUT_WIDTH;
      if (r_count > OUTPUT_BYTES)
        next_count = r_count - COUNT_WIDTH'(OUTPUT_BYTES);
      else
        next_count = '0;
      if (o_last)
        next_last = 1'b0;
    end

    // Reserve room for a whole input word, including space freed this cycle.
    // Finish the current packet before accepting bytes from the next one.
    i_ready = !i_rst && !r_last && (next_count <= BUFFER_BYTES - INPUT_BYTES);
    if (i_valid && i_ready) begin
      // The input keep patterns have contiguous valid bytes at the LSB.
      // Shift data by eight bits for each byte already buffered.
      next_data = next_data | (input_data << (next_count * 8));
      next_count = next_count + input_bytes;
      next_last = i_last;
    end
  end

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      r_data <= '0;
      r_count <= '0;
      r_last <= 1'b0;
    end else begin
      r_data <= next_data;
      r_count <= next_count;
      r_last <= next_last;
    end
  end

endmodule
