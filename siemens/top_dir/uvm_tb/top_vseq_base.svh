//
// File: top_vseq_base.svh
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
class top_vseq_base extends uvm_sequence;
    `uvm_object_utils(top_vseq_base)
    // Handles for each of the target (QVIP) sequencers
    
    aaxi_stream_sequencer aaxi4_stream_master_0;
    aaxi_stream_sequencer aaxi4_stream_slave_0;
    function new
    (
        string name = "top_vseq_base"
    );
        super.new(name);
    endfunction
    
    task body;
    endtask: body
    
endclass: top_vseq_base

