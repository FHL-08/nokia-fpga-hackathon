-f top_test_filelist.f
hdl_top.sv
hvl_top.sv
-64
-quiet
-permit_unmatched_virtual_intf
-designfile design.bin
-c
-pli $AVERY_PLI/linux_x86_64/lib/libtb_ms.so
+nowarnTSCALE -t 1ps
-do "run -all; quit"
+UVM_TESTNAME=top_test_base
+SEQ=top_fir_vseq
-qwavedb=+signal+transaction+class+uvm_schematic
