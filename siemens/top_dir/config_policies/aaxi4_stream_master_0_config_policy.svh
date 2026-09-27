//
// File: aaxi4_stream_master_0_config_policy.sv
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
class aaxi4_stream_master_0_config_policy;
    static function void configure
    (
        input aaxi4_stream_master_0_cfg_t cfg
    );
        //
        // Agent setup configurations:
        //
        cfg.set_config_int("agent_type",aaxi_pkg::AAXI_MASTER);
        cfg.set_config_int("is_active",1);
        //
        // BFM setup configurations:
        //
        cfg.set_config_int("stream_if_type",aaxi_pkg::AAXI4STREAM);
        //
        // BFM setup configurations at default value:
        //    // Variable: tuser_width
        //cfg.set_config_int("tuser_width",AAXI_USER_BYTE_WIDTH*data_bus_bytes);
        //    // Variable: tvalid_ready_timeout
        //cfg.set_config_int("tvalid_ready_timeout",32'h00001388);
        //    // Variable: tlast_mode
        //cfg.set_config_int("tlast_mode",AAXI4_PACKET);
        //    // Variable: interleave_support
        //cfg.set_config_int("interleave_support",AAXI4_NONE);
        //    // Variable: TS_cfgread_CRS
        //cfg.set_config_int("TS_cfgread_CRS",0);
        //    // // switch for checking ports.TKEEP, default 1, enable_tkeep is 0 not to check
        //cfg.set_config_int("enable_tkeep",1);
        //    // // switch for checking ports.TSTRB, default 1, enable_tstrb is 0 not to check
        //cfg.set_config_int("enable_tstrb",1);
        //    // // switch for checking ports.TDEST with slave.device_id, default 0, not to check
        //cfg.set_config_int("enable_TDEST_check",0);
        //    // // switch for checking ports.TUSER signal, default 1, enable_tuser is 0 not to check
        //cfg.set_config_int("enable_tuser",1);
        //    // // switch for checking ports signal before reset process, default 0, enable_pre_reset_xz_check is 0 not to check
        //cfg.set_config_int("enable_pre_reset_xz_check",0);
        //    // // switch for checking ports.TLAST signal, default 1, enable_tlast is 0 not to check
        //cfg.set_config_int("enable_tlast",1);
        //    // // stream_tx_port_mode to send out packet while 1: last tr/0: first tr
        //cfg.set_config_int("stream_tx_port_mode",1);
        //    // // set as 1 to enable aaxi_device_class_stream_slave::rc_tr_Q
        //cfg.set_config_int("enable_stream_queue",0);
        //    // // set as 1 to enable aaxi4_stream_interconnect rx_port received tr and// modify TID = rx_port.port_id, let downstream could know source device// Interconnect components manipulate the TID signals
        //cfg.set_config_int("enable_stream_intc_modify_TID",0);
        //    // Variable: enable_tdata_fill
        //cfg.set_config_int("enable_tdata_fill",0);
        //    // Variable: tdata_value_fill
        //cfg.set_config_int("tdata_value_fill",0);
        //    // Turn off warning messages if AAXI_TDEST_WIDTH, AAXI_TID_WIDTH or AAXI_TUSER_WIDTH doesn't fit Recommended value
        //cfg.set_config_int("enable_recommendation_checking",0);
        //cfg.set_config_int("perf_stats",'{});
        //
        
    endfunction: configure
    
endclass: aaxi4_stream_master_0_config_policy

