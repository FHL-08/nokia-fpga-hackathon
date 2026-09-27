//
// File: top_example_vseq.svh
//
// Generated from Questa VIP Configurator (2026.1_20260323)
// Generated using Questa VIP Library ( DEV : __DATE__ )
//
// The purpose of this example virtual sequence is to show how the default or selected sequences for 
// each QVIP can be run. The sequences are run in series in an arbitary order. 
class top_example_vseq extends top_vseq_base;
    `uvm_object_utils(top_example_vseq)
    function new
    (
        string name = "top_example_vseq"
    );
        super.new(name);
    endfunction
    
    extern task body;
    
endclass: top_example_vseq

task top_example_vseq::body;
    aaxi_stream_all_byte_seq aaxi4_stream_master_0_seq_0;
    
    aaxi4_stream_master_0_seq_0 = aaxi_stream_all_byte_seq::type_id::create("aaxi_stream_all_byte_seq");
    
    // Sequences run in the following order
    
    begin
        aaxi4_stream_master_0_seq_0.start(aaxi4_stream_master_0);
    end
endtask: body

