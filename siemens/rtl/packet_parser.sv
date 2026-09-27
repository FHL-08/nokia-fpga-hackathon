// =============================================================================
// Module      : packet_parser
// Description : Parses the incoming AXI-Stream packet.
//               - Extracts header fields (N, T, S)
//               - Writes coefficients into BRAM
//               - Forwards sample words to the FIR channel engines
//               s_ready is ALWAYS HIGH (no backpressure to input).
//
//               The packet is self-terminating: the parser walks a
//               (channel, index) pair through the coefficient block and then
//               the sample block, so no N*T / N*S products are needed.
// =============================================================================
module packet_parser #(
    parameter int MAX_CHANNELS = 4,
    parameter int MAX_TAPS     = 16,
    parameter int MAX_SAMPLES  = 64
)(
    input  logic        clk,
    input  logic        rst_n,

    // Input AXI-Stream
    input  logic [31:0] s_data,
    input  logic        s_valid,
    output logic        s_ready,    // Always HIGH

    // Parsed header outputs (registered, valid when hdr_valid=1)
    output logic [3:0]  num_channels,   // N
    output logic [4:0]  num_taps,       // T
    output logic [6:0]  num_samples,    // S
    output logic        hdr_valid,      // Pulses high for 1 cycle when header parsed

    // Coefficient BRAM write port
    output logic        coeff_we,
    output logic [5:0]  coeff_addr,     // log2(64)=6 bits
    output logic [15:0] coeff_din,

    // Sample output to FIR engines
    output logic [15:0] sample_data,
    output logic [1:0]  sample_ch,      // Which channel this sample belongs to
    output logic        sample_valid,
    output logic        sample_last,    // Last sample of the current channel

    // Packet done indicator
    output logic        pkt_done
);

    // -------------------------------------------------------------------------
    // State machine
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        ST_HEADER   = 2'd0,
        ST_COEFFS   = 2'd1,
        ST_SAMPLES  = 2'd2
    } ST_STATE_T;

    ST_STATE_T state;

    // Registered header fields
    logic [3:0] r_num_ch;
    logic [4:0] r_num_taps;
    logic [6:0] r_num_samp;

    // Coefficient addressing: channel c, tap k -> c*MAX_TAPS + k
    logic [1:0] coeff_ch_idx;
    logic [4:0] coeff_tap_idx;

    // Sample tracking
    logic [1:0] ch_idx;
    logic [6:0] samp_in_ch;

    logic       last_ch_coeff;
    logic       last_tap;
    logic       last_ch_samp;
    logic       last_samp;

    assign s_ready       = 1'b1;
    assign last_tap      = (coeff_tap_idx == (r_num_taps - 5'd1));
    assign last_ch_coeff = ({2'b00, coeff_ch_idx} == (r_num_ch - 4'd1));
    assign last_samp     = (samp_in_ch == (r_num_samp - 7'd1));
    assign last_ch_samp  = ({2'b00, ch_idx} == (r_num_ch - 4'd1));

    // =========================================================================
    // Main sequential logic — FSM, header registers, coefficient addressing
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_HEADER;
            r_num_ch      <= 4'd0;
            r_num_taps    <= 5'd0;
            r_num_samp    <= 7'd0;
            coeff_ch_idx  <= 2'd0;
            coeff_tap_idx <= 5'd0;
            hdr_valid     <= 1'b0;
            pkt_done      <= 1'b0;
        end else begin
            hdr_valid <= 1'b0;
            pkt_done  <= 1'b0;
            if (s_valid) begin
                case (state)
                    ST_HEADER: begin
                        r_num_ch      <= s_data[27:24];
                        r_num_taps    <= s_data[20:16];
                        r_num_samp    <= s_data[6:0];
                        coeff_ch_idx  <= 2'd0;
                        coeff_tap_idx <= 5'd0;
                        hdr_valid     <= 1'b1;
                        state         <= ST_COEFFS;
                    end
                    ST_COEFFS: begin
                        if (last_tap) begin
                            coeff_tap_idx <= 5'd0;
                            coeff_ch_idx  <= coeff_ch_idx + 2'd1;
                            if (last_ch_coeff) begin
                                state <= ST_SAMPLES;
                            end
                        end else begin
                            coeff_tap_idx <= coeff_tap_idx + 5'd1;
                        end
                    end
                    ST_SAMPLES: begin
                        if (last_samp && last_ch_samp) begin
                            pkt_done <= 1'b1;
                            state    <= ST_HEADER;
                        end
                    end
                    default: begin
                        state <= ST_HEADER;
                    end
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // Output registered header fields
    // -------------------------------------------------------------------------
    assign num_channels = r_num_ch;
    assign num_taps     = r_num_taps;
    assign num_samples  = r_num_samp;

    // -------------------------------------------------------------------------
    // Coefficient BRAM write port (MAX_TAPS = 16 -> {ch, tap[3:0]})
    // -------------------------------------------------------------------------
    assign coeff_we   = (state == ST_COEFFS) && s_valid;
    assign coeff_addr = {coeff_ch_idx, coeff_tap_idx[3:0]};
    assign coeff_din  = s_data[15:0];

    // =========================================================================
    // Sample channel tracking — per-channel sample counter
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ch_idx     <= 2'd0;
            samp_in_ch <= 7'd0;
        end else if (s_valid) begin
            if (state == ST_HEADER) begin
                ch_idx     <= 2'd0;
                samp_in_ch <= 7'd0;
            end else if (state == ST_SAMPLES) begin
                if (last_samp) begin
                    samp_in_ch <= 7'd0;
                    ch_idx     <= ch_idx + 2'd1;
                end else begin
                    samp_in_ch <= samp_in_ch + 7'd1;
                end
            end
        end
    end

    assign sample_data  = s_data[15:0];
    assign sample_ch    = ch_idx;
    assign sample_valid = (state == ST_SAMPLES) && s_valid;
    assign sample_last  = sample_valid && last_samp;

endmodule
