QRUN=/opt/tools/Questa/questasim/bin/qrun
ROOT=..
VIVADO_PRJ=$(ROOT)/vivado/hackathon
XILINX_DATA=/opt/tools/Xilinx/2025.2/data

### Testbench selection: make <target> TB=tb_lite|tb_top
TB ?= tb_lite
ifeq ($(filter $(TB),tb_lite tb_top),)
$(error TB must be tb_lite or tb_top, got '$(TB)')
endif

### Vivado simulation fileset per testbench: sim_1 -> tb_lite, sim_full -> tb_top
XSIM_DIR_tb_lite=$(VIVADO_PRJ)/hackathon.sim/sim_1/behav/xsim
XSIM_DIR_tb_top=$(VIVADO_PRJ)/hackathon.sim/sim_full/behav/xsim
XSIM_DIR=$(XSIM_DIR_$(TB))

IP_MEM_FILES=microblaze_system_lmb_bram_0.mem microblaze_system_axi_bram_ctrl_0_bram_0.mem \
sc_xtlm_microblaze_system_smartconnect_0_0.mem
IP_MEM_FILES_tb_top=sc_xtlm_design_1_smartconnect_1_0.mem
IP_MEM_FILES_tb_lite=

SWITCHES= -modelsimini ./modelsim.ini -suppress 10016 -incr -mfcu -sv -work xil_defaultlib
LIBS= -L xil_defaultlib \
-L xbip_utils_v3_0_15 -L axi_utils_v2_0_11 -L c_reg_fd_v12_0_11 -L xbip_dsp48_wrapper_v3_0_7 -L xbip_pipe_v3_0_11 \
-L c_addsub_v12_0_21 -L c_shift_ram_v12_0_20 -L mult_gen_v12_0_24 -L floating_point_v7_1_21 -L cmpy_v6_0_27 -L xfft_v9_1_15 \
-L microblaze_v11_0_16 -L lmb_v10_v3_0_16 -L lmb_bram_if_cntlr_v4_0_27 -L blk_mem_gen_v8_4_12 -L proc_sys_reset_v5_0_17 \
-L axi_datamover_v5_1_37 -L axi_sg_v4_1_21 -L axi_dma_v7_1_37 -L axi_bram_ctrl_v4_1_13 -L smartconnect_v1_0 \
-L axi_infrastructure_v1_1_0 -L axi_register_slice_v2_1_36 -L axi_vip_v1_1_22 -L axis_infrastructure_v1_1_1 \
-L axis_data_fifo_v2_0_17 -L zynq_ultra_ps_e_vip_v1_0_22 -L xlconstant_v1_1_10 \
-L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -L xpm -L unisim

MB_IP=$(VIVADO_PRJ)/hackathon.ip_user_files/bd/microblaze_system/ip
MB_SC=$(MB_IP)/microblaze_system_smartconnect_0_0/bd_0/ip
BD_IP=$(VIVADO_PRJ)/hackathon.gen/sources_1/bd/design_1/ip
BD_SC=$(BD_IP)/design_1_smartconnect_1_0/bd_0/ip
AXI_VIP=$(ROOT)/tb/hackathon.gen/sources_1/ip/axi_vip_0

INCDIRS= +incdir+$(ROOT)/src +incdir+$(ROOT)/tb \
+incdir+$(ROOT)/src/tasks/task_8/microblaze_system/ipshared/f0b6/hdl/verilog \
+incdir+$(ROOT)/src/tasks/task_8/microblaze_system/ipshared/00fe/hdl/verilog \
+incdir+$(ROOT)/src/tasks/task_8/microblaze_system/ipshared/ec67/hdl \
+incdir+$(ROOT)/src/tasks/task_8/microblaze_system/ipshared/434f/hdl \
+incdir+$(XILINX_DATA)/xilinx_vip/include \
+incdir+$(XILINX_DATA)/rsb/busdef

