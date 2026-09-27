// tb_serial_frame_extender.sv
`timescale 1ns/1fs

module tb_serial_frame_extender;

  // DUT I/O
  logic clk64;
  logic rst_n;
  logic in_clk;
  logic in_data;
  wire  out_clk;
  wire  out_data;

  // Instantiate DUT
  serial_frame_extender dut (
    .clk64   (clk64),
    .rst_n   (rst_n),
    .in_clk  (in_clk),
    .in_data (in_data),
    .out_clk (out_clk),
    .out_data(out_data)
  );

  // Instantiate DUT
  tb_serial_frame_extender_sub tb (
    .clk64   (clk64),
    .rst_n   (rst_n),
    .in_clk  (in_clk),
    .in_data (in_data),
    .out_clk (out_clk),
    .out_data(out_data)
  );
   

endmodule
