//
// File: top_params_pkg.sv
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
package top_params_pkg;
    //
    // Import the necessary QVIP packages:
    //
    import aaxi_pkg::*;
    import aaxi_pkg_xactor::*;
    import aaxi_stream_seq_pkg::*;
    class fir_filter_bank_top_params;
        localparam int CH_ID = 0;
    endclass: fir_filter_bank_top_params
    
    class aaxi4_stream_master_0_params;
        localparam int ID_WIDTH        = 4;
        localparam int DEST_WIDTH      = 8;
        localparam int DATA_WIDTH      = 32;
        localparam int USER_BYTE_WIDTH = 8;
    endclass: aaxi4_stream_master_0_params
    
    typedef aaxi_stream_vip_config aaxi4_stream_master_0_cfg_t;
    
    typedef aaxi_stream_agent aaxi4_stream_master_0_agent_t;
    
    typedef virtual aaxi_intf aaxi4_stream_master_0_bfm_t;
    
    class aaxi4_stream_slave_0_params;
        localparam int ID_WIDTH        = 4;
        localparam int DEST_WIDTH      = 8;
        localparam int DATA_WIDTH      = 32;
        localparam int USER_BYTE_WIDTH = 8;
    endclass: aaxi4_stream_slave_0_params
    
    typedef aaxi_stream_vip_config aaxi4_stream_slave_0_cfg_t;
    
    typedef aaxi_stream_agent aaxi4_stream_slave_0_agent_t;
    
    typedef virtual aaxi_intf aaxi4_stream_slave_0_bfm_t;
    
    //
    // `includes for the config policy classes:
    //
    `include "aaxi4_stream_master_0_config_policy.svh"
    `include "aaxi4_stream_slave_0_config_policy.svh"
endpackage: top_params_pkg
