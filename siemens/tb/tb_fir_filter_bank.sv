// =============================================================================
// Testbench    : tb_fir_filter_bank
// Description  : Comprehensive self-checking testbench for fir_filter_bank_top.
//                Drives all 5 test vectors, computes software reference,
//                compares output, and reports pass/fail per vector.
// =============================================================================
`timescale 1ns/1ps

import tb_pkg::*;

module tb_fir_filter_bank;

    // -------------------------------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------------------------------
    localparam real CLK_PERIOD = 10.0; // 100 MHz

    logic clk   = 0;
    logic rst_n = 0;

    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    // DUT Interface signals
    // -------------------------------------------------------------------------
    logic [31:0] s_data;       
    logic        s_valid;
    logic        s_last;
    logic        s_ready;

    logic [31:0] m_data;
    logic        m_valid;
    logic        m_last;
    logic        m_ready;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    fir_filter_bank_top dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .s_data  (s_data),
        .s_valid (s_valid),
        .s_ready (s_ready),
        .m_data  (m_data),
        .m_valid (m_valid),
        .m_last  (m_last),
        .m_ready (m_ready)
    );

    // -------------------------------------------------------------------------
    // Testbench state
    // -------------------------------------------------------------------------
    int  test_num;
    int  pass_count;
    int  fail_count;
    int  total_errors;

    // Output capture buffer
    logic signed [15:0] captured_out [0:4*64-1];
    int                 cap_idx;
    logic               capture_done;

    // -------------------------------------------------------------------------
    // Reference model output buffer
    // -------------------------------------------------------------------------
    logic signed [15:0] ref_out [0:4*64-1];

    // -------------------------------------------------------------------------
    // Task: Apply reset
    // -------------------------------------------------------------------------
    task apply_reset();
        rst_n   = 0;
        s_valid = 0;
        s_data  = 0;
        s_last  = 0;
        m_ready = 1;
        repeat(5) @(posedge clk);
        #1;
        rst_n = 1;
        repeat(2) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Task: Send one 32-bit word on AXI-Stream input
    // -------------------------------------------------------------------------
    task send_word(input logic [31:0] data, input logic last);
        @(posedge clk);
        #1;
        s_data  = data;
        s_valid = 1;
        s_last  = last;
        // s_ready should always be high; just wait one cycle
        @(posedge clk);
        #1;
        s_valid = 0;
        s_last  = 0;
    endtask

    // -------------------------------------------------------------------------
    // Task: Send full input packet for a test vector
    // -------------------------------------------------------------------------
    task send_packet(input test_vector_t tv);
        logic [31:0] word;
        int          N, T, S;
        int          total_coeffs, total_samples;

        N = tv.num_channels;
        T = tv.num_taps;
        S = tv.num_samples;
        total_coeffs  = N * T;
        total_samples = N * S;

        // Header word
        word = {4'(N), 4'b0, 5'(T), 3'b0, 7'(S), 9'b0};
        // Repack properly per spec:
        // [31:24]=N, [23:16]=T, [15:0]=S
        word = {8'(N), 8'(T), 16'(S)};
        send_word(word, 1'b0);

        // Coefficient words (channel-major: ch0 taps, ch1 taps, ...)
        for (int c = 0; c < N; c++) begin
            for (int k = 0; k < T; k++) begin
                word = {16'b0, tv.coeffs[c][k]};
                send_word(word, 1'b0);
            end
        end

        // Sample words (channel-major: ch0 samples, ch1 samples, ...)
        for (int c = 0; c < N; c++) begin
            for (int n = 0; n < S; n++) begin
                logic is_last;
                is_last = (c == N-1) && (n == S-1);
                word    = {16'b0, tv.samples[c][n]};
                send_word(word, is_last);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: Capture output packet
    // -------------------------------------------------------------------------
    task capture_output(input int expected_samples);
        int  timeout;
        int  idx;

        idx     = 0;
        timeout = 10000;

        // Wait for output header
        while (!m_valid && timeout > 0) begin
            @(posedge clk);
            timeout--;
        end

        if (timeout == 0) begin
            $display("  [ERROR] Timeout waiting for output header!");
            fail_count++;
            return;
        end

        // Consume header word - m_data updates on next cycle
        @(posedge clk);

        // Capture data words
        timeout = 10000;
        idx = 0;
        while (idx < expected_samples && timeout > 0) begin
            if (m_valid && m_ready) begin
                captured_out[idx] = m_data[15:0];
                $display("  [DEBUG] Captured sample %0d: 0x%04X (%0d) at time %0t", 
                         idx, m_data[15:0], $signed(m_data[15:0]), $time);
                idx++;
            end
            @(posedge clk);
            timeout--;
        end

        if (timeout == 0)
            $display("  [ERROR] Timeout during output capture!");

        capture_done = 1;
    endtask

    // -------------------------------------------------------------------------
    // Task: Compute software reference model
    // -------------------------------------------------------------------------
    task compute_reference(input test_vector_t tv);
        logic signed [15:0] shift_reg [16];
        logic signed [15:0] coeff_slice [16];
        int N, T, S;

        N = tv.num_channels;
        T = tv.num_taps;
        S = tv.num_samples;

        for (int c = 0; c < N; c++) begin
            // Clear shift register for this channel
            for (int i = 0; i < 16; i++) shift_reg[i] = '0;

            // Extract coefficients for this channel
            for (int k = 0; k < T; k++)
                coeff_slice[k] = tv.coeffs[c][k];

            for (int n = 0; n < S; n++) begin
                // Shift in new sample
                for (int i = T-1; i > 0; i--)
                    shift_reg[i] = shift_reg[i-1];
                shift_reg[0] = tv.samples[c][n];

                // Compute FIR output
                ref_out[c*S + n] = fir_ref_sample(shift_reg, coeff_slice, T);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: Compare captured vs reference
    // -------------------------------------------------------------------------
    task compare_results(input test_vector_t tv, output int errors);
        int N, S;
        errors = 0;
        N = tv.num_channels;
        S = tv.num_samples;

        for (int c = 0; c < N; c++) begin
            for (int n = 0; n < S; n++) begin
                int idx;
                idx = c * S + n;
                if (captured_out[idx] !== ref_out[idx]) begin
                    $display("  [MISMATCH] ch=%0d, n=%0d: got=%0d (0x%04X), exp=%0d (0x%04X)",
                             c, n,
                             $signed(captured_out[idx]), captured_out[idx],
                             $signed(ref_out[idx]),      ref_out[idx]);
                    errors++;
                end
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: Run a single test vector end-to-end
    // -------------------------------------------------------------------------
    task run_test(input test_vector_t tv, input int tv_num);
        int errors;
        int exp_samples;

        $display("\n========================================");
        $display(" Test Vector %0d: %s", tv_num, tv.description);
        $display(" N=%0d, T=%0d, S=%0d",
                 tv.num_channels, tv.num_taps, tv.num_samples);
        $display("========================================");

        // Inter-test gap BEFORE starting (ensures previous test output finished)
        repeat(30) @(posedge clk);

        exp_samples = tv.num_channels * tv.num_samples;
        capture_done = 0;

        // Compute reference
        compute_reference(tv);

        // Fork: send packet and capture output simultaneously
        fork
            send_packet(tv);
            capture_output(exp_samples);
        join

        // Compare
        compare_results(tv, errors);

        if (errors == 0) begin
            $display("  [PASS] All %0d output samples match reference.", exp_samples);
            pass_count++;
        end else begin
            $display("  [FAIL] %0d mismatches found.", errors);
            fail_count++;
            total_errors += errors;
        end

        // Inter-test gap
        repeat(20) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Task: Verify s_ready never deasserts (backpressure check)
    // -------------------------------------------------------------------------
    logic s_ready_violation;
    initial s_ready_violation = 0;

    always @(posedge clk) begin
        if (rst_n && !s_ready) begin
            $display("[VIOLATION] s_ready deasserted at time %0t!", $time);
            s_ready_violation = 1;
        end
    end

    // -------------------------------------------------------------------------
    // Task: Latency checker
    // Measures cycles from last input word to first output word
    // -------------------------------------------------------------------------
    int  last_input_time;
    int  first_output_time;
    int  latency_cycles;

    always @(posedge clk) begin
        if (s_valid && s_last)
            last_input_time = $time / CLK_PERIOD;
        if (m_valid && m_ready && last_input_time > 0 && first_output_time == 0)
            first_output_time = $time / CLK_PERIOD;
    end

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        test_vector_t tv;
        pass_count    = 0;
        fail_count    = 0;
        total_errors  = 0;
        last_input_time  = 0;
        first_output_time = 0;

        $display("==============================================");
        $display("  FIR Filter Bank Hackathon Judge Testbench  ");
        $display("==============================================");

        apply_reset();

        // m_ready always asserted (no downstream backpressure)
        m_ready = 1;

        // ----- Test Vector 0: 1ch, 4-tap moving average -----
        tv = build_tv0();
        run_test(tv, 0);

        // ----- Test Vector 1: 2ch, 8-tap, sinusoidal -----
        tv = build_tv1();
        run_test(tv, 1);

        // ----- Test Vector 2: 4ch, 16-tap, saturation -----
        tv = build_tv2();
        run_test(tv, 2);

        // ----- Test Vector 3: 1ch, 4-tap, 64 samples -----
        tv = build_tv3();
        run_test(tv, 3);

        // ----- Test Vector 4: 3ch, 12-tap, alternating -----
        tv = build_tv4();
        run_test(tv, 4);

        // ----- Latency report -----
        if (last_input_time > 0 && first_output_time > 0) begin
            latency_cycles = first_output_time - last_input_time;
            $display("\n[LATENCY] First output word appeared %0d cycles after last input word.",
                     latency_cycles);
            if (latency_cycles <= 32)
                $display("[LATENCY] PASS — within 32-cycle requirement.");
            else
                $display("[LATENCY] FAIL — exceeds 32-cycle requirement!");
        end

        // ----- Backpressure check -----
        $display("\n[BACKPRESSURE] s_ready violation detected: %s",
                 s_ready_violation ? "YES — FAIL" : "NO  — PASS");

        // ----- Final summary -----
        $display("\n==============================================");
        $display("  FINAL RESULTS");
        $display("  Tests Passed : %0d / %0d", pass_count, pass_count+fail_count);
        $display("  Total Sample Errors: %0d", total_errors);
        $display("  Backpressure Violation: %s",
                 s_ready_violation ? "YES" : "NO");
        $display("==============================================");

        if (fail_count == 0 && !s_ready_violation)
            $display("  *** ALL TESTS PASSED — FULL MARKS ELIGIBLE ***");
        else
            $display("  *** SOME TESTS FAILED — REVIEW ABOVE LOG ***");

        $display("==============================================\n");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #5_000_000;
        $display("[WATCHDOG] Simulation exceeded 5ms limit. Aborting.");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Waveform dump - Selective VCD for smaller file size
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("fir_filter_bank.vcd");
        // Selective dump: only TB top-level and DUT interfaces (much smaller)
        $dumpvars(1, tb_fir_filter_bank);      // TB signals (depth 1)
        $dumpvars(1, dut);                      // DUT top-level signals
        // Uncomment for full debug (much larger VCD):
        // $dumpvars(0);  // Dump all signals in entire design
    end

endmodule
