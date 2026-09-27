// =============================================================================
// Package     : tb_pkg
// Description : Test vector definitions and helper tasks/functions for the
//               FIR filter bank testbench.
// =============================================================================
package tb_pkg;

    // -------------------------------------------------------------------------
    // Q1.15 helpers
    // -------------------------------------------------------------------------
    typedef logic signed [15:0] q15_t;

    function automatic logic signed [15:0] real_to_q15(input real val);
        real clamped;
        clamped = (val >  0.999969482421875) ?  0.999969482421875 :
                  (val < -1.0)               ? -1.0               : val;
        return q15_t'(int'(clamped * 32768.0));
    endfunction

    function automatic real q15_to_real(input logic signed [15:0] val);
        return real'(val) / 32768.0;
    endfunction

    // -------------------------------------------------------------------------
    // Saturating Q1.15 accumulation (software reference model)
    // -------------------------------------------------------------------------
    function automatic logic signed [15:0] fir_ref_sample(
        input logic signed [15:0] shift_reg [],
        input logic signed [15:0] coeffs    [],
        input int                 num_taps
    );
        logic signed [31:0] acc;
        logic signed [31:0] prod;
        acc = '0;
        for (int k = 0; k < num_taps; k++) begin
            prod = $signed(shift_reg[k]) * $signed(coeffs[k]);
            acc  = acc + (prod >>> 15);
        end
        // Saturate
        if      (acc >  32'sh00007FFF) return 16'sh7FFF;
        else if (acc <  32'shFFFF8000) return 16'sh8000;
        else                           return acc[15:0];
    endfunction

    // -------------------------------------------------------------------------
    // Test vector structure
    // -------------------------------------------------------------------------
    typedef struct {
        int unsigned num_channels;
        int unsigned num_taps;
        int unsigned num_samples;
        logic signed [15:0] coeffs  [4][16];  // [ch][tap]
        logic signed [15:0] samples [4][64];  // [ch][sample]
        string description;
    } test_vector_t;

    // -------------------------------------------------------------------------
    // Build test vector 0: Simple 1-channel, 4-tap moving average
    // -------------------------------------------------------------------------
    function automatic test_vector_t build_tv0();
        test_vector_t tv;
        tv.num_channels = 1;
        tv.num_taps     = 4;
        tv.num_samples  = 8;
        tv.description  = "TV0: 1ch, 4-tap moving average";

        // Coefficients: 0.25 each = moving average
        for (int k = 0; k < 4; k++)
            tv.coeffs[0][k] = real_to_q15(0.25);

        // Samples: impulse at index 0
        tv.samples[0][0] = real_to_q15(1.0);
        for (int n = 1; n < 8; n++)
            tv.samples[0][n] = real_to_q15(0.0);

        return tv;
    endfunction

    // -------------------------------------------------------------------------
    // Build test vector 1: 2-channel, 8-tap, sinusoidal input
    // -------------------------------------------------------------------------
    function automatic test_vector_t build_tv1();
        test_vector_t tv;
        real pi;
        pi = 3.14159265358979;
        tv.num_channels = 2;
        tv.num_taps     = 8;
        tv.num_samples  = 16;
        tv.description  = "TV1: 2ch, 8-tap, sinusoidal input";

        // Channel 0: low-pass coefficients (Hann-windowed sinc, fc=0.1)
        tv.coeffs[0][0] = real_to_q15( 0.0045);
        tv.coeffs[0][1] = real_to_q15( 0.0428);
        tv.coeffs[0][2] = real_to_q15( 0.1472);
        tv.coeffs[0][3] = real_to_q15( 0.2983);
        tv.coeffs[0][4] = real_to_q15( 0.2983);
        tv.coeffs[0][5] = real_to_q15( 0.1472);
        tv.coeffs[0][6] = real_to_q15( 0.0428);
        tv.coeffs[0][7] = real_to_q15( 0.0045);

        // Channel 1: identity (delta) filter
        tv.coeffs[1][0] = real_to_q15(1.0);
        for (int k = 1; k < 8; k++)
            tv.coeffs[1][k] = real_to_q15(0.0);

        // Samples: sine wave at 0.05 normalized frequency
        for (int n = 0; n < 16; n++) begin
            tv.samples[0][n] = real_to_q15(0.8 * $sin(2.0*pi*0.05*n));
            tv.samples[1][n] = real_to_q15(0.5 * $cos(2.0*pi*0.1 *n));
        end

        return tv;
    endfunction

    // -------------------------------------------------------------------------
    // Build test vector 2: 4-channel, 16-tap, saturation stress test
    // -------------------------------------------------------------------------
    function automatic test_vector_t build_tv2();
        test_vector_t tv;
        tv.num_channels = 4;
        tv.num_taps     = 16;
        tv.num_samples  = 8;
        tv.description  = "TV2: 4ch, 16-tap, saturation stress";

        // All coefficients = 0.5 (will cause overflow with large inputs)
        for (int c = 0; c < 4; c++)
            for (int k = 0; k < 16; k++)
                tv.coeffs[c][k] = real_to_q15(0.5);

        // All samples = max positive (0.9999)
        for (int c = 0; c < 4; c++)
            for (int n = 0; n < 8; n++)
                tv.samples[c][n] = real_to_q15(0.9999);

        return tv;
    endfunction

    // -------------------------------------------------------------------------
    // Build test vector 3: 1-channel, 4-tap minimum config
    // -------------------------------------------------------------------------
    function automatic test_vector_t build_tv3();
        test_vector_t tv;
        tv.num_channels = 1;
        tv.num_taps     = 4;
        tv.num_samples  = 64;
        tv.description  = "TV3: 1ch, 4-tap, max samples (64)";

        // Differentiator-like: [1, -1, 0, 0]
        tv.coeffs[0][0] = real_to_q15( 0.5);
        tv.coeffs[0][1] = real_to_q15(-0.5);
        tv.coeffs[0][2] = real_to_q15( 0.0);
        tv.coeffs[0][3] = real_to_q15( 0.0);

        // Ramp input
        for (int n = 0; n < 64; n++)
            tv.samples[0][n] = real_to_q15((n % 32) / 32.0 * 0.9);

        return tv;
    endfunction

    // -------------------------------------------------------------------------
    // Build test vector 4: 3-channel, 12-tap, alternating coefficients
    // -------------------------------------------------------------------------
    function automatic test_vector_t build_tv4();
        test_vector_t tv;
        tv.num_channels = 3;
        tv.num_taps     = 12;
        tv.num_samples  = 20;
        tv.description  = "TV4: 3ch, 12-tap, alternating coefficients";

        // Alternating sign coefficients
        for (int c = 0; c < 3; c++)
            for (int k = 0; k < 12; k++)
                tv.coeffs[c][k] = (k % 2 == 0) ?
                                   real_to_q15( 0.083) :
                                   real_to_q15(-0.083);

        // Random-ish samples
        for (int c = 0; c < 3; c++)
            for (int n = 0; n < 20; n++)
                tv.samples[c][n] = real_to_q15(
                    0.6 * $sin(2.0*3.14159*(c+1)*0.07*n));

        return tv;
    endfunction

endpackage