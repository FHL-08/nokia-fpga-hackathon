// =============================================================================
// Module      : fir_channel
// Description : Single-channel FIR filter engine.
//               - Reads coefficients from BRAM (shared, addressed by ch_id)
//               - Maintains a shift register of input samples
//               - Computes dot product using DSP48E1 inference
//               - Outputs saturated Q1.15 results
// =============================================================================
module fir_channel #(
    parameter int CH_ID      = 0,
    parameter int MAX_TAPS   = 16,
    parameter int MAX_SAMPLES = 64
)(
    input  logic        clk,
    input  logic        rst_n,

    // New-packet indicator: resets shift register and sample FIFO
    input  logic        hdr_valid,

    // Configuration (from parser, stable during processing)
    input  logic [4:0]  num_taps,
    input  logic [6:0]  num_samples,

    // Sample input
    input  logic [15:0] sample_data,
    input  logic        sample_valid,   // Valid only when this channel's turn
    input  logic        sample_last,

    // Coefficient BRAM read port (dedicated per channel)
    output logic        coeff_re,
    output logic [5:0]  coeff_addr,
    input  logic [15:0] coeff_dout,

    // Output samples
    output logic signed [15:0] out_data,
    output logic               out_valid,
    output logic               out_last
);

    // -------------------------------------------------------------------------
    // Sample shift register (delay line)
    // -------------------------------------------------------------------------
    logic signed [15:0] shift_reg [0:MAX_TAPS-1];

    // -------------------------------------------------------------------------
    // State machine type — declared first so enum literals are visible to the
    // combinational assign below.
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE    = 3'd0,
        ST_SHIFT   = 3'd1,
        ST_MAC     = 3'd2,
        ST_OUTPUT  = 3'd3,
        ST_MAC_LAST = 3'd4
    } state_t;

    state_t state;

    // -------------------------------------------------------------------------
    // Sample input FIFO (depth = MAX_SAMPLES)
    // -------------------------------------------------------------------------
    logic [15:0] sample_fifo [0:MAX_SAMPLES-1];
    logic        last_fifo   [0:MAX_SAMPLES-1];
    logic [5:0]  fifo_wr_ptr;
    logic [5:0]  fifo_rd_ptr;
    logic [6:0]  fifo_count;
    logic [15:0] current_sample;

    logic        fifo_do_write;
    logic        fifo_do_read;

    assign fifo_do_write = sample_valid && (fifo_count < MAX_SAMPLES);
    assign fifo_do_read  = (state == ST_IDLE) && (fifo_count > 0);

    // -------------------------------------------------------------------------
    // Accumulator
    // -------------------------------------------------------------------------
    logic signed [31:0] accumulator;

    // -------------------------------------------------------------------------
    // DSP inference: multiplier
    // -------------------------------------------------------------------------
    (* use_dsp = "yes" *)
    logic signed [31:0] mult_pipe;   // registered product: breaks BRAM->DSP->adder path

    logic [4:0] mac_tap;
    logic       last_sample_reg;

    // Saturation wiring
    logic signed [31:0] sat_in;
    logic signed [15:0] sat_out;

    saturation u_sat (
        .data_in  (sat_in),
        .data_out (sat_out)
    );

    assign sat_in = accumulator;

    // -------------------------------------------------------------------------
    // Main FSM  +  FIFO write  +  shift-reg reset on new packet
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= ST_IDLE;
            mac_tap         <= '0;
            accumulator     <= '0;
            mult_pipe       <= '0;
            coeff_re        <= 1'b0;
            coeff_addr      <= '0;
            out_data        <= '0;
            out_valid       <= 1'b0;
            out_last        <= 1'b0;
            last_sample_reg <= 1'b0;
            current_sample  <= '0;
            fifo_wr_ptr     <= '0;
            fifo_rd_ptr     <= '0;
            fifo_count      <= '0;
            for (int i = 0; i < MAX_TAPS; i++)
                shift_reg[i] <= '0;
        end else begin
            out_valid <= 1'b0;
            out_last  <= 1'b0;
            coeff_re  <= 1'b0;

            // -----------------------------------------------------------------
            // FIFO write path – always accepts new samples regardless of FSM
            // state.  Samples are dropped only if the FIFO is somehow full,
            // which cannot happen for the legal input sizes (S ≤ MAX_SAMPLES).
            // -----------------------------------------------------------------
            if (fifo_do_write) begin
                sample_fifo[fifo_wr_ptr] <= sample_data;
                last_fifo  [fifo_wr_ptr] <= sample_last;
                fifo_wr_ptr <= (fifo_wr_ptr == 6'(MAX_SAMPLES-1))
                                ? '0 : fifo_wr_ptr + 1;
                `ifndef SYNTHESIS
                $display("[CH%0d] FIFO write: data=0x%04X, last=%0d, wr_ptr=%0d, count=%0d, time=%0t", 
                         CH_ID, sample_data, sample_last, fifo_wr_ptr, fifo_count, $time);
                `endif
            end

            // FIFO count – net change from simultaneous write and/or read
            if (fifo_do_write && !fifo_do_read)
                fifo_count <= fifo_count + 1;
            else if (!fifo_do_write && fifo_do_read)
                fifo_count <= fifo_count - 1;

            // -----------------------------------------------------------------
            // New-packet reset
            // -----------------------------------------------------------------
            if (hdr_valid) begin
                for (int i = 0; i < MAX_TAPS; i++)
                    shift_reg[i] <= '0;
                fifo_wr_ptr <= '0;
                fifo_rd_ptr <= '0;
                fifo_count  <= '0;
                state       <= ST_IDLE;
            end else begin
                case (state)
                    // ---------------------------------------------------------
                    // ST_IDLE: wait for a sample in the FIFO.
                    // Issue BRAM read for tap 0 here so data arrives after
                    // ST_SHIFT without needing a dedicaated ST_WAIT_BRAM state.
                    ST_IDLE: begin
                        if (fifo_do_read) begin
                            current_sample  <= sample_fifo[fifo_rd_ptr];
                            last_sample_reg <= last_fifo  [fifo_rd_ptr];
                            fifo_rd_ptr     <= (fifo_rd_ptr == 6'(MAX_SAMPLES-1))
                                               ? '0 : fifo_rd_ptr + 1;
                            // Pre-fetch tap 0 now; BRAM output ready after ST_SHIFT
                            coeff_re   <= 1'b1;
                            coeff_addr <= 6'(CH_ID * MAX_TAPS);
                            state      <= ST_SHIFT;
                            `ifndef SYNTHESIS
                            $display("[CH%0d] FIFO read: rd_ptr=%0d, count=%0d, will_be_last=%0d, time=%0t", 
                                     CH_ID, fifo_rd_ptr, fifo_count, last_fifo[fifo_rd_ptr], $time);
                            `endif
                        end
                    end

                    // ---------------------------------------------------------
                    // ST_SHIFT: push current_sample into delay line.
                    // Tap 0 BRAM read was issued in ST_IDLE — data will be ready
                    // in ST_MAC (2 cycles later), not now (1 cycle later).
                    // Do NOT save coeff here due to BRAM timing.
                    ST_SHIFT: begin
                        for (int i = MAX_TAPS-1; i > 0; i--)
                            shift_reg[i] <= shift_reg[i-1];
                        shift_reg[0] <= current_sample;

                        accumulator <= '0;
                        mult_pipe   <= '0;
                        mac_tap     <= '0;
                        
                        // Fetch tap 1 NOW for use in second MAC iteration
                        if (num_taps > 1) begin
                            coeff_re   <= 1'b1;
                            coeff_addr <= 6'(CH_ID * MAX_TAPS + 1);
                        end
                        
                        state <= ST_MAC;
                    end

                    // ---------------------------------------------------------
                    // ST_MAC: 1 cycle per tap.
                    // coeff_dout holds the coefficient for current mac_tap
                    // (fetched in previous state: tap 0 from ST_IDLE, tap 1 from ST_SHIFT,
                    //  tap N from previous ST_MAC iteration for N>1).
                    // While processing tap N, fetch tap N+1.
                    ST_MAC: begin
                        // Stage 1: multiply current tap; Stage 2: accumulate previous product
                        mult_pipe   <= $signed(shift_reg[mac_tap]) * $signed(coeff_dout);
                        accumulator <= accumulator + (mult_pipe >>> 15);

                        // Check for last tap BEFORE incrementing
                        if (mac_tap == num_taps - 1) begin
                            state <= ST_MAC_LAST;
                        end else begin
                            // Fetch next tap: mac_tap+2 (since tap 1 was pre-fetched in ST_SHIFT)
                            // For mac_tap=0: fetch tap 2
                            // For mac_tap=1: fetch tap 3, etc.
                            if (mac_tap + 2 < num_taps) begin
                                coeff_re   <= 1'b1;
                                coeff_addr <= 6'(CH_ID * MAX_TAPS + mac_tap + 2);
                            end
                        end
                        
                        mac_tap <= mac_tap + 1;
                    end

                    // ---------------------------------------------------------
                    // ST_MAC_LAST: drain the final product from the pipeline.
                    ST_MAC_LAST: begin
                        accumulator <= accumulator + (mult_pipe >>> 15);
                        state       <= ST_OUTPUT;
                    end

                    // ---------------------------------------------------------
                    ST_OUTPUT: begin
                        out_data  <= sat_out;
                        out_valid <= 1'b1;
                        out_last  <= last_sample_reg;
                        state     <= ST_IDLE;
                        `ifndef SYNTHESIS
                        $display("[CH%0d] Output: data=0x%04X (%0d), last=%0d, acc=0x%08X, time=%0t", 
                                 CH_ID, sat_out, $signed(sat_out), last_sample_reg, accumulator, $time);
                        `endif
                    end

                    default: state <= ST_IDLE;
                endcase
            end // !hdr_valid
        end
    end

endmodule