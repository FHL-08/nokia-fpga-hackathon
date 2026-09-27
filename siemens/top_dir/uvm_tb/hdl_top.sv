//
// File: hdl_top.sv
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
//
//Time resolution of '1ps' will be used (See Makefiles and scripts)
module hdl_top;
    import uvm_pkg::*;
    import top_params_pkg::*;
    wire                                                                                                      default_clk_gen_CLK;
    wire                                                                                                      default_reset_gen_RESET;
    wire                                                                                                       aaxi4_stream_master_0_TREADY;
    wire  [(aaxi4_stream_master_0_params::DATA_WIDTH/8)-1:0]                                                   aaxi4_stream_master_0_TSTRB;
    wire  [(aaxi4_stream_master_0_params::DATA_WIDTH/8)-1:0]                                                   aaxi4_stream_master_0_TKEEP;
    wire  [aaxi4_stream_master_0_params::ID_WIDTH-1:0]                                                         aaxi4_stream_master_0_TID;
    wire  [aaxi4_stream_master_0_params::DEST_WIDTH-1:0]                                                       aaxi4_stream_master_0_TDEST;
    wire  [((aaxi4_stream_master_0_params::USER_BYTE_WIDTH*(aaxi4_stream_master_0_params::DATA_WIDTH/8))-1):0] aaxi4_stream_master_0_TUSER;
    wire                                                                                                       aaxi4_stream_slave_0_TREADY;
    wire  [(aaxi4_stream_slave_0_params::DATA_WIDTH/8)-1:0]                                                    aaxi4_stream_slave_0_TSTRB;
    wire  [(aaxi4_stream_slave_0_params::DATA_WIDTH/8)-1:0]                                                    aaxi4_stream_slave_0_TKEEP;
    wire  [aaxi4_stream_slave_0_params::ID_WIDTH-1:0]                                                          aaxi4_stream_slave_0_TID   = '0;
    wire  [aaxi4_stream_slave_0_params::DEST_WIDTH-1:0]                                                        aaxi4_stream_slave_0_TDEST = '0;
    wire  [(aaxi4_stream_slave_0_params::USER_BYTE_WIDTH*(aaxi4_stream_slave_0_params::DATA_WIDTH/8))-1:0]     aaxi4_stream_slave_0_TUSER;
    wire logic [31:0]                                                                                               fir_filter_bank_top_s_data;
    wire logic                                                                                                      fir_filter_bank_top_s_valid;
    wire logic                                                                                                      fir_filter_bank_top_s_last;
    wire logic                                                                                                      fir_filter_bank_top_s_ready;
    wire logic [31:0]                                                                                               fir_filter_bank_top_m_data;
    wire logic                                                                                                      fir_filter_bank_top_m_valid;
    wire logic                                                                                                      fir_filter_bank_top_m_last;
    wire logic                                                                                                      fir_filter_bank_top_m_ready;
    default_clk_gen default_clk_gen(.CLK(default_clk_gen_CLK));
    
    default_reset_gen default_reset_gen(.RESET(default_reset_gen_RESET),.CLK_IN(default_clk_gen_CLK));
    
    aaxi4_stream_master 
    #(
        .ID_WIDTH(aaxi4_stream_master_0_params::ID_WIDTH),
        .DEST_WIDTH(aaxi4_stream_master_0_params::DEST_WIDTH),
        .DATA_WIDTH(aaxi4_stream_master_0_params::DATA_WIDTH),
        .USER_BYTE_WIDTH(aaxi4_stream_master_0_params::USER_BYTE_WIDTH),
        .PATH_NAME("uvm_test_top"),
        .IF_NAME("aaxi4_stream_master_0")
    )
    aaxi4_stream_master_0
    (
        .ACLK(default_clk_gen_CLK),
        .ARESETn(default_reset_gen_RESET),
        .TVALID(fir_filter_bank_top_s_valid),
        .TREADY(fir_filter_bank_top_s_ready),
        .TDATA(fir_filter_bank_top_s_data),
        .TSTRB(aaxi4_stream_master_0_TSTRB),
        .TKEEP(aaxi4_stream_master_0_TKEEP),
        .TLAST(fir_filter_bank_top_s_last),
        .TID(aaxi4_stream_master_0_TID),
        .TDEST(aaxi4_stream_master_0_TDEST),
        .TUSER(aaxi4_stream_master_0_TUSER)
    );
    
    aaxi4_stream_slave 
    #(
        .ID_WIDTH(aaxi4_stream_slave_0_params::ID_WIDTH),
        .DEST_WIDTH(aaxi4_stream_slave_0_params::DEST_WIDTH),
        .DATA_WIDTH(aaxi4_stream_slave_0_params::DATA_WIDTH),
        .USER_BYTE_WIDTH(aaxi4_stream_slave_0_params::USER_BYTE_WIDTH),
        .PATH_NAME("uvm_test_top"),
        .IF_NAME("aaxi4_stream_slave_0")
    )
    aaxi4_stream_slave_0
    (
        .ACLK(default_clk_gen_CLK),
        .ARESETn(default_reset_gen_RESET),
        .TVALID(fir_filter_bank_top_m_valid),
        .TREADY(fir_filter_bank_top_m_ready),
        .TDATA(fir_filter_bank_top_m_data),
        .TSTRB(aaxi4_stream_slave_0_TSTRB),
        .TKEEP(aaxi4_stream_slave_0_TKEEP),
        .TLAST(fir_filter_bank_top_m_last),
        .TID(aaxi4_stream_slave_0_TID),
        .TDEST(aaxi4_stream_slave_0_TDEST),
        .TUSER(aaxi4_stream_slave_0_TUSER)
    );
    
    fir_filter_bank_top 
    #(
        .CH_ID(fir_filter_bank_top_params::CH_ID)
    )
    fir_filter_bank_top
    (
        .clk(default_clk_gen_CLK),
        .rst_n(default_reset_gen_RESET),
        .s_data(fir_filter_bank_top_s_data),
        .s_valid(fir_filter_bank_top_s_valid),
        //.s_last(fir_filter_bank_top_s_last),
        .s_ready(fir_filter_bank_top_s_ready),
        .m_data(fir_filter_bank_top_m_data),
        .m_valid(fir_filter_bank_top_m_valid),
        .m_last(fir_filter_bank_top_m_last),
        .m_ready(fir_filter_bank_top_m_ready)
    );
    

endmodule: hdl_top

