// =============================================================================
// Testbench : tb_packet_parser
// DUT       : packet_parser
//
// ─── Input packet constraints (applied to EVERY test case) ───────────────────
//   N  : 1 – 4          (number of channels)
//   T  : 4 – 16, even   (number of taps per channel; T ∈ {4,6,8,10,12,14,16})
//   S  : 8 – 64         (samples per channel)
// ─────────────────────────────────────────────────────────────────────────────
//
// Test plan:
//   TC01  Reset behaviour                          (no packet needed)
//   TC02  Typical 2-channel      N=2 T=8  S=16
//   TC03  Maximum packet         N=4 T=16 S=64
//   TC04  s_valid gaps — coefficients  N=2 T=6  S=8
//   TC05  s_valid gaps — samples       N=2 T=4  S=12
//   TC06  Back-to-back packets   (pkt1: N=1 T=4 S=8 ; pkt2: N=2 T=4 S=8)
//   TC07  Reset mid-packet, clean restart
//   TC08  s_ready always high    N=3 T=8  S=16
//   TC09  hdr_valid exactly 1 cycle              N=1 T=4  S=8
//   TC10  pkt_done exactly 1 cycle               N=1 T=4  S=8
//   TC11  BRAM address sequence  N=3 T=4  S=8
//   TC12  sample_ch / sample_last correctness    N=2 T=4  S=10
//   TC13  sample_last fires per-channel (N=4)    N=4 T=4  S=8
//   TC14  Coefficient data integrity             N=4 T=16 S=8
// =============================================================================

 `timescale 1ns/1ps

  module tb_packet_parser;

       // -------------------------------------------------------------------------
       // DUT parameters
       // -------------------------------------------------------------------------
       localparam int MAX_CHANNELS = 4;
       localparam int MAX_TAPS     = 16;
       localparam int MAX_SAMPLES  = 64;

    // -------------------------------------------------------------------------
    // Packet constraints — enforced by send_packet assertions
    // -------------------------------------------------------------------------
    localparam int MIN_TAPS    = 4;
    localparam int MIN_SAMPLES = 8;

     // -------------------------------------------------------------------------
     // Clock
     // -------------------------------------------------------------------------
     localparam real CLK_PERIOD = 10.0; // 100 MHz

      logic clk;
      logic rst_n;

       initial clk = 0;
       always #(CLK_PERIOD / 2.0) clk = ~clk;

    // -------------------------------------------------------------------------
    // DUT ports
    // -------------------------------------------------------------------------
    logic [31:0] s_data;
    logic        s_valid;
    logic        s_ready;

     logic [3:0]  num_channels;
     logic [4:0]  num_taps;
     logic [6:0]  num_samples;
     logic        hdr_valid;

      logic        coeff_we;
      logic [5:0]  coeff_addr;
      logic [15:0] coeff_din;

       logic [15:0] sample_data;
       logic [1:0]  sample_ch;
       logic        sample_valid;
       logic        sample_last;
       logic        pkt_done;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    packet_parser #(
        .MAX_CHANNELS (MAX_CHANNELS),
        .MAX_TAPS     (MAX_TAPS),
        .MAX_SAMPLES  (MAX_SAMPLES)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .s_data       (s_data),
        .s_valid      (s_valid),
        .s_ready      (s_ready),
        .num_channels (num_channels),
        .num_taps     (num_taps),
        .num_samples  (num_samples),
        .hdr_valid    (hdr_valid),
        .coeff_we     (coeff_we),
        .coeff_addr   (coeff_addr),
        .coeff_din    (coeff_din),
        .sample_data  (sample_data),
        .sample_ch    (sample_ch),
        .sample_valid (sample_valid),
        .sample_last  (sample_last),
        .pkt_done     (pkt_done)
    );

     // -------------------------------------------------------------------------
     // Scoreboard structures
     // -------------------------------------------------------------------------
     logic [15:0] bram_capture [0:63];

      typedef struct {
          logic [15:0] data;
          logic [1:0]  ch;
          logic        last;
      } sample_entry_t;

       sample_entry_t sample_log [$];
       integer        sample_last_count;
       integer        hdr_valid_count;
       integer        pkt_done_count;
       integer        coeff_we_count;
       integer        test_pass_count;
       integer        test_fail_count;

    // -------------------------------------------------------------------------
    // Continuous monitor
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (coeff_we) begin
            bram_capture[coeff_addr] <= coeff_din;
            coeff_we_count++;
        end
        if (sample_valid) begin
            sample_log.push_back('{sample_data, sample_ch, sample_last});
            if (sample_last) sample_last_count++;
        end
        if (hdr_valid) hdr_valid_count++;
        if (pkt_done)  pkt_done_count++;
    end

     // =========================================================================
     // Utility tasks
     // =========================================================================

      task apply_reset(input int cycles = 4);
          rst_n   = 1'b0;
          s_valid = 1'b0;
          s_data  = '0;
          repeat (cycles) @(posedge clk);
          #1;
          rst_n = 1'b1;
          @(posedge clk);
      endtask

       task clear_scoreboard();
           hdr_valid_count   = 0;
           pkt_done_count    = 0;
           coeff_we_count    = 0;
           sample_last_count = 0;
           sample_log.delete();
           for (int i = 0; i < 64; i++) bram_capture[i] = '0;
       endtask

    task wait_cycles(input int n);
        repeat (n) @(posedge clk);
    endtask

     task check(input string label, input logic condition);
         if (condition) begin
             $display("  PASS : %s", label);
             test_pass_count++;
         end else begin
             $display("  FAIL : %s", label);
             test_fail_count++;
         end
     endtask

      // Drive one word; s_valid held high for exactly that posedge
      task drive_word(input logic [31:0] data, input logic last = 1'b0);
          @(negedge clk);
          s_data  = data;
          s_valid = 1'b1;
          @(posedge clk);
          #1;
          s_valid = 1'b0;
      endtask

       // Drive one word preceded by 'gap_cycles' idle cycles
       task drive_word_with_gap(
           input logic [31:0] data,
           input int          gap_cycles,
           input logic        last = 1'b0
       );
           @(negedge clk);
           s_valid = 1'b0;
           repeat (gap_cycles) @(posedge clk);
           @(negedge clk);
           s_data  = data;
           s_valid = 1'b1;
           @(posedge clk);
           #1;
           s_valid = 1'b0;
       endtask

    // -------------------------------------------------------------------------
    // send_packet — full packet driver with constraint guard
    //   N : 1–4
    //   T : 4–16, even
    //   S : 8–64
    //   coeff_gap  : idle cycles inserted between consecutive coefficient words
    //   sample_gap : idle cycles inserted between consecutive sample words
    // -------------------------------------------------------------------------
    task send_packet(
        input int    N,
        input int    T,
        input int    S,
        input logic [15:0] coeffs  [0:3][0:15],
        input logic [15:0] samples [0:3][0:63],
        input int    coeff_gap  = 0,
        input int    sample_gap = 0
    );
        // ── constraint guard ──────────────────────────────────────────────────
        if (N < 1 || N > 4)           $fatal(1, "send_packet: N=%0d out of range [1,4]", N);
        if (T < MIN_TAPS || T > 16)   $fatal(1, "send_packet: T=%0d out of range [4,16]", T);
        if (T % 2 != 0)               $fatal(1, "send_packet: T=%0d is odd (must be even)", T);
        if (S < MIN_SAMPLES || S > 64)$fatal(1, "send_packet: S=%0d out of range [8,64]", S);
        // ─────────────────────────────────────────────────────────────────────

         // Header word: [31:24]=N  [23:16]=T  [15:0]=S
         drive_word({8'(N), 8'(T), 16'(S)}, 1'b0);

          // Coefficients: channel-major, tap-minor order
          for (int ch = 0; ch < N; ch++) begin
              for (int tap = 0; tap < T; tap++) begin
                  if (coeff_gap > 0)
                      drive_word_with_gap({16'h0, coeffs[ch][tap]}, coeff_gap, 1'b0);
                  else
                      drive_word({16'h0, coeffs[ch][tap]}, 1'b0);
              end
          end

           // Samples: channel-major, sample-minor order
           for (int ch = 0; ch < N; ch++) begin
               for (int s = 0; s < S; s++) begin
                   logic is_last;
                   is_last = (ch == N-1) && (s == S-1);
                   if (sample_gap > 0)
                       drive_word_with_gap({16'h0, samples[ch][s]}, sample_gap, is_last);
                   else
                       drive_word({16'h0, samples[ch][s]}, is_last);
               end
           end
       endtask

    // =========================================================================
    // Lookup tables — all indices in-range for the largest legal packet
    // coeff_table[ch][tap] = (ch+1)*512 + tap*32   → unique, non-zero, 16-bit
    // sample_table[ch][s]  = ch*1000 + s            → unique per (ch,s)
    // =========================================================================
    logic [15:0] coeff_table [0:3][0:15];
    logic [15:0] sample_table[0:3][0:63];

     task init_tables();
         for (int ch = 0; ch < 4; ch++)
             for (int tap = 0; tap < 16; tap++)
                 coeff_table[ch][tap] = 16'((ch+1)*512 + tap*32);
         for (int ch = 0; ch < 4; ch++)
             for (int s = 0; s < 64; s++)
                 sample_table[ch][s] = 16'(ch*1000 + s);
     endtask

//
logic captured_we;
logic [5:0] captured_addr;
logic [15:0] captured_din;
//

      // =========================================================================
      // MAIN TEST SEQUENCE
      // =========================================================================
      initial begin
          $display("=============================================================");
          $display("  tb_packet_parser  —  all packets: 1≤N≤4, T even 4–16, 8≤S≤64");
          $display("=============================================================");

           test_pass_count = 0;
           test_fail_count = 0;
           init_tables();

        // =====================================================================
        // TC01 — Reset behaviour (no packet sent)
        // =====================================================================
        $display("\n--- TC01: Reset behaviour ---");

         rst_n   = 1'b0;
         s_valid = 1'b0;
         s_data  = 32'hDEAD_BEEF;
         @(posedge clk); @(posedge clk);

          check("TC01: s_ready=1 during reset",       s_ready     === 1'b1);
          check("TC01: hdr_valid=0 during reset",     hdr_valid   === 1'b0);
          check("TC01: coeff_we=0 during reset",      coeff_we    === 1'b0);
          check("TC01: sample_valid=0 during reset",  sample_valid=== 1'b0);
          check("TC01: pkt_done=0 during reset",      pkt_done    === 1'b0);

           rst_n = 1'b1;
           @(posedge clk);
           check("TC01: s_ready=1 after reset release", s_ready === 1'b1);


         // =====================================================================
         // TC02 — Typical 2-channel packet: N=2, T=8, S=16
         //   Total words = 1 + 16 + 32 = 49
         // =====================================================================
         $display("\n--- TC02: Typical packet N=2 T=8 S=16 ---");
         apply_reset();
         clear_scoreboard();

          send_packet(2, 8, 16, coeff_table, sample_table);
          wait_cycles(4);

           check("TC02: hdr_valid once",         hdr_valid_count   === 1);
           check("TC02: pkt_done once",          pkt_done_count    === 1);
           check("TC02: coeff_we = N*T = 16",    coeff_we_count    === 16);
           check("TC02: samples = N*S = 32",     sample_log.size() === 32);
           check("TC02: sample_last count = N=2", sample_last_count === 2);

        // Channel assignment: first S=16 entries → ch0, next 16 → ch1
        begin
            logic ch_ok;
            ch_ok = 1;
            for (int i =  0; i < 16; i++) if (sample_log[i].ch !== 2'd0) ch_ok = 0;
            for (int i = 16; i < 32; i++) if (sample_log[i].ch !== 2'd1) ch_ok = 0;
            check("TC02: sample_ch correct for all 32 entries", ch_ok);
        end

         // sample_last fires at indices 15 and 31 (end of each S-block)
         check("TC02: sample_last at index 15 (end ch0)", sample_log[15].last === 1'b1);
         check("TC02: sample_last at index 31 (end ch1)", sample_log[31].last === 1'b1);
         check("TC02: sample_last NOT at index 14",       sample_log[14].last === 1'b0);

          // BRAM addresses: ch0 taps 0–7 → 0–7; ch1 taps 0–7 → 16–23
          begin
              logic bram_ok;
              bram_ok = 1;
              for (int tap = 0; tap < 8; tap++) begin
                  if (bram_capture[tap]    !== coeff_table[0][tap]) bram_ok = 0;
                  if (bram_capture[16+tap] !== coeff_table[1][tap]) bram_ok = 0;
              end
              check("TC02: BRAM addresses ch0 (0–7) and ch1 (16–23) correct", bram_ok);
          end

           // Data integrity: first and last sample of each channel
           check("TC02: sample[0].data  = ch0 samp0",  sample_log[0].data  === sample_table[0][0]);
           check("TC02: sample[15].data = ch0 samp15", sample_log[15].data === sample_table[0][15]);
           check("TC02: sample[16].data = ch1 samp0",  sample_log[16].data === sample_table[1][0]);
           check("TC02: sample[31].data = ch1 samp15", sample_log[31].data === sample_table[1][15]);

        // =====================================================================
        // TC03 — Maximum packet: N=4, T=16, S=64
        //   Total words = 1 + 64 + 256 = 321
        // =====================================================================
        $display("\n--- TC03: Maximum packet N=4 T=16 S=64 ---");
        apply_reset();
        clear_scoreboard();

         send_packet(4, 16, 64, coeff_table, sample_table);
         wait_cycles(4);

          check("TC03: hdr_valid once",           hdr_valid_count   === 1);
          check("TC03: pkt_done once",            pkt_done_count    === 1);
          check("TC03: coeff_we = 64",            coeff_we_count    === 64);
          check("TC03: samples = 256",            sample_log.size() === 256);
          check("TC03: sample_last count = 4",    sample_last_count === 4);

           // All 64 BRAM cells correct
           begin
               logic bram_ok;
               bram_ok = 1;
               for (int ch = 0; ch < 4; ch++)
                   for (int tap = 0; tap < 16; tap++)
                       if (bram_capture[ch*16+tap] !== coeff_table[ch][tap]) bram_ok = 0;
               check("TC03: all 64 BRAM addresses written correctly", bram_ok);
           end

        // All 256 samples correct with proper channel tags
        begin
            logic samp_ok;
            samp_ok = 1;
            for (int ch = 0; ch < 4; ch++)
                for (int s = 0; s < 64; s++) begin
                    int idx;
                    idx = ch*64 + s;
                    if (sample_log[idx].data !== sample_table[ch][s]) samp_ok = 0;
                    if (sample_log[idx].ch   !== 2'(ch))              samp_ok = 0;
                end
            check("TC03: all 256 samples correct and channel-tagged", samp_ok);
        end

         // sample_last at end of each 64-sample block
         check("TC03: sample_last at index  63 (end ch0)", sample_log[63].last  === 1'b1);
         check("TC03: sample_last at index 127 (end ch1)", sample_log[127].last === 1'b1);
         check("TC03: sample_last at index 191 (end ch2)", sample_log[191].last === 1'b1);
         check("TC03: sample_last at index 255 (end ch3)", sample_log[255].last === 1'b1);

          // =====================================================================
          // TC04 — s_valid gaps during coefficient phase: N=2, T=6, S=8
          //   3 idle cycles injected between every coefficient word
          // =====================================================================
          $display("\n--- TC04: s_valid gaps during coefficients N=2 T=6 S=8 ---");
          apply_reset();
          clear_scoreboard();

           send_packet(2, 6, 8, coeff_table, sample_table, .coeff_gap(3));
           wait_cycles(4);

        check("TC04: coeff_we count = N*T = 12",    coeff_we_count    === 12);
        check("TC04: sample count = N*S = 16",      sample_log.size() === 16);
        check("TC04: pkt_done fired",               pkt_done_count    === 1);
        check("TC04: sample_last count = 2",        sample_last_count === 2);
        // Verify BRAM was written correctly despite gaps
        check("TC04: BRAM[0]  = ch0 tap0", bram_capture[0]  === coeff_table[0][0]);
        check("TC04: BRAM[5]  = ch0 tap5", bram_capture[5]  === coeff_table[0][5]);
        check("TC04: BRAM[16] = ch1 tap0", bram_capture[16] === coeff_table[1][0]);
        check("TC04: BRAM[21] = ch1 tap5", bram_capture[21] === coeff_table[1][5]);

         // =====================================================================
         // TC05 — s_valid gaps during sample phase: N=2, T=4, S=12
         //   2 idle cycles injected between every sample word
         // =====================================================================
         $display("\n--- TC05: s_valid gaps during samples N=2 T=4 S=12 ---");
         apply_reset();
         clear_scoreboard();

          send_packet(2, 4, 12, coeff_table, sample_table, .sample_gap(2));
          wait_cycles(4);

           check("TC05: sample count = N*S = 24",  sample_log.size() === 24);
           check("TC05: pkt_done fired",            pkt_done_count    === 1);
           check("TC05: sample_last count = 2",     sample_last_count === 2);
           // Channel boundary: samples 0–11 are ch0, 12–23 are ch1
           check("TC05: sample[0].ch=0",            sample_log[0].ch  === 2'd0);
           check("TC05: sample[11].ch=0",           sample_log[11].ch === 2'd0);
           check("TC05: sample[12].ch=1",           sample_log[12].ch === 2'd1);
           check("TC05: sample[23].ch=1",           sample_log[23].ch === 2'd1);
           // sample_last at index 11 (end ch0) and 23 (end ch1)
           check("TC05: sample_last at index 11",   sample_log[11].last === 1'b1);
           check("TC05: sample_last at index 23",   sample_log[23].last === 1'b1);
           check("TC05: sample_last NOT at index 10", sample_log[10].last === 1'b0);

        // =====================================================================
        // TC06 — Back-to-back packets (no idle cycle between end of pkt1 and
        //         header of pkt2)
        //   Packet 1: N=1 T=4 S=8
        //   Packet 2: N=2 T=4 S=8
        // =====================================================================
        $display("\n--- TC06: Back-to-back packets ---");
        apply_reset();
        clear_scoreboard();

         send_packet(1, 4, 8,  coeff_table, sample_table); // pkt1 — 1+4+8  = 13 words
         send_packet(2, 4, 8,  coeff_table, sample_table); // pkt2 — 1+8+16 = 25 words
         wait_cycles(4);

          check("TC06: hdr_valid fired twice",      hdr_valid_count   === 2);
          check("TC06: pkt_done fired twice",       pkt_done_count    === 2);
          // pkt1: 1*8=8 samples; pkt2: 2*8=16 samples → 24 total
          check("TC06: total samples = 24",         sample_log.size() === 24);
          check("TC06: sample_last count = 3",      sample_last_count === 3); // 1+2

           // =====================================================================
           // TC07 — Reset asserted mid-packet, then a clean packet must succeed
           // =====================================================================
           $display("\n--- TC07: Reset mid-packet, clean restart ---");
           clear_scoreboard();
           rst_n   = 1'b1;
           s_valid = 1'b0;
           @(posedge clk);

        // Send header N=3 T=8 S=16 then a few coeff words, then reset
        @(negedge clk);
        s_data  = {8'd3, 8'd8, 16'd16};
        s_valid = 1'b1;
        @(posedge clk); #1;
        // Four coefficient words
        repeat (4) begin
            @(negedge clk); s_data = 32'hCCDD_AABB; @(posedge clk); #1;
        end
        s_valid = 1'b0;

         // Assert reset mid-packet
         rst_n = 1'b0;
         @(posedge clk); @(posedge clk);

          check("TC07: coeff_we=0 after reset",      coeff_we    === 1'b0);
          check("TC07: sample_valid=0 after reset",  sample_valid=== 1'b0);
          check("TC07: hdr_valid=0 after reset",     hdr_valid   === 1'b0);
          check("TC07: pkt_done=0 after reset",      pkt_done    === 1'b0);
          check("TC07: s_ready=1 after reset",       s_ready     === 1'b1);

           // Release reset; clean packet N=2 T=4 S=8 must complete correctly
           rst_n = 1'b1;
           @(posedge clk);
           clear_scoreboard();
           send_packet(2, 4, 8, coeff_table, sample_table);
           wait_cycles(4);

        check("TC07: clean pkt after reset — pkt_done",      pkt_done_count    === 1);
        check("TC07: clean pkt — N*S=16 samples received",   sample_log.size() === 16);
        check("TC07: clean pkt — coeff_we = N*T = 8",        coeff_we_count    === 8);
        check("TC07: clean pkt — hdr_valid once",            hdr_valid_count   === 1);

         // =====================================================================
         // TC08 — s_ready must stay permanently high throughout a full packet
         //   N=3 T=8 S=16   (1+24+48 = 73 words → 73+ cycles to monitor)
         // =====================================================================
         $display("\n--- TC08: s_ready always high N=3 T=8 S=16 ---");
         apply_reset();

          begin
              logic ready_never_low;
              ready_never_low = 1;

               fork
                   send_packet(3, 8, 16, coeff_table, sample_table);
                   begin
                       // Poll every posedge across the entire packet + margin
                       repeat (1 + 3*8 + 3*16 + 10) begin
                           @(posedge clk);
                           if (!s_ready) ready_never_low = 0;
                       end
                   end
               join

            check("TC08: s_ready never deasserted during or after packet",
                  ready_never_low);
          end

           // =====================================================================
           // TC09 — hdr_valid pulse width: must be exactly 1 cycle
           //   N=1 T=4 S=8
           // =====================================================================
           $display("\n--- TC09: hdr_valid exactly 1 cycle N=1 T=4 S=8 ---");
           apply_reset();
           clear_scoreboard();

        @(negedge clk);
        s_data  = {8'd1, 8'd4, 16'd8};
        s_valid = 1'b1;
        @(posedge clk); #1;                          // header consumed
        check("TC09: hdr_valid=1 on header cycle",   hdr_valid === 1'b1);

         @(negedge clk); s_data = {16'h0, coeff_table[0][0]}; // first coeff
         @(posedge clk); #1;
         check("TC09: hdr_valid=0 on first coeff cycle", hdr_valid === 1'b0);

          // Finish the packet cleanly
          for (int tap = 1; tap < 4; tap++) begin
              @(negedge clk); s_data = {16'h0, coeff_table[0][tap]};
              @(posedge clk); #1;
              check($sformatf("TC09: hdr_valid=0 during coeff tap%0d", tap),
                    hdr_valid === 1'b0);
        end
        for (int s = 0; s < 8; s++) begin
            @(negedge clk); s_data = {16'h0, sample_table[0][s]};
            @(posedge clk); #1;
            check($sformatf("TC09: hdr_valid=0 during sample %0d", s),
                  hdr_valid === 1'b0);
          end
          s_valid = 1'b0;
          check("TC09: hdr_valid fired exactly once total", hdr_valid_count === 1);

           // =====================================================================
           // TC10 — pkt_done pulse width: must be exactly 1 cycle
           //   N=1 T=4 S=8
           // =====================================================================
           $display("\n--- TC10: pkt_done exactly 1 cycle N=1 T=4 S=8 ---");
           apply_reset();
           clear_scoreboard();

        // Send full packet; last drive_word call lands on the final sample
        send_packet(1, 4, 8, coeff_table, sample_table);

         // One cycle after drive_word returns, pkt_done should already have fired
         // and fallen back to 0
         @(posedge clk); #1;
         check("TC10: pkt_done=0 the cycle after last sample", pkt_done === 1'b0);
         check("TC10: pkt_done fired exactly once",            pkt_done_count === 1);
         wait_cycles(4);
         check("TC10: pkt_done stays 0 after packet",         pkt_done === 1'b0);

          // =====================================================================
          // TC11 — BRAM address sequence: N=3, T=4, S=8
          //   Expected addresses: ch0→0,1,2,3  ch1→16,17,18,19  ch2→32,33,34,35
          // =====================================================================
          $display("\n--- TC11: BRAM address sequence N=3 T=4 S=8 ---");
          apply_reset();

           begin
               logic [5:0] addr_log [$];
               logic       addr_ok;

            fork
                send_packet(3, 4, 8, coeff_table, sample_table);
                begin
                     @(posedge clk); #1 ;
					 if (hdr_valid === 1'b1) begin
                    //@(posedge clk); //@(posedge clk); // skip header cycle
                    // Capture coeff_addr on every cycle where coeff_we=1
                    repeat (3*4 + 5) begin
                        @(posedge clk);
                        if (coeff_we) addr_log.push_back(coeff_addr);
                    end
					end
                end
            join

             addr_ok = (addr_log.size() === 12);
             if (addr_ok) begin
                 for (int ch = 0; ch < 3; ch++)
                     for (int tap = 0; tap < 4; tap++) begin
                         automatic int idx  = ch*4 + tap;
                         automatic int exp  = ch*16 + tap;
                         if (int'(addr_log[idx]) !== exp) begin
                             $display("    addr_log[%0d] = %0d, expected %0d",
                                      idx, addr_log[idx], exp);
                              addr_ok = 0;
                          end
                      end
              end
              check("TC11: BRAM address walk correct for N=3 T=4", addr_ok);
              check("TC11: exactly 12 BRAM writes captured",       addr_log.size() === 12);
          end

           // =====================================================================
           // TC12 — sample_ch and sample_last correctness: N=2, T=4, S=10
           //   10 samples per channel → sample_last at indices 9 and 19
           // =====================================================================
           $display("\n--- TC12: sample_ch and sample_last N=2 T=4 S=10 ---");
           apply_reset();
           clear_scoreboard();

        send_packet(2, 4, 10, coeff_table, sample_table);
        wait_cycles(2);

         check("TC12: 20 samples received",          sample_log.size() === 20);
         check("TC12: sample_last count = 2",        sample_last_count === 2);

          // ch0 block: indices 0–9
          check("TC12: index 0  ch=0 last=0",
                sample_log[0].ch===2'd0  && sample_log[0].last===1'b0);
        check("TC12: index 9  ch=0 last=1",
              sample_log[9].ch===2'd0  && sample_log[9].last===1'b1);
          // ch1 block: indices 10–19
          check("TC12: index 10 ch=1 last=0",
                sample_log[10].ch===2'd1 && sample_log[10].last===1'b0);
        check("TC12: index 19 ch=1 last=1",
              sample_log[19].ch===2'd1 && sample_log[19].last===1'b1);

           // Data integrity spot-checks
           check("TC12: sample[0].data  = ch0 samp0",  sample_log[0].data  === sample_table[0][0]);
           check("TC12: sample[9].data  = ch0 samp9",  sample_log[9].data  === sample_table[0][9]);
           check("TC12: sample[10].data = ch1 samp0",  sample_log[10].data === sample_table[1][0]);
           check("TC12: sample[19].data = ch1 samp9",  sample_log[19].data === sample_table[1][9]);

        // =====================================================================
        // TC13 — sample_last fires once per channel (N=4): N=4, T=4, S=8
        //   sample_last at indices 7, 15, 23, 31
        // =====================================================================
        $display("\n--- TC13: sample_last per-channel N=4 T=4 S=8 ---");
        apply_reset();
        clear_scoreboard();

         send_packet(4, 4, 8, coeff_table, sample_table);
         wait_cycles(2);

          check("TC13: 32 samples received",            sample_log.size() === 32);
          check("TC13: sample_last fires exactly 4x",   sample_last_count === 4);

           check("TC13: index  7 last=1 ch=0",
                 sample_log[7].last===1'b1  && sample_log[7].ch===2'd0);
         check("TC13: index 15 last=1 ch=1",
               sample_log[15].last===1'b1 && sample_log[15].ch===2'd1);
           check("TC13: index 23 last=1 ch=2",
                 sample_log[23].last===1'b1 && sample_log[23].ch===2'd2);
         check("TC13: index 31 last=1 ch=3",
               sample_log[31].last===1'b1 && sample_log[31].ch===2'd3);

        // No spurious last in the middle of a block
        check("TC13: index  6 last=0", sample_log[6].last  === 1'b0);
        check("TC13: index 14 last=0", sample_log[14].last === 1'b0);
        check("TC13: index 22 last=0", sample_log[22].last === 1'b0);

         // =====================================================================
         // TC14 — Coefficient data integrity with unique pattern: N=4, T=16, S=8
         //   coeff[ch][tap] = ch*1000 + tap  — each of 64 cells is unique
         //   Verify every BRAM address receives the exact value sent
         // =====================================================================
         $display("\n--- TC14: Coefficient data integrity N=4 T=16 S=8 ---");
         apply_reset();
         clear_scoreboard();

          begin
              logic [15:0] uniq_coeffs [0:3][0:15];
              for (int ch = 0; ch < 4; ch++)
                  for (int tap = 0; tap < 16; tap++)
                      uniq_coeffs[ch][tap] = 16'(ch * 1000 + tap);

               send_packet(4, 16, 8, uniq_coeffs, sample_table);
               wait_cycles(4);

            begin
                logic data_ok;
                data_ok = 1;
                for (int ch = 0; ch < 4; ch++) begin
                    for (int tap = 0; tap < 16; tap++) begin
                        automatic int  addr = ch * 16 + tap;
                        automatic logic [15:0] exp = 16'(ch * 1000 + tap);
                        if (bram_capture[addr] !== exp) begin
                            $display("    MISMATCH BRAM[%0d]: expected 0x%04X got 0x%04X",
                                     addr, exp, bram_capture[addr]);
                             data_ok = 0;
                         end
                     end
                 end
                 check("TC14: all 64 BRAM cells match ch*1000+tap pattern", data_ok);
             end

              check("TC14: pkt_done fired",           pkt_done_count  === 1);
              check("TC14: coeff_we = 64",            coeff_we_count  === 64);
              check("TC14: samples = N*S = 32",       sample_log.size() === 32);
          end

           // =====================================================================
           // Summary
           // =====================================================================
           $display("\n=============================================================");
           $display("  Test Summary : %0d PASSED,  %0d FAILED",
                    test_pass_count, test_fail_count);
        $display("=============================================================");
        if (test_fail_count == 0)
            $display("  RESULT : ALL TESTS PASSED");
        else
            $display("  RESULT : FAILURES DETECTED — review output above");

         $finish;
     end

      // -------------------------------------------------------------------------
      // Watchdog
      // -------------------------------------------------------------------------
      initial begin
          #2_000_000;
          $display("WATCHDOG: simulation exceeded 2 000 000 ns — aborting");
          $finish;
      end

       // -------------------------------------------------------------------------
       // Waveform dump
       // -------------------------------------------------------------------------
       initial begin
           $dumpfile("tb_packet_parser.vcd");
           $dumpvars(0, tb_packet_parser);
       end

endmodule
