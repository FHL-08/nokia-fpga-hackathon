// =============================================================================
// File: fir_scoreboard.svh
//
// FIR Filter Bank Scoreboard
//
// Subscribes to the master agent's aaxi_stream_packet_ap (FIR input packet)
// and the slave agent's aaxi_stream_packet_ap (FIR output packet).
//
// For each input packet:
//   1. Parses the FIR packet format: {header, N*T coefficients, N*S samples}
//   2. Runs a software reference FIR using Q1.15 arithmetic
//   3. Waits for the corresponding output packet from the slave
//   4. Compares expected filtered samples with actual filtered samples
//   5. Reports PASS / ERROR
//
// Packet wire format (little-endian 32-bit words on TDATA):
//   Master input:  [header][coeff_0]..[coeff_N*T-1][samp_0]..[samp_N*S-1]
//   Slave output:  [header][filt_0]..[filt_N*S-1]
//   All data words: value in [15:0], upper 16 bits zero (master) or sign-ext (slave)
// =============================================================================
class fir_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fir_scoreboard)

    // -----------------------------------------------------------------------
    // Analysis exports (connected to agent aaxi_stream_packet_ap ports)
    // -----------------------------------------------------------------------
    uvm_analysis_export #(aaxi_stream_packet) master_export;
    uvm_analysis_export #(aaxi_stream_packet) slave_export;

    // Internal FIFOs to decouple write() from run_phase()
    local uvm_tlm_analysis_fifo #(aaxi_stream_packet) master_fifo;
    local uvm_tlm_analysis_fifo #(aaxi_stream_packet) slave_fifo;

    int unsigned num_packets_checked = 0;
    int unsigned num_errors          = 0;

    // FIR model parameters (unpacked per packet)
    local int unsigned r_N, r_T, r_S;
    local logic signed [15:0] r_coeffs[];   // [ch][tap] — flattened ch*MAX_TAPS+tap
    local logic signed [15:0] r_samples[];  // [ch][samp] — flattened

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        master_export = new("master_export", this);
        slave_export  = new("slave_export",  this);
        master_fifo   = new("master_fifo",   this);
        slave_fifo    = new("slave_fifo",    this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        master_export.connect(master_fifo.analysis_export);
        slave_export.connect(slave_fifo.analysis_export);
    endfunction

    // -----------------------------------------------------------------------
    // Helper: reconstruct 32-bit word from 4 consecutive payload bytes (LE)
    // -----------------------------------------------------------------------
    local function automatic logic [31:0] get_word(
        ref aaxi_stream_packet pkt,
        input int              byte_off
    );
        return { pkt.payload[byte_off+3].d,
                 pkt.payload[byte_off+2].d,
                 pkt.payload[byte_off+1].d,
                 pkt.payload[byte_off  ].d };
    endfunction

    // -----------------------------------------------------------------------
    // Helper: saturate 32-bit signed accumulator to Q1.15 range
    // -----------------------------------------------------------------------
    local function automatic logic signed [15:0] saturate(
        input logic signed [31:0] val
    );
        if      (val > 32'sh00007FFF) return 16'sh7FFF;
        else if (val < 32'shFFFF8000) return 16'sh8000;
        else                          return val[15:0];
    endfunction

    // -----------------------------------------------------------------------
    // Reference FIR: compute expected output for one channel
    //   coeffs[0..T-1], samples[0..S-1]  →  out[0..S-1]
    //   Q1.15: result = saturate( sum(x[n-k] * h[k]) >> 15 )
    // -----------------------------------------------------------------------
    local function automatic void ref_fir(
        input  logic signed [15:0] h[],    // coefficients (T entries)
        input  logic signed [15:0] x[],    // samples      (S entries)
        output logic signed [15:0] y[]     // output        (S entries)
    );
        int T = h.size();
        int S = x.size();
        y = new[S];
        for (int n = 0; n < S; n++) begin
            logic signed [31:0] acc  = 0;
            logic signed [31:0] prod = 0;
            for (int k = 0; k < T; k++) begin
                if ((n - k) >= 0) begin
                    prod = $signed(x[n-k]) * $signed(h[k]);
                    acc += prod >>> 15;
                end
            end
            y[n] = saturate(acc);
        end
    endfunction

    // -----------------------------------------------------------------------
    // run_phase: get packets from FIFOs, check each one
    // -----------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        aaxi_stream_packet master_pkt;
        aaxi_stream_packet slave_pkt;

        forever begin
            // ----------------------------------------------------------------
            // 1. Get the master input packet (FIR input: header+coeffs+samples)
            // ----------------------------------------------------------------
            `uvm_info("FIR_SB_DBG", "Waiting for master packet...", UVM_HIGH)
            master_fifo.get(master_pkt);
            `uvm_info("FIR_SB_DBG", $sformatf("Got master packet: payload.size()=%0d", master_pkt.payload.size()), UVM_HIGH)

            if (master_pkt.payload.size() < 4) begin
                `uvm_error("FIR_SB", "Master packet too short to contain header")
                continue;
            end

            begin
                // Parse header word (word 0)
                logic [31:0] hdr = get_word(master_pkt, 0);
                int unsigned N   = hdr[31:24];
                int unsigned T   = hdr[23:16];
                int unsigned S   = hdr[15:0];

                int unsigned expected_bytes = (1 + N*T + N*S) * 4;

                if (master_pkt.payload.size() < expected_bytes) begin
                    `uvm_error("FIR_SB", $sformatf(
                        "Master packet payload too short: got %0d bytes, expected %0d (N=%0d T=%0d S=%0d)",
                        master_pkt.payload.size(), expected_bytes, N, T, S))
                    continue;
                end

                `uvm_info("FIR_SB", $sformatf(
                    "Parsing master FIR packet: N=%0d T=%0d S=%0d", N, T, S), UVM_HIGH)

                // ----------------------------------------------------------------
                // 2. Get the slave output packet (FIR output: header+filtered_samples)
                // ----------------------------------------------------------------
                `uvm_info("FIR_SB_DBG", $sformatf("Waiting for slave packet (N=%0d T=%0d S=%0d)...", N, T, S), UVM_HIGH)
                slave_fifo.get(slave_pkt);
                `uvm_info("FIR_SB_DBG", $sformatf("Got slave packet: payload.size()=%0d", slave_pkt.payload.size()), UVM_HIGH)

                begin
                    logic [31:0] out_hdr = get_word(slave_pkt, 0);
                    int unsigned oN = out_hdr[31:24];
                    int unsigned oT = out_hdr[23:16];
                    int unsigned oS = out_hdr[15:0];

                    if (oN !== N || oT !== T || oS !== S) begin
                        `uvm_error("FIR_SB", $sformatf(
                            "Header mismatch: master N=%0d T=%0d S=%0d, slave N=%0d T=%0d S=%0d",
                            N, T, S, oN, oT, oS))
                        num_errors++;
                        continue;
                    end
                end

                // ----------------------------------------------------------------
                // 3. For each channel: extract coeffs & samples, run ref FIR, compare
                // ----------------------------------------------------------------
                for (int ch = 0; ch < N; ch++) begin
                    logic signed [15:0] h[];
                    logic signed [15:0] x[];
                    logic signed [15:0] y_ref[];

                    // Extract coefficients for this channel
                    h = new[T];
                    for (int k = 0; k < T; k++) begin
                        int byte_off = (1 + ch*T + k) * 4;
                        logic [31:0] w = get_word(master_pkt, byte_off);
                        h[k] = w[15:0];
                    end

                    // Extract samples for this channel
                    x = new[S];
                    for (int n = 0; n < S; n++) begin
                        int byte_off = (1 + N*T + ch*S + n) * 4;
                        logic [31:0] w = get_word(master_pkt, byte_off);
                        x[n] = w[15:0];
                    end

                    // Compute reference output
                    ref_fir(h, x, y_ref);

                    // -------------------------------------------------------
                    // 4. Compare reference output with slave received samples
                    // -------------------------------------------------------
                    for (int n = 0; n < S; n++) begin
                        int byte_off = (1 + ch*S + n) * 4;
                        logic [31:0] actual_w = get_word(slave_pkt, byte_off);
                        logic signed [15:0] actual_s = actual_w[15:0];

                        `uvm_info("FIR_SB_DBG", $sformatf("ch=%0d n=%0d byte_off=%0d actual=0x%04X ref=0x%04X",
                                 ch, n, byte_off, actual_s, y_ref[n]), UVM_HIGH)

                        if (actual_s !== y_ref[n]) begin
                            `uvm_error("FIR_SB", $sformatf(
                                "MISMATCH ch=%0d samp=%0d: expected 0x%04X (%0d), got 0x%04X (%0d)",
                                ch, n, y_ref[n], $signed(y_ref[n]),
                                actual_s, $signed(actual_s)))
                            num_errors++;
                        end else begin
                            `uvm_info("FIR_SB", $sformatf(
                                "MATCH    ch=%0d samp=%0d: 0x%04X (%0d)",
                                ch, n, actual_s, $signed(actual_s)), UVM_LOW)
                        end
                    end
                end

                num_packets_checked++;
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        if (num_errors == 0)
            `uvm_info("FIR_SB", $sformatf(
                "SCOREBOARD PASSED — %0d packet(s) checked, 0 errors",
                num_packets_checked), UVM_LOW)
        else
            `uvm_error("FIR_SB", $sformatf(
                "SCOREBOARD FAILED — %0d packet(s) checked, %0d error(s)",
                num_packets_checked, num_errors))
    endfunction

endclass: fir_scoreboard