INCDIRS_tb_top= \
+incdir+$(VIVADO_PRJ)/hackathon.gen/sources_1/bd/design_1/ipshared/ec67/hdl \
+incdir+$(VIVADO_PRJ)/hackathon.gen/sources_1/bd/design_1/ipshared/a0fe/hdl \
+incdir+$(VIVADO_PRJ)/hackathon.gen/sources_1/bd/design_1/ipshared/a415 \
+incdir+$(ROOT)/vivado/bd/design_1/ipshared/f0b6/hdl/verilog \
+incdir+$(ROOT)/vivado/bd/design_1/ipshared/00fe/hdl/verilog \
+incdir+$(ROOT)/vivado/bd/design_1/ipshared/ec67/hdl

INCDIRS_tb_lite= +incdir+$(AXI_VIP)/hdl

VHDL_SOURCES= \
$(ROOT)/src/tasks/task_8/task_8_dual_port_ram.vhd \
$(ROOT)/src/tasks/task_8/task_8_black_box.vhd \
$(MB_IP)/microblaze_system_microblaze_0_0/sim/microblaze_system_microblaze_0_0.vhd \
$(MB_IP)/microblaze_system_dlmb_v10_0/sim/microblaze_system_dlmb_v10_0.vhd \
$(MB_IP)/microblaze_system_ilmb_v10_0/sim/microblaze_system_ilmb_v10_0.vhd \
$(MB_IP)/microblaze_system_dlmb_bram_if_cntlr_0/sim/microblaze_system_dlmb_bram_if_cntlr_0.vhd \
$(MB_IP)/microblaze_system_ilmb_bram_if_cntlr_0/sim/microblaze_system_ilmb_bram_if_cntlr_0.vhd \
$(MB_IP)/microblaze_system_rst_Clk_100M_0/sim/microblaze_system_rst_Clk_100M_0.vhd \
$(MB_IP)/microblaze_system_axi_dma_int_0/sim/microblaze_system_axi_dma_int_0.vhd \
$(MB_IP)/microblaze_system_axi_bram_ctrl_0_0/sim/microblaze_system_axi_bram_ctrl_0_0.vhd \
$(MB_SC)/ip_1/sim/bd_9975_psr_aclk_0.vhd \
$(MB_IP)/microblaze_system_axi_dma_ext_0/sim/microblaze_system_axi_dma_ext_0.vhd

VHDL_SOURCES_tb_top= \
$(ROOT)/src/pl_controller.vhd \
$(BD_IP)/design_1_axi_bram_ctrl_0_0/sim/design_1_axi_bram_ctrl_0_0.vhd \
$(BD_IP)/design_1_rst_clk_wiz_0_100M_0/sim/design_1_rst_clk_wiz_0_100M_0.vhd \
$(BD_SC)/ip_1/sim/bd_88fd_psr_aclk_0.vhd

VHDL_SOURCES_tb_lite=

