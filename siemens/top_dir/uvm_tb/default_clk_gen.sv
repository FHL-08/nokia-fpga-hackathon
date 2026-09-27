//
// File: default_clk_gen.sv
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
module default_clk_gen
(
    output reg  CLK
);
    
    timeunit 1ns;
    timeprecision 1ns;
    
    initial
    begin
        CLK = 0;
        forever
        begin
            #1 CLK = ~CLK;
        end
    end

endmodule: default_clk_gen

