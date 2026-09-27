//
// File: default_reset_gen.sv
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
module default_reset_gen
(
    output reg  RESET,
    input  reg  CLK_IN
);
    
    initial
    begin
        RESET = 1;
        
        RESET = ~RESET;
        
        repeat ( 2 )
        begin
            @( posedge CLK_IN );
        end
        
        RESET = ~RESET;
    end

endmodule: default_reset_gen

