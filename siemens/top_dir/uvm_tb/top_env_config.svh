//
// File: top_env_config.svh
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
class top_env_config extends uvm_object;
    `uvm_object_utils(top_env_config)
    // Handles for vip config for each of the QVIP instances
    
    aaxi4_stream_master_0_cfg_t aaxi4_stream_master_0_cfg;
    aaxi4_stream_slave_0_cfg_t aaxi4_stream_slave_0_cfg;
    function new
    (
        string name = "top_env_config"
    );
        super.new(name);
    endfunction
    
    extern function void initialize;
    
endclass: top_env_config

function void top_env_config::initialize;
endfunction: initialize

