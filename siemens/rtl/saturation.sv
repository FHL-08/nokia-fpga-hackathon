// =============================================================================
// Module      : saturation
// Description : Saturates a wide signed accumulator result to Q1.15 range.
//               Input is a 32-bit signed value (result of Q1.15 x Q1.15 mult
//               and accumulation). Output is 16-bit signed Q1.15.
// =============================================================================
module saturation (
    input  logic signed [31:0] data_in,
    output logic signed [15:0] data_out
);

    // Q1.15 x Q1.15 = Q2.30 product; after summing up to 16 taps we have
    // up to Q6.30 in 36 bits, but we keep 32-bit accumulator and check
    // the upper bits for overflow.
    // Saturation limits: MAX =  32767 (0x7FFF), MIN = -32768 (0x8000)

    always_comb begin
        // If any bit above bit 15 differs from bit 15 (sign), we have overflow
        if (data_in > 32'sh00007FFF)
            data_out = 16'sh7FFF;
        else if (data_in < 32'shFFFF8000)
            data_out = 16'sh8000;
        else
            data_out = data_in[15:0];
    end

endmodule