VLOG_SOURCES= \
$(MB_IP)/microblaze_system_lmb_bram_0/sim/microblaze_system_lmb_bram_0.v \
$(MB_IP)/microblaze_system_task_8_black_box_0_0/sim/microblaze_system_task_8_black_box_0_0.v \
$(MB_IP)/microblaze_system_axi_bram_ctrl_0_bram_0/sim/microblaze_system_axi_bram_ctrl_0_bram_0.v \
$(MB_SC)/ip_2/sim/bd_9975_arsw_0.sv \
$(MB_SC)/ip_3/sim/bd_9975_rsw_0.sv \
$(MB_SC)/ip_4/sim/bd_9975_awsw_0.sv \
$(MB_SC)/ip_5/sim/bd_9975_wsw_0.sv \
$(MB_SC)/ip_6/sim/bd_9975_bsw_0.sv \
$(MB_SC)/ip_7/sim/bd_9975_s00mmu_0.sv \
$(MB_SC)/ip_8/sim/bd_9975_s00tr_0.sv \
$(MB_SC)/ip_9/sim/bd_9975_s00sic_0.sv \
$(MB_SC)/ip_10/sim/bd_9975_s00a2s_0.sv \
$(MB_SC)/ip_11/sim/bd_9975_sarn_0.sv \
$(MB_SC)/ip_12/sim/bd_9975_srn_0.sv \
$(MB_SC)/ip_13/sim/bd_9975_sawn_0.sv \
$(MB_SC)/ip_14/sim/bd_9975_swn_0.sv \
$(MB_SC)/ip_15/sim/bd_9975_sbn_0.sv \
$(MB_SC)/ip_16/sim/bd_9975_s01mmu_0.sv \
$(MB_SC)/ip_17/sim/bd_9975_s01tr_0.sv \
$(MB_SC)/ip_18/sim/bd_9975_s01sic_0.sv \
$(MB_SC)/ip_19/sim/bd_9975_s01a2s_0.sv \
$(MB_SC)/ip_20/sim/bd_9975_sarn_1.sv \
$(MB_SC)/ip_21/sim/bd_9975_srn_1.sv \
$(MB_SC)/ip_22/sim/bd_9975_s02mmu_0.sv \
$(MB_SC)/ip_23/sim/bd_9975_s02tr_0.sv \
$(MB_SC)/ip_24/sim/bd_9975_s02sic_0.sv \
$(MB_SC)/ip_25/sim/bd_9975_s02a2s_0.sv \
$(MB_SC)/ip_26/sim/bd_9975_sawn_1.sv \
$(MB_SC)/ip_27/sim/bd_9975_swn_1.sv \
$(MB_SC)/ip_28/sim/bd_9975_sbn_1.sv \
$(MB_SC)/ip_29/sim/bd_9975_s03mmu_0.sv \
$(MB_SC)/ip_30/sim/bd_9975_s03tr_0.sv \
$(MB_SC)/ip_31/sim/bd_9975_s03sic_0.sv \
$(MB_SC)/ip_32/sim/bd_9975_s03a2s_0.sv \
$(MB_SC)/ip_33/sim/bd_9975_sarn_2.sv \
$(MB_SC)/ip_34/sim/bd_9975_srn_2.sv \
$(MB_SC)/ip_35/sim/bd_9975_s04mmu_0.sv \
$(MB_SC)/ip_36/sim/bd_9975_s04tr_0.sv \
$(MB_SC)/ip_37/sim/bd_9975_s04sic_0.sv \
$(MB_SC)/ip_38/sim/bd_9975_s04a2s_0.sv \
$(MB_SC)/ip_39/sim/bd_9975_sawn_2.sv \
$(MB_SC)/ip_40/sim/bd_9975_swn_2.sv \
$(MB_SC)/ip_41/sim/bd_9975_sbn_2.sv \
$(MB_SC)/ip_42/sim/bd_9975_m00s2a_0.sv \
$(MB_SC)/ip_43/sim/bd_9975_m00arn_0.sv \
$(MB_SC)/ip_44/sim/bd_9975_m00rn_0.sv \
$(MB_SC)/ip_45/sim/bd_9975_m00awn_0.sv \
$(MB_SC)/ip_46/sim/bd_9975_m00wn_0.sv \
$(MB_SC)/ip_47/sim/bd_9975_m00bn_0.sv \
$(MB_SC)/ip_48/sim/bd_9975_m00e_0.sv \
$(MB_SC)/ip_49/sim/bd_9975_m01s2a_0.sv \
$(MB_SC)/ip_50/sim/bd_9975_m01arn_0.sv \
$(MB_SC)/ip_51/sim/bd_9975_m01rn_0.sv \
$(MB_SC)/ip_52/sim/bd_9975_m01awn_0.sv \
$(MB_SC)/ip_53/sim/bd_9975_m01wn_0.sv \
$(MB_SC)/ip_54/sim/bd_9975_m01bn_0.sv \
$(MB_SC)/ip_55/sim/bd_9975_m01e_0.sv \
$(MB_SC)/ip_56/sim/bd_9975_m02s2a_0.sv \
$(MB_SC)/ip_57/sim/bd_9975_m02arn_0.sv \
$(MB_SC)/ip_58/sim/bd_9975_m02rn_0.sv \
$(MB_SC)/ip_59/sim/bd_9975_m02awn_0.sv \
$(MB_SC)/ip_60/sim/bd_9975_m02wn_0.sv \
$(MB_SC)/ip_61/sim/bd_9975_m02bn_0.sv \
$(MB_SC)/ip_62/sim/bd_9975_m02e_0.sv \
$(MB_IP)/microblaze_system_smartconnect_0_0/bd_0/sim/bd_9975.v \
$(MB_IP)/microblaze_system_smartconnect_0_0/sim/microblaze_system_smartconnect_0_0.sv \
$(MB_IP)/microblaze_system_input_fifo_0/sim/microblaze_system_input_fifo_0.v \
$(VIVADO_PRJ)/hackathon.ip_user_files/bd/microblaze_system/sim/microblaze_system.v \
$(ROOT)/src/axi_mm_master.v \
$(ROOT)/src/tasks/task_8/microblaze_system/hdl/microblaze_system_wrapper.v \
$(ROOT)/src/axis_backpressure_gen.sv \
$(ROOT)/src/axis_data_width_converter.sv \
$(ROOT)/src/bytes_counter.sv \
$(ROOT)/src/control.sv \
$(ROOT)/src/sync_fifo.sv \
$(ROOT)/src/tasks/task_10/task_10.sv \
$(ROOT)/src/task_wrappers/task_10_wrapper.sv \
$(ROOT)/src/tasks/task_11/task_11.sv \
$(ROOT)/src/task_wrappers/task_11_wrapper.sv \
$(ROOT)/src/tasks/task_12/task_12.sv \
$(ROOT)/src/task_wrappers/task_12_wrapper.sv \
$(ROOT)/src/tasks/task_13/task_13.sv \
$(ROOT)/src/task_wrappers/task_13_wrapper.sv \
$(ROOT)/src/tasks/task_14/task_14.sv \
$(ROOT)/src/task_wrappers/task_14_wrapper.sv \
$(ROOT)/src/tasks/task_15/task_15.sv \
$(ROOT)/src/task_wrappers/task_15_wrapper.sv \
$(ROOT)/src/tasks/task_16/task_16.sv \
$(ROOT)/src/task_wrappers/task_16_wrapper.sv \
$(ROOT)/src/tasks/task_1/task_1.sv \
$(ROOT)/src/task_wrappers/task_1_wrapper.sv \
$(ROOT)/src/tasks/task_2/task_2.sv \
$(ROOT)/src/task_wrappers/task_2_wrapper.sv \
$(ROOT)/src/tasks/task_3/task_3.sv \
$(ROOT)/src/task_wrappers/task_3_wrapper.sv \
$(ROOT)/src/tasks/task_5/task_5.sv \
$(ROOT)/src/task_wrappers/task_5_wrapper.sv \
$(ROOT)/src/tasks/task_7/task_7.sv \
$(ROOT)/src/task_wrappers/task_7_wrapper.sv \
$(ROOT)/src/tasks/task_8/task_8.sv \
$(ROOT)/src/task_wrappers/task_8_wrapper.sv \
$(ROOT)/src/tasks/task_9/task_9.sv \
$(ROOT)/src/task_wrappers/task_9_wrapper.sv \
$(ROOT)/src/task_deserializer.sv \
$(ROOT)/src/task_in.sv \
$(ROOT)/src/task_in_mask.sv \
$(ROOT)/src/task_latency_meas.sv \
$(ROOT)/src/task_manager.sv \
$(ROOT)/src/task_out.sv \
$(ROOT)/src/task_serializer.sv \
$(ROOT)/src/control_wrapper.v

