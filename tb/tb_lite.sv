`timescale 1ns / 1ps
import axi_vip_pkg::*;
import axi_vip_0_pkg::*;
import tasks_parameters::*;

module tb_lite();

  // SET YOUR TASK HERE!
  `define TASK_1
  //`define TASK_2
  //`define TASK_3
  //`define TASK_5
  //`define TASK_7
  //`define TASK_8
  //`define TASK_9
  //`define TASK_10
  //`define TASK_11
  //`define TASK_12
  //`define TASK_13
  //`define TASK_14
  //`define TASK_15
  //`define TASK_16

  // SET NUMBER OF INPUT AND OUTPUT SAMPLES FOR SIMULATION
  `ifdef TASK_1
    localparam NUM_SAMPLES_IN  = 6;
    localparam NUM_SAMPLES_OUT = 4;
  `elsif TASK_2
    localparam NUM_SAMPLES_IN  = 4090;
    localparam NUM_SAMPLES_OUT = 2046;
  `elsif TASK_3
    localparam NUM_SAMPLES_IN  = 48;
    localparam NUM_SAMPLES_OUT = 7;
  `elsif TASK_5
    localparam NUM_SAMPLES_IN  = 65;
    localparam NUM_SAMPLES_OUT = 65;
  `elsif TASK_7
    localparam NUM_SAMPLES_IN  = 15;
    localparam NUM_SAMPLES_OUT = 15;
  `elsif TASK_8
    localparam NUM_SAMPLES_IN  = 256;
    localparam NUM_SAMPLES_OUT = 256;
  `elsif TASK_9
    localparam NUM_SAMPLES_IN  = 3;
    localparam NUM_SAMPLES_OUT = 2;
  `elsif TASK_10
    localparam NUM_SAMPLES_IN  = 16;
    localparam NUM_SAMPLES_OUT = 1;
  `elsif TASK_11
    localparam NUM_SAMPLES_IN  = 16;
    localparam NUM_SAMPLES_OUT = 16;
  `elsif TASK_12
    localparam NUM_SAMPLES_IN  = 10;
    localparam NUM_SAMPLES_OUT = 3;
  `elsif TASK_13
    localparam NUM_SAMPLES_IN  = 2;
    localparam NUM_SAMPLES_OUT = 2048;
  `elsif TASK_14
    localparam NUM_SAMPLES_IN  = 2048;
    localparam NUM_SAMPLES_OUT = 1024;
  `elsif TASK_15
    localparam NUM_SAMPLES_IN  = 120;
    localparam NUM_SAMPLES_OUT = 208;
  `elsif TASK_16
    localparam NUM_SAMPLES_IN  = 32;
    localparam NUM_SAMPLES_OUT = 24;
  `endif

  `include "tb_defs.sv";

  localparam NUM_32_BIT_SAMPLES_IN = ceil_div(NUM_SAMPLES_IN, 32/DATA_WIDTH_IN);
  localparam NUM_SAMPLES_WITHIN_32_BIT = 32/DATA_WIDTH_OUT;

  bit clk, reset, start_tests, tasks_done, num_bytes_from_task_valid;
  bit [31:0] enabled_tasks, num_bytes_in_to_task, current_task_number, num_bytes_from_task;

  reg [31:0] readdata;
  reg [DATA_WIDTH_OUT-1:0] readdata_adjusted;
  reg [31:0] task_in  [0:NUM_SAMPLES_IN+10];
  reg [31:0] task_ref [0:NUM_SAMPLES_OUT+10];
  reg [DATA_WIDTH_OUT-1:0] task_out[0:NUM_SAMPLES_OUT+10];

  int err_count = 0;
  int k = 0;
  int num_32_bit_samples_to_read;
  int padding_bytes;
  int num_bytes_to_read;
  int num_samples_in_last_32_bit;

  localparam logic [31:0] SMEM_BASEADDR   = 32'hA000_0000;
  localparam logic [31:0] TASK_IN_OFFSET  = SMEM_BASEADDR;
  localparam logic [31:0] TASK_OUT_OFFSET = SMEM_BASEADDR + 32'h2000;

  axi_vip_0_slv_mem_t slv_agent;

  always #5 clk = ~clk;

  initial begin
    $display ("STARTING TB...");
    setup_soc();
    check_max_words_in();
    $readmemh($sformatf("task%02d.mem",     TASK_NUMBER), task_in);
    $readmemh($sformatf("task%02d_ref.mem", TASK_NUMBER), task_ref);

    reset_soc();
    for (int i=0; i<NUM_32_BIT_SAMPLES_IN+10; i++) begin
      backdoor_mem_write(TASK_IN_OFFSET+4*i, 32'hFFFFFFFF);
    end
    $display("\n******** First iteration ********\n");
    test_task();
    $display("\n******** Second iteration ********\n");
    test_task();
    $display("\n******** Third iteration ********\n");
    test_task();

///////////////// display results //////////////

    $display("---------------------------------------------");
    $display("----          TESTBENCH RESULTS          ----");
    $display("---------------------------------------------");

    if (err_count > 0) begin
        $display("      TEST FAILED!");
        $display("      NUMBER OF MISMATCHES: %d", err_count);
    end else
        $display("      TEST PASSED!");

    #10us $display("      Testbench finished");
    $finish;
  end


  function void check_sample(input reg [DATA_WIDTH_OUT-1:0] task_out_i, input reg [DATA_WIDTH_OUT-1:0] task_ref_j, input int i);
  `ifdef TASK_7
      longint signed diff;
      diff = longint'(signed'(task_out_i)) - longint'(signed'(task_ref_j));
      if (diff < 0) diff = -diff;
      if(diff <= 128)
        $display("      TASK_OUT[%0d]: 0x%0h | TASK_REF[%0d]: 0x%0h | OK! (diff=%0d)", i, task_out_i, i, task_ref_j, diff);
      else begin
        $display("      TASK_OUT[%0d]: 0x%0h | TASK_REF[%0d]: 0x%0h | MISMATCH! (diff=%0d)", i, task_out_i, i, task_ref_j, diff);
        err_count++;
      end
   `elsif TASK_13
      longint signed diff;
      diff = longint'(signed'(task_out_i)) - longint'(signed'(task_ref_j));
      if (diff < 0) diff = -diff;
      if(diff <= 1)
        $display("      TASK_OUT[%0d]: 0x%0h | TASK_REF[%0d]: 0x%0h | OK! (diff=%0d)", i, task_out_i, i, task_ref_j, diff);
      else begin
        $display("      TASK_OUT[%0d]: 0x%0h | TASK_REF[%0d]: 0x%0h | MISMATCH! (diff=%0d)", i, task_out_i, i, task_ref_j, diff);
        err_count++;
      end
  `else
    if (!(task_out_i === task_ref_j)) begin
      $display("      TASK_OUT[%0d]: 0x%0h | TASK_REF[%0d]: 0x%0h | MISMATCH!", i, task_out_i, i, task_ref_j);
      err_count++;
    end
  `endif
  endfunction

  function void check_max_words_in();
    if (NUM_SAMPLES_IN > MAX_SAMPLES_IN)
      $fatal(1, "NUM_SAMPLES_IN is bigger than MAX_SAMPLES_IN parameter declared for this task in task_parameters.svh!");
  endfunction

  function int ceil_div(input int x, input int y);
    if (y == 0) begin
        $fatal(1, "Division by zero error");
    end
    return (x % y == 0) ? (x / y) : (x / y + 1);
  endfunction

  function void round_x_to_mult_y(input int x, input int y, output int padding, output int rounded_x);
    int rem;
    rem       = x % y;
    rounded_x = (rem == 0) ? x : x + (y - rem);
    padding   = (y - rem) % y;
    endfunction

  task write_tv_in_to_smem();
    for (int i=0; i<NUM_32_BIT_SAMPLES_IN; i++) begin
      backdoor_mem_write(TASK_IN_OFFSET+4*i, task_in[i]);
    end
  endtask

  task wait_for_tasks_done();
    wait(tasks_done);
  endtask

  task reset_soc();
    reset <= 1'b1;
    repeat(17) @(posedge clk);
    reset <= 1'b0;
    #2000ns;
