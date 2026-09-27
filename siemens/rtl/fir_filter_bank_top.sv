// =============================================================================
// Module      : fir_filter_bank_top
// Description : Top-level integration of the adaptive FIR filter bank.
//               Instantiates parser, BRAM, 4x FIR channel engines,
//               and output packetizer.
// =============================================================================
module fir_filter_bank_top  #(
    parameter int CH_ID      = 0)
    (
    input  logic        clk,
    input  logic        rst_n,

    // Input AXI-Stream
    input  logic [31:0] s_data,
    input  logic        s_valid,
    output logic        s_ready,

    // Output AXI-Stream
    output logic [31:0] m_data,
    output logic        m_valid,
    output logic        m_last,
    input  logic        m_ready
);

    localparam int MAX_CHANNELS = 4;
    localparam int MAX_TAPS     = 16;
    localparam int MAX_SAMPLES  = 64;

    // -------------------------------------------------------------------------
    // Parser outputs
    // -------------------------------------------------------------------------
    logic [3:0]  num_channels;
    logic [4:0]  num_taps;
    logic [6:0]  num_samples;
    logic        hdr_valid;

    logic        coeff_we;
    logic [5:0]  coeff_addr_wr;
    logic [15:0] coeff_din;

    logic [15:0] sample_data;
    logic [1:0]  sample_ch;
    logic        sample_valid;
    logic        sample_last;
    logic        pkt_done;

    // -------------------------------------------------------------------------
    // BRAM read ports (one per channel)
    // -------------------------------------------------------------------------
    logic        coeff_re   [0:MAX_CHANNELS-1];
    logic [5:0]  coeff_addr_rd [0:MAX_CHANNELS-1];
    logic [15:0] coeff_dout [0:MAX_CHANNELS-1];

    // -------------------------------------------------------------------------
    // FIR channel outputs
    // -------------------------------------------------------------------------
    logic signed [15:0] ch_data  [0:MAX_CHANNELS-1];
    logic               ch_valid [0:MAX_CHANNELS-1];
    logic               ch_last  [0:MAX_CHANNELS-1];

    // -------------------------------------------------------------------------
    // Per-channel sample routing
    // -------------------------------------------------------------------------
    logic [15:0] ch_sample_data  [0:MAX_CHANNELS-1];
    logic        ch_sample_valid [0:MAX_CHANNELS-1];
    logic        ch_sample_last  [0:MAX_CHANNELS-1];

    genvar c;
    generate
        for (c = 0; c < MAX_CHANNELS; c++) begin : gen_ch_route
            assign ch_sample_data[c]  = sample_data;
            assign ch_sample_valid[c] = sample_valid && (sample_ch == c[1:0]);
            assign ch_sample_last[c]  = sample_last  && (sample_ch == c[1:0]);
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Packet Parser
    // -------------------------------------------------------------------------
    packet_parser #(
        .MAX_CHANNELS (MAX_CHANNELS),
        .MAX_TAPS     (MAX_TAPS),
        .MAX_SAMPLES  (MAX_SAMPLES)
    ) u_parser (
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
        .coeff_addr   (coeff_addr_wr),
        .coeff_din    (coeff_din),
        .sample_data  (sample_data),
        .sample_ch    (sample_ch),
        .sample_valid (sample_valid),
        .sample_last  (sample_last),
        .pkt_done     (pkt_done)
    );

    // -------------------------------------------------------------------------
    // Coefficient BRAMs (one per channel for independent read access)
    // All share the same write port (broadcast write)
    // -------------------------------------------------------------------------
    generate
        for (c = 0; c < MAX_CHANNELS; c++) begin : gen_bram
            coeff_bram #(
                .DEPTH (MAX_CHANNELS * MAX_TAPS),
                .WIDTH (16)
            ) u_bram (
                .clk_a  (clk),
                .we_a   (coeff_we),
                .addr_a (coeff_addr_wr),
                .din_a  (coeff_din),
                .clk_b  (clk),
                .re_b   (coeff_re[c]),
                .addr_b (coeff_addr_rd[c]),
                .dout_b (coeff_dout[c])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // FIR Channel Engines
    // -------------------------------------------------------------------------
    generate
        for (c = 0; c < MAX_CHANNELS; c++) begin : gen_fir
            fir_channel #(
                .CH_ID       (c),
                .MAX_TAPS    (MAX_TAPS),
                .MAX_SAMPLES (MAX_SAMPLES)
            ) u_fir (
                .clk          (clk),
                .rst_n        (rst_n),
                .hdr_valid    (hdr_valid),
                .num_taps     (num_taps),
                .num_samples  (num_samples),
                .sample_data  (ch_sample_data[c]),
                .sample_valid (ch_sample_valid[c]),
                .sample_last  (ch_sample_last[c]),
                .coeff_re     (coeff_re[c]),
                .coeff_addr   (coeff_addr_rd[c]),
                .coeff_dout   (coeff_dout[c]),
                .out_data     (ch_data[c]),
                .out_valid    (ch_valid[c]),
                .out_last     (ch_last[c])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Output Packetizer
    // -------------------------------------------------------------------------
    output_packetizer #(
        .MAX_CHANNELS (MAX_CHANNELS),
        .MAX_SAMPLES  (MAX_SAMPLES)
    ) u_packetizer (
        .clk          (clk),
        .rst_n        (rst_n),
        .num_channels (num_channels),
        .num_taps     (num_taps),
        .num_samples  (num_samples),
        .hdr_valid    (hdr_valid),
        .ch_data      (ch_data),
        .ch_valid     (ch_valid),
        .ch_last      (ch_last),
        .m_data       (m_data),
        .m_valid      (m_valid),
        .m_last       (m_last),
        .m_ready      (m_ready)
    );

endmodule