VLOG_SOURCES_tb_top= \
$(ROOT)/src/control_regs_S_AXI.v \
$(ROOT)/src/reset_delay.v \
$(ROOT)/src/control_regs.v \
$(BD_IP)/design_1_zynq_ultra_ps_e_0_0/sim/design_1_zynq_ultra_ps_e_0_0_vip_wrapper.v \
$(BD_IP)/design_1_clk_wiz_0_0/design_1_clk_wiz_0_0_clk_wiz.v \
$(BD_IP)/design_1_clk_wiz_0_0/design_1_clk_wiz_0_0.v \
$(BD_IP)/design_1_blk_mem_gen_0_0/sim/design_1_blk_mem_gen_0_0.v \
$(BD_IP)/design_1_pl_controller_0_0/sim/design_1_pl_controller_0_0.v \
$(BD_IP)/design_1_control_wrapper_0_0/sim/design_1_control_wrapper_0_0.v \
$(BD_IP)/design_1_xlconstant_0_0/sim/design_1_xlconstant_0_0.v \
$(BD_IP)/design_1_control_regs_0_0/sim/design_1_control_regs_0_0.v \
$(BD_SC)/ip_2/sim/bd_88fd_arinsw_0.sv \
$(BD_SC)/ip_3/sim/bd_88fd_rinsw_0.sv \
$(BD_SC)/ip_4/sim/bd_88fd_awinsw_0.sv \
$(BD_SC)/ip_5/sim/bd_88fd_winsw_0.sv \
$(BD_SC)/ip_6/sim/bd_88fd_binsw_0.sv \
$(BD_SC)/ip_7/sim/bd_88fd_aroutsw_0.sv \
$(BD_SC)/ip_8/sim/bd_88fd_routsw_0.sv \
$(BD_SC)/ip_9/sim/bd_88fd_awoutsw_0.sv \
$(BD_SC)/ip_10/sim/bd_88fd_woutsw_0.sv \
$(BD_SC)/ip_11/sim/bd_88fd_boutsw_0.sv \
$(BD_SC)/ip_12/sim/bd_88fd_arni_0.sv \
$(BD_SC)/ip_13/sim/bd_88fd_rni_0.sv \
$(BD_SC)/ip_14/sim/bd_88fd_awni_0.sv \
$(BD_SC)/ip_15/sim/bd_88fd_wni_0.sv \
$(BD_SC)/ip_16/sim/bd_88fd_bni_0.sv \
$(BD_SC)/ip_17/sim/bd_88fd_s00mmu_0.sv \
$(BD_SC)/ip_18/sim/bd_88fd_s00tr_0.sv \
$(BD_SC)/ip_19/sim/bd_88fd_s00sic_0.sv \
$(BD_SC)/ip_20/sim/bd_88fd_s00a2s_0.sv \
$(BD_SC)/ip_21/sim/bd_88fd_sarn_0.sv \
$(BD_SC)/ip_22/sim/bd_88fd_srn_0.sv \
$(BD_SC)/ip_23/sim/bd_88fd_sawn_0.sv \
$(BD_SC)/ip_24/sim/bd_88fd_swn_0.sv \
$(BD_SC)/ip_25/sim/bd_88fd_sbn_0.sv \
$(BD_SC)/ip_26/sim/bd_88fd_s01mmu_0.sv \
$(BD_SC)/ip_27/sim/bd_88fd_s01tr_0.sv \
$(BD_SC)/ip_28/sim/bd_88fd_s01sic_0.sv \
$(BD_SC)/ip_29/sim/bd_88fd_s01a2s_0.sv \
$(BD_SC)/ip_30/sim/bd_88fd_sarn_1.sv \
$(BD_SC)/ip_31/sim/bd_88fd_srn_1.sv \
$(BD_SC)/ip_32/sim/bd_88fd_sawn_1.sv \
$(BD_SC)/ip_33/sim/bd_88fd_swn_1.sv \
$(BD_SC)/ip_34/sim/bd_88fd_sbn_1.sv \
$(BD_SC)/ip_35/sim/bd_88fd_m00s2a_0.sv \
$(BD_SC)/ip_36/sim/bd_88fd_m00arn_0.sv \
$(BD_SC)/ip_37/sim/bd_88fd_m00rn_0.sv \
$(BD_SC)/ip_38/sim/bd_88fd_m00awn_0.sv \
$(BD_SC)/ip_39/sim/bd_88fd_m00wn_0.sv \
$(BD_SC)/ip_40/sim/bd_88fd_m00bn_0.sv \
$(BD_SC)/ip_41/sim/bd_88fd_m00e_0.sv \
$(BD_SC)/ip_42/sim/bd_88fd_m01s2a_0.sv \
$(BD_SC)/ip_43/sim/bd_88fd_m01arn_0.sv \
$(BD_SC)/ip_44/sim/bd_88fd_m01rn_0.sv \
$(BD_SC)/ip_45/sim/bd_88fd_m01awn_0.sv \
$(BD_SC)/ip_46/sim/bd_88fd_m01wn_0.sv \
$(BD_SC)/ip_47/sim/bd_88fd_m01bn_0.sv \
$(BD_SC)/ip_48/sim/bd_88fd_m01e_0.sv \
$(BD_IP)/design_1_smartconnect_1_0/bd_0/sim/bd_88fd.v \
$(BD_IP)/design_1_smartconnect_1_0/sim/design_1_smartconnect_1_0.sv \
$(VIVADO_PRJ)/hackathon.gen/sources_1/bd/design_1/sim/design_1.v \
$(ROOT)/src/design_1_wrapper.v \
$(ROOT)/tb/tb_top.sv

