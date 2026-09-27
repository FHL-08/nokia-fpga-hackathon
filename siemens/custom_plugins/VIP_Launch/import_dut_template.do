VIP_import  {% for top in TOP_UNITS%} {{top.FILE_URI}} {% endfor %}
#VIP_create VIP_instance options
VIP_create VIP_instance AVERY_AXI/amba/axi_stream /top/aaxi4_stream_master_0 aaxi4_stream_master
VIP_create VIP_instance AVERY_AXI/amba/axi_stream /top/aaxi4_stream_slave_0 aaxi4_stream_slave

VIP_change port connection /top/aaxi4_stream_master_0/TVALID fir_filter_bank_top_s_valid
VIP_change port connection /top/aaxi4_stream_master_0/TDATA fir_filter_bank_top_s_data
VIP_change port connection /top/fir_filter_bank_top/clk default_clk_gen_CLK
VIP_change port connection /top/fir_filter_bank_top/rst_n default_reset_gen_RESET
VIP_change instance /top/aaxi4_stream_master_0 agent
VIP_change port connection /top/fir_filter_bank_top/m_ready fir_filter_bank_top_m_ready
VIP_change port connection /top/fir_filter_bank_top/m_ready fir_filter_bank_top_m_ready
VIP_change port connection /top/aaxi4_stream_slave_0/TVALID fir_filter_bank_top_m_data
VIP_change port connection /top/aaxi4_stream_slave_0/TVALID
VIP_change port connection /top/aaxi4_stream_slave_0/TDATA fir_filter_bank_top_m_data
VIP_change port connection /top/aaxi4_stream_slave_0/TVALID fir_filter_bank_top_m_valid
VIP_change port connection /top/aaxi4_stream_slave_0/TLAST fir_filter_bank_top_m_last
VIP_change port connection /top/aaxi4_stream_slave_0/TLAST
VIP_change port connection /top/aaxi4_stream_slave_0/TLAST fir_filter_bank_top_m_last
VIP_change port connection /top/aaxi4_stream_master_0/TREADY fir_filter_bank_top_s_ready

VIP_change port connection /top/aaxi4_stream_slave_0/TREADY fir_filter_bank_top_m_ready

VIP_change variable /top/aaxi4_stream_slave_0 {enable_tkeep} 0
VIP_change variable /top/aaxi4_stream_slave_0 {enable_tstrb} 0
VIP_change variable /top/aaxi4_stream_slave_0 {enable_tuser} 0
VIP_change variable /top/aaxi4_stream_slave_0 {enable_tlast} 0
VIP_change variable /top/aaxi4_stream_slave_0 {tready_default} 1
VIP_change instance /top/aaxi4_stream_master_0 agent
VIP_sequence add aaxi4_stream_master_0 aaxi_stream_all_byte_seq