`ifdef TASK_8
    #150us;
`endif
  endtask

  task setup_soc();
    fork
      slv_start_stimulus();
    join_none;
  endtask

  task read_data_from_smem();
    for (int i=0; i<num_32_bit_samples_to_read; i++) begin
      backdoor_mem_read(TASK_OUT_OFFSET+4*i, readdata);
      if(i == num_32_bit_samples_to_read-1) begin
        $display("\n      TASK LATENCY: %0d clock cycles", readdata);
      end else if (i == num_32_bit_samples_to_read-2) begin
        for(int j=0; j<num_samples_in_last_32_bit; j++) begin
          readdata_adjusted = readdata >> DATA_WIDTH_OUT*j;
          $display("      OUTPUT SAMPLE [%0d], 0x%0h", k, readdata_adjusted);
          task_out[k] = readdata_adjusted;
          k++;
        end
      end else begin
        for(int j=0; j<NUM_SAMPLES_WITHIN_32_BIT; j++) begin
          readdata_adjusted = readdata >> DATA_WIDTH_OUT*j;
          $display("      OUTPUT SAMPLE [%0d], 0x%0h", k, readdata_adjusted);
          task_out[k] = readdata_adjusted;
          k++;
        end
      end
    end
  endtask

  task set_reg_num_bytes_to_task();
    num_bytes_in_to_task <= NUM_SAMPLES_IN*(DATA_WIDTH_IN/8);
  endtask

  task set_reg_current_task_number();
    current_task_number <= TASK_NUMBER;
  endtask

  task set_start_tests();
    @(posedge clk);
    start_tests <= 1'b1;
    @(posedge clk);
    start_tests <= 1'b0;
  endtask

  task read_reg_num_bytes_from_task();
    wait (num_bytes_from_task_valid);
    $display("      NUM_BYTES_FROM_TASK: %0d", num_bytes_from_task);
  endtask

  task calc_number_of_samples();
    round_x_to_mult_y(num_bytes_from_task, 4, padding_bytes, num_bytes_to_read);
    num_bytes_to_read += 4;
    num_32_bit_samples_to_read = num_bytes_to_read/4;
    num_samples_in_last_32_bit = NUM_SAMPLES_WITHIN_32_BIT - (padding_bytes * 8/DATA_WIDTH_OUT);
  endtask


  task compare_task_2_mse();
    real sse_out, mse_out;
    real yin, yout, clean;
    int i;
    localparam real scale = 32768.0;
    localparam real max_mse = 3.0e-3;

    sse_out = 0.0;

    $display("      TASK_2 HEADER: 0x%0h", task_out[0]);
    if (task_out[0] === 32'h01007171)
      $display("      TASK_2 input format: FIXED POINT (Q1.15)");
    else if (task_out[0] === 32'h01006666)
      $display("      TASK_2 input format: FLOAT");
    else if (task_out[0] === 32'h01004949)
      $display("      TASK_2 input format: INTEGER");
    else
      $fatal(1, "TASK_2 HEADER NOT KNOWN");

    for (i = 0; i < NUM_SAMPLES_OUT-1; i++) begin
      clean = $bitstoshortreal(task_ref[i]);
      yin   = $signed(task_in[i][15:0]) / scale;

      if (task_out[0] === 32'h01007171)
        yout = $signed(task_out[i+1][15:0]) / 32768.0;
      else if (task_out[0] === 32'h01006666)
        yout = $bitstoshortreal(task_out[i+1]);
      else
        yout = $signed(task_out[i+1][15:0]) / scale;

      sse_out += (yout - clean) * (yout - clean);
    end

    mse_out = sse_out / real'(NUM_SAMPLES_OUT-1);
    $display("      TASK_2 MSE out=%0f", mse_out);
    if (!(mse_out < max_mse)) begin
      $display("      TASK_2 MSE above treshold");
      err_count++;
    end else
      $display("      TASK_2 MSE below treshold");
  endtask

  task compare_task_out_with_task_ref();
  `ifdef TASK_2
      compare_task_2_mse();
  `else
      for(int i=0; i<NUM_SAMPLES_OUT; i++) begin
          check_sample(task_out[i], task_ref[i], i);
      end
  `endif
  endtask

  task test_task();
    task_out = '{default:'bx};
    k = 0;
    write_tv_in_to_smem();
    set_reg_num_bytes_to_task();
    set_reg_current_task_number();
    set_start_tests();
    read_reg_num_bytes_from_task();
    wait_for_tasks_done();
    #100us calc_number_of_samples();
    read_data_from_smem();
    compare_task_out_with_task_ref();
    #100us;
  endtask

  task slv_start_stimulus();
    tb_lite.DUT.s_axi_vip.inst.IF.set_xilinx_reset_check_to_warn();
    tb_lite.DUT.s_axi_vip.inst.IF.PC.set_fatal_to_warnings();
    slv_agent = new("s_axi_agent",tb_lite.DUT.s_axi_vip.inst.IF);
    slv_agent.set_agent_tag("AXI_VIP");
    slv_agent.set_verbosity(0);  //or 400 for verbose
    slv_agent.start_slave();
    user_gen_wready();
  endtask

  task user_gen_wready();
    axi_ready_gen wready_gen;
    wready_gen = slv_agent.wr_driver.create_ready("wready");
    wready_gen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE); //XIL_AXI_READY_GEN_OSC
    // wready_gen.set_low_time(1);
    // wready_gen.set_high_time(2);
    slv_agent.wr_driver.send_wready(wready_gen);
  endtask

  task backdoor_mem_write(input xil_axi_ulong addr, input bit [32-1:0] wr_data,
                          input bit [(32/8)-1:0] wr_strb = {(32/8){1'b1}});
    slv_agent.mem_model.backdoor_memory_write(addr, wr_data, wr_strb);
  endtask

  task backdoor_mem_read(input xil_axi_ulong mem_rd_addr, output bit [32-1:0] mem_rd_data);
    mem_rd_data = slv_agent.mem_model.backdoor_memory_read(mem_rd_addr);
  endtask

  control_wrapper_tb #(
    .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32)
  ) DUT (
    .clk                    (clk),
    .reset                  (reset),
    .enabled_tasks          (enabled_tasks),
    .num_bytes_in_to_task   (num_bytes_in_to_task),
    .start_tests            (start_tests),
    .current_task_number    (current_task_number),
    .tasks_done             (tasks_done),
    .num_bytes_out_from_task      (num_bytes_from_task),
    .num_bytes_out_from_task_valid(num_bytes_from_task_valid)
  );

endmodule
