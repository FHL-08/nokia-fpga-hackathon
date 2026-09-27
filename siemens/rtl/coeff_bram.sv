// =============================================================================
// Module      : coeff_bram
// Description : True dual-port Block RAM storing FIR coefficients.
//               Port A = write (loading coefficients from parser).
//               Port B = read  (FIR channel engines reading coefficients).
//               Depth = 4 channels x 16 taps = 64 words of 16 bits.
// =============================================================================
module coeff_bram #(
    parameter int DEPTH = 64,   // 4 channels x 16 taps
    parameter int WIDTH = 16
)(
    // Port A – Write
    input  logic                      clk_a,
    input  logic                      we_a,
    input  logic [$clog2(DEPTH)-1:0]  addr_a,
    input  logic [WIDTH-1:0]          din_a,

    // Port B – Read
    input  logic                      clk_b,
    input  logic                      re_b,
    input  logic [$clog2(DEPTH)-1:0]  addr_b,
    output logic [WIDTH-1:0]          dout_b
);

    // Infer Block RAM
    (* ram_style = "block" *)
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // Port A – synchronous write
    always_ff @(posedge clk_a) begin
        if (we_a)
            mem[addr_a] <= din_a;
    end

    // Port B – synchronous read
    always_ff @(posedge clk_b) begin
        if (re_b)
            dout_b <= mem[addr_b];
    end

endmodule