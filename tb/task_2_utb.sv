`timescale 1ns/1ps
// Standalone unit TB for task_2: feeds task02.mem, checks header + MSE.
module task_2_utb;
  localparam int N = 2048;

  logic clk = 0, rst = 1;
  logic v = 0, f = 0, l = 0;
  logic [15:0] d0 = 0, d1 = 0;
  logic ov, ol;
  logic [31:0] od;

  logic [31:0] mem    [0:N-1];
  logic [31:0] refm   [0:N-1];
  logic [31:0] outmem [0:N+8];
  int k = 0;
  int nlast = 0;

  always #5 clk = ~clk;

  task_2 dut (
    .i_clk(clk), .i_rst(rst),
    .i_valid(v), .i_first(f), .i_last(l),
    .i_data0(d0), .i_data1(d1),
    .o_valid(ov), .o_last(ol), .o_data(od)
  );

  always @(posedge clk) if (ov) begin
    outmem[k] = od;
    if (ol) nlast++;
    k++;
  end

  initial begin
    int i;
    real clean, yout, sse, mse; int fo; fo=$fopen("out.txt","w");
    $readmemh("task02.mem", mem);
    $readmemh("task02_ref.mem", refm);
    repeat (20) @(posedge clk);
    rst <= 0;
    repeat (5) @(posedge clk);
    for (i = 0; i < N; i++) begin
      v <= 1; f <= (i == 0); l <= (i == N-1);
      d0 <= mem[i][15:0]; d1 <= mem[i][31:16];
      @(posedge clk);
    end
    v <= 0; f <= 0; l <= 0;
    // wait for output: header + N samples
    i = 0;
    while (k < N+1 && i < 2000000) begin @(posedge clk); i++; end
    $display("UTB: got %0d beats, o_last pulses=%0d", k, nlast);
    $display("UTB: header=0x%08h", outmem[0]);
    if (outmem[0] !== 32'h01006666)
      $display("UTB: UNEXPECTED HEADER");
    sse = 0;
    for (i = 0; i < N; i++) begin
      clean = $bitstoshortreal(refm[i]);
      yout  = $bitstoshortreal(outmem[i+1]);
      sse  += (yout - clean) * (yout - clean);
    end
    mse = sse / N;
    $display("UTB: MSE = %0e", mse); for (i=0;i<N;i++) $fdisplay(fo, "%08h", outmem[i+1]);
    if (mse < 3.0e-11) $display("UTB: 15pt level"); else if (mse < 3.0e-7) $display("UTB: PASS (<3e-7, 10pt level)");
    else if (mse < 3.0e-3) $display("UTB: 5pt level");
    else $display("UTB: FAIL");
    $finish;
  end

  initial begin
    #200ms;
    $display("UTB: TIMEOUT, beats=%0d", k);
    $finish;
  end
endmodule
