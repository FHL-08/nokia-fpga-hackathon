// =============================================================================
// Module      : output_packetizer
// Description : Collects filtered samples from all channel engines and
//               serializes them into an output AXI-Stream packet.
//               Buffers all output samples before transmitting (ensures
//               output does not affect input acceptance).
// =============================================================================
module output_packetizer #(
    parameter int MAX_CHANNELS = 4,
    parameter int MAX_SAMPLES  = 64
)(
    input  logic        clk,
    input  logic        rst_n,

    // Header info (stable after hdr_valid)
    input  logic [3:0]  num_channels,
    input  logic [4:0]  num_taps,
    input  logic [6:0]  num_samples,
    input  logic        hdr_valid,

    // Filtered sample inputs from FIR channel engines
    input  wire signed [15:0]  ch_data   [0:MAX_CHANNELS-1],
    input  wire                ch_valid  [0:MAX_CHANNELS-1],
    input  wire                ch_last   [0:MAX_CHANNELS-1],

    // Output AXI-Stream
    output logic [31:0] m_data,
    output logic        m_valid,
    output logic        m_last,
    input  logic        m_ready
);

    // -------------------------------------------------------------------------
    // Output sample buffer: MAX_CHANNELS x MAX_SAMPLES
    // Stored in channel-major order
    // -------------------------------------------------------------------------
    logic signed [15:0] out_buf [0:MAX_CHANNELS*MAX_SAMPLES-1];
    logic [8:0]  buf_wr_ptr [0:MAX_CHANNELS-1]; // per-channel write pointer
    logic [8:0]  buf_rd_ptr;
    logic [8:0]  total_out_samples;

    // Registered header for output packet
    logic [3:0]  r_num_ch;
    logic [4:0]  r_num_taps;
    logic [6:0]  r_num_samp;

    // -------------------------------------------------------------------------
    // State machine
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        ST_COLLECT  = 2'd0,   // Collecting filtered samples
        ST_HDR      = 2'd1,   // Sending output header word
        ST_DATA     = 2'd2    // Streaming output samples
    } state_t;

    state_t state;

    logic [8:0] samples_sent;
    logic [3:0] ch_done_mask;   // Which channels have finished
    logic       all_done;
    logic       packet_streamed; // Flag: current packet already streamed

    assign all_done = (ch_done_mask == ((1 << r_num_ch) - 1));

    // -------------------------------------------------------------------------
    // Capture header
    // -------------------------------------------------------------------------
    logic hdr_valid_d1;  // Delayed by 1 cycle
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_num_ch     <= '0;
            r_num_taps   <= '0;
            r_num_samp   <= '0;
            hdr_valid_d1 <= 1'b0;
        end else begin
            hdr_valid_d1 <= hdr_valid;
            if (hdr_valid) begin
                r_num_ch   <= num_channels;
                r_num_taps <= num_taps;
                r_num_samp <= num_samples;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Buffer write: collect samples from each channel engine
    // Each channel writes to its own region: ch_id * MAX_SAMPLES + offset
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int c = 0; c < MAX_CHANNELS; c++) begin
                buf_wr_ptr[c] <= '0;
            end
            ch_done_mask      <= '0;
            total_out_samples <= '0;
        end else begin
            if (hdr_valid_d1) begin
                for (int c = 0; c < MAX_CHANNELS; c++)
                    // Use r_num_samp (now properly captured) as the stride so the
                    // channels occupy contiguous addresses 0..N*S-1 and the
                    // linear buf_rd_ptr reads them in the correct order.
                    buf_wr_ptr[c] <= 9'(c) * 9'(r_num_samp);
                ch_done_mask      <= '0;
                total_out_samples <= r_num_ch * r_num_samp;
                `ifndef SYNTHESIS
                $display("[OPKT] Init: N=%0d, S=%0d, total=%0d, ch0_addr=%0d, time=%0t",
                         r_num_ch, r_num_samp, r_num_ch * r_num_samp, 
                         9'(0) * 9'(r_num_samp), $time);
                `endif
                // Clear output buffer to prevent stale data from previous
                // packet from being read if new packet hasn't fully written yet
                for (int i = 0; i < MAX_CHANNELS * MAX_SAMPLES; i++)
                    out_buf[i] <= 16'hXXXX;
            end else begin
                // Normal operation: channels write their filtered samples
                for (int c = 0; c < MAX_CHANNELS; c++) begin
                    if (ch_valid[c]) begin
                        out_buf[buf_wr_ptr[c]] <= ch_data[c];
                        `ifndef SYNTHESIS
                        $display("[OPKT] Ch%0d write: addr=%0d, data=0x%04X, last=%0d, time=%0t",
                                 c, buf_wr_ptr[c], ch_data[c], ch_last[c], $time);
                        `endif
                        buf_wr_ptr[c]          <= buf_wr_ptr[c] + 1;
                        if (ch_last[c])
                            ch_done_mask[c] <= 1'b1;
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Output state machine
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= ST_COLLECT;
            m_valid        <= 1'b0;
            m_data         <= '0;
            m_last         <= 1'b0;
            buf_rd_ptr     <= '0;
            samples_sent   <= '0;
            packet_streamed <= 1'b0;
        end else begin
            // -----------------------------------------------------------------
            // Force reset to COLLECT state on new packet header
            // This prevents streaming stale output data from a previous packet.
            // Use hdr_valid_d1 to align with buffer initialization timing.
            // -----------------------------------------------------------------
            if (hdr_valid_d1) begin
                state          <= ST_COLLECT;
                m_valid        <= 1'b0;
                m_last         <= 1'b0;
                buf_rd_ptr     <= '0;
                samples_sent   <= '0;
                packet_streamed <= 1'b0; // New packet, not yet streamed
            end else begin
                case (state)
                    // ---------------------------------------------------------
                    ST_COLLECT: begin
                        m_valid <= 1'b0;
                        m_last  <= 1'b0;
                        // Only stream if all channels done AND we haven't already streamed this packet
                        if (all_done && (r_num_ch != 0) && !packet_streamed) begin
                            buf_rd_ptr   <= '0;
                            samples_sent <= '0;
                            state        <= ST_HDR;
                        end
                    end

                    // ---------------------------------------------------------
                    // Send header word
                    ST_HDR: begin
                        m_data  <= {8'(r_num_ch), 8'(r_num_taps), 16'(r_num_samp)};
                        m_valid <= 1'b1;
                        m_last  <= 1'b0;
                        if (m_ready) begin
                            state <= ST_DATA;
                        end
                    end

                    // ---------------------------------------------------------
                    // Stream output samples
                    ST_DATA: begin
                        if (m_ready || !m_valid) begin
                            if (samples_sent < total_out_samples) begin
                                m_data       <= {{16{out_buf[buf_rd_ptr][15]}},
                                                 out_buf[buf_rd_ptr]};
                                m_valid      <= 1'b1;
                                m_last       <= (samples_sent ==
                                                 total_out_samples - 1);
                                `ifndef SYNTHESIS
                                $display("[OPKT] Read: addr=%0d, data=0x%04X, sent=%0d/%0d, time=%0t",
                                         buf_rd_ptr, out_buf[buf_rd_ptr], samples_sent, 
                                         total_out_samples, $time);
                                `endif
                                buf_rd_ptr   <= buf_rd_ptr + 1;
                                samples_sent <= samples_sent + 1;
                            end else begin
                                // Done streaming this packet
                                m_valid         <= 1'b0;
                                m_last          <= 1'b0;
                                packet_streamed <= 1'b1; // Mark packet as streamed
                                state           <= ST_COLLECT;
                            end
                        end
                    end

                    default: state <= ST_COLLECT;
                endcase
            end
        end
    end

endmodule