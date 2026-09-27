//
// File: top_env.svh
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
`include "uvm_macros.svh"
class top_env extends uvm_env;
    `uvm_component_utils(top_env)
    top_env_config cfg;
    // Agent handles
    
    aaxi4_stream_master_0_agent_t aaxi4_stream_master_0;
    aaxi4_stream_slave_0_agent_t aaxi4_stream_slave_0;
    // FIR scoreboard
    fir_scoreboard fir_sb;
    function new
    (
        string name = "top_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction
    
    extern function void build_phase
    (
        uvm_phase phase
    );

    extern function void connect_phase
    (
        uvm_phase phase
    );
    
endclass: top_env

function void top_env::build_phase
(
    uvm_phase phase
);
    if ( cfg == null )
    begin
        if ( !uvm_config_db #(top_env_config)::get(this, "", "env_config", cfg) )
        begin
            `uvm_error("build_phase", "Unable to find the env config object in the uvm_config_db")
        end
    end
    aaxi4_stream_master_0 = aaxi4_stream_master_0_agent_t::type_id::create("aaxi4_stream_master_0", this );
    aaxi4_stream_master_0.set_config(cfg.aaxi4_stream_master_0_cfg);
    
    aaxi4_stream_slave_0 = aaxi4_stream_slave_0_agent_t::type_id::create("aaxi4_stream_slave_0", this );
    aaxi4_stream_slave_0.set_config(cfg.aaxi4_stream_slave_0_cfg);

    fir_sb = fir_scoreboard::type_id::create("fir_sb", this);
    
endfunction: build_phase

function void top_env::connect_phase
(
    uvm_phase phase
);
    aaxi4_stream_master_0.aaxi_stream_packet_ap.connect(fir_sb.master_export);
    aaxi4_stream_slave_0.aaxi_stream_packet_ap.connect(fir_sb.slave_export);
endfunction: connect_phase

