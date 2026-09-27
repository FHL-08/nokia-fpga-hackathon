####################
# Common Setup.

INCDIRS = 

HVL_SV_SOURCE = hvl_top.sv
HDL_SV_SOURCE = hdl_top.sv

UVM_OPTIONS = +UVM_TESTNAME=top_test_base +SEQ=top_fir_vseq

####################
# Questa support.

all: work sv opt sim64

sv: hvl_sv hdl_sv

vis: work sv vis_opt vis_sim

work:
	vlib work

hvl_sv:
	vlog -f top_test_filelist.f $(INCDIRS) $(HVL_SV_SOURCE)

hdl_sv:
	vlog $(INCDIRS) $(HDL_SV_SOURCE)

opt:
	qopt hdl_top hvl_top -o top_opt

vis_opt:
	qopt hdl_top hvl_top -o top_opt -debug -designfile design.bin

sim32:
	qsim -permit_unmatched_virtual_intf -32 -pli $(AVERY_PLI)/linux/lib/libtb_ms.so top_opt $(UVM_OPTIONS) +nowarnTSCALE -t 1ps -batch -l questa.log -do "run -all; quit"
sim64:
	qsim -permit_unmatched_virtual_intf -64 -pli $(AVERY_PLI)/linux_x86_64/lib/libtb_ms.so top_opt $(UVM_OPTIONS) +nowarnTSCALE -t 1ps -batch -l questa.log -do "run -all; quit"

vis_sim:
	qsim -permit_unmatched_virtual_intf -64 -pli $(AVERY_PLI)/linux_x86_64/lib/libtb_ms.so top_opt $(UVM_OPTIONS) +nowarnTSCALE -t 1ps -batch -l questa.log -do "run -all; quit" -qwavedb=+signal+transaction+class+uvm_schematic
	qsim -designfile design.bin -wavefile qwave.db

vis_int: work sv vis_opt
	qsim -permit_unmatched_virtual_intf -64 -pli $(AVERY_PLI)/linux_x86_64/lib/libtb_ms.so top_opt $(UVM_OPTIONS) +nowarnTSCALE -t 1ps -l questa.log -visualizer=design.bin -qwavedb=+signal+transaction+class+uvm_schematic


####################
# Incisive support.

ius32:
	xrun -sv -uvm -quiet -licqueue \
         +loadpli1=$(AVERY_PLI)/linux/lib/libtb_xm.so:wizard_bootstrap \
         $(INCDIRS) -f top_test_filelist.f $(HVL_SV_SOURCE) $(HDL_SV_SOURCE) \
         $(UVM_OPTIONS)

ius64:
	xrun -sv -uvm -quiet -licqueue -64bit \
         +loadpli1=$(AVERY_PLI)/linux_x86_64/lib/libtb_xm.so:wizard_bootstrap \
         $(INCDIRS) -f top_test_filelist.f $(HVL_SV_SOURCE) $(HDL_SV_SOURCE) \
         $(UVM_OPTIONS)

####################
# VCS support.

vcs32:
	vcs +vcs+lic+wait -sverilog -ntb_opts uvm +vpi -l vcs.log -quiet +warn=noUII-L -timescale=1ps/1ps \
         $(AVERY_PLI)/linux/lib/libtb_vcs.so -P $(AVERY_PLI)/linux/src/tb_vcs.tab \
        $(INCDIRS) -f top_test_filelist.f $(HVL_SV_SOURCE) $(HDL_SV_SOURCE)
	./simv \
         $(UVM_OPTIONS)

vcs64:
	vcs +vcs+lic+wait -sverilog -ntb_opts uvm +vpi -l vcs.log -quiet +warn=noUII-L -full64 -timescale=1ps/1ps \
         $(AVERY_PLI)/linux_x86_64/lib/libtb_vcs.so -P $(AVERY_PLI)/linux_x86_64/src/tb_vcs.tab \
        $(INCDIRS) -f top_test_filelist.f $(HVL_SV_SOURCE) $(HDL_SV_SOURCE)
	./simv \
         $(UVM_OPTIONS)

####################
# Cleanup.

clean:
	rm -rf work transcript vsim.wlf design.bin qwave.db questa.log *tracker*
	rm -rf csrc simv* ucli.key vc_hdrs.h
	rm -rf xcelium.d xrun.log xrun.history

.PHONY: all sv hvl_sv hdl_sv opt sim32 sim64 ius32 ius64 vcs32 vcs64
.PHONY: vis vis_opt vis_sim vis_int