VLOG_SOURCES_tb_lite= \
$(AXI_VIP)/sim/axi_vip_0_pkg.sv \
$(AXI_VIP)/sim/axi_vip_0.sv \
$(ROOT)/tb/control_wrapper_tb.sv \
$(ROOT)/tb/tb_lite.sv

GLBL=$(XILINX_DATA)/verilog/src/glbl.v

COMPILATION_BASE=$(INCDIRS) $(INCDIRS_$(TB)) \
$(VHDL_SOURCES) $(VHDL_SOURCES_$(TB)) \
$(VLOG_SOURCES) $(VLOG_SOURCES_$(TB)) $(GLBL)

###
help:
	@echo "Available commands"
	@echo "make batch    - compile, optimize and simulate in terminal"
	@echo "make gui      - run simulation in Visualizer gui"
	@echo "make compile  - just compilation"
	@echo "make optimize - just optimize"
	@echo "make simulate - just simulate"
	@echo "make clean    - remove qrun output"
	@echo ""
	@echo "Testbench selection (default: tb_lite):"
	@echo "make <target> TB=tb_lite - control_wrapper with AXI VIP memory model"
	@echo "make <target> TB=tb_top  - full design_1 block design with Zynq PS VIP"

batch: compile optimize simulate
gui: simulate_gui

compile:
	$(QRUN) -compile -top $(TB) -top glbl $(SWITCHES) $(LIBS) $(COMPILATION_BASE)
optimize:
	$(QRUN) -optimize -top $(TB) -top glbl $(SWITCHES) $(LIBS) $(COMPILATION_BASE)
simulate: ip_mem
	$(QRUN) -simulate -top $(TB) -top glbl $(SWITCHES) $(LIBS) $(COMPILATION_BASE)

### THIS TARGET HERE WILL RUN GUI MODE FOR SIMULATION
simulate_gui: ip_mem
	$(QRUN) -visualizer -gui=interactive -debug,livesim -top $(TB) -top glbl $(SWITCHES) $(LIBS) $(COMPILATION_BASE)

### BRAM init files are generated by Vivado into the XSim directory
ip_mem:
	cp $(addprefix $(XSIM_DIR)/,$(IP_MEM_FILES) $(IP_MEM_FILES_$(TB))) .

clean:
	rm -rf qrun.out qrun.log

.PHONY: help batch gui compile optimize simulate simulate_gui ip_mem clean
