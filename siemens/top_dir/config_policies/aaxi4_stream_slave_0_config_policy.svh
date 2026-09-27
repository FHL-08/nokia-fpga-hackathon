//
// File: aaxi4_stream_slave_0_config_policy.sv
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
class aaxi4_stream_slave_0_config_policy;
    static function void configure
    (
        input aaxi4_stream_slave_0_cfg_t cfg
    );
        //
        // Agent setup configurations:
        //
        cfg.set_config_int("agent_type",aaxi_pkg::AAXI_SLAVE);
        cfg.set_config_int("is_active",1);
        //
        // BFM setup configurations:
        //
        cfg.set_config_int("tready_default",1);
        cfg.set_config_int("enable_tkeep",0);
        cfg.set_config_int("enable_tstrb",0);
        cfg.set_config_int("enable_tuser",0);
        cfg.set_config_int("enable_tlast",0);
        cfg.set_config_int("stream_if_type",aaxi_pkg::AAXI4STREAM);
        //
        // BFM setup configurations at default value:
        //    // Variable: tuser_width
        //cfg.set_config_int("tuser_width",AAXI_USER_BYTE_WIDTH*data_bus_bytes);
        //    // Variable: tvalid_ready_timeout
        //cfg.set_config_int("tvalid_ready_timeout",32'h00001388);
        //    // Variable: TS_cfgread_CRS
        //cfg.set_config_int("TS_cfgread_CRS",0);
        //    // // switch for checking ports.TDEST with slave.device_id, default 0, not to check
        //cfg.set_config_int("enable_TDEST_check",0);
        //    // // switch for checking ports signal before reset process, default 0, enable_pre_reset_xz_check is 0 not to check
        //cfg.set_config_int("enable_pre_reset_xz_check",0);
        //    // // set as 1 to enable aaxi_device_class_stream_slave::fifo_Q/rx_pkt_Q
        //cfg.set_config_int("enable_aaxi_queue",0);
        //    // // set as 1 to enable aaxi_device_class_stream_slave::rc_tr_Q
        //cfg.set_config_int("enable_stream_queue",0);
        //    // // set as 1 to enable aaxi4_stream_interconnect rx_port received tr and// modify TID = rx_port.port_id, let downstream could know source device// Interconnect components manipulate the TID signals
        //cfg.set_config_int("enable_stream_intc_modify_TID",0);
        //    // Variable:- enable_period_tready_delay
        //cfg.set_config_int("enable_period_tready_delay",0);
        //    // Variable:- default_period_tr_h_delay
        //cfg.set_config_int("default_period_tr_h_delay",32'h00000004);
        //    // Variable:- random_period_tr_h_delay
        //cfg.set_config_int("random_period_tr_h_delay",1);
        //    // Variable:- max_period_tr_h_delay
        //cfg.set_config_int("max_period_tr_h_delay",32'h00000005);
        //    // Variable:- min_period_tr_h_delay
        //cfg.set_config_int("min_period_tr_h_delay",32'h00000000);
        //    // Variable:- default_period_tr_l_delay
        //cfg.set_config_int("default_period_tr_l_delay",32'h00000005);
        //    // Variable:- random_period_tr_l_delay
        //cfg.set_config_int("random_period_tr_l_delay",1);
        //    // Variable:- max_period_tr_l_delay
        //cfg.set_config_int("max_period_tr_l_delay",32'h00000005);
        //    // Variable:- min_period_tr_l_delay
        //cfg.set_config_int("min_period_tr_l_delay",32'h00000000);
        //    // Turn off warning messages if AAXI_TDEST_WIDTH, AAXI_TID_WIDTH or AAXI_TUSER_WIDTH doesn't fit Recommended value
        //cfg.set_config_int("enable_recommendation_checking",0);
        //cfg.set_config_int("perf_stats",'{});
        //
        
    endfunction: configure
    
endclass: aaxi4_stream_slave_0_config_policy

