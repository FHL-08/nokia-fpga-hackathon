module task_13_wrapper #(
    parameter int TASK_INPUT_WIDTH = 8,
    parameter int TASK_OUTPUT_WIDTH = 8,
    parameter int INPUT_STREAMS = 8,
    parameter int OUTPUT_STREAMS = 8,
    parameter int MAX_SAMPLES_IN = 1000
) (
    input i_clk,
    input i_rst,
    input i_rst_data_width_converter,
    task_in_interface.slave tis,
    task_out_interface.slave tos,
    input tv_in_last
);


`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="VCS"
`pragma protect encrypt_agent_info="X-2025.06-SP2_Full64 Build Date Dec 01 2025 00:16:42"
`pragma protect key_keyowner="Xilinx"
`pragma protect key_keyname="xilinxt_2023_11"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
WQdv21LWwNRn0rO2TbMq1x3mytcKkbM3iGvp947/HSlwRJg8qfI7rcMMBlBmaJU9
un8vT0lJosNMEVbYndAqGLwxOkvZspgcDuMQsSRTYVpNWs82Vi8sh0V031Du8AKE
lpFuR4jDYyiCEfwKZL8NwaWGPiabYgVmg7yv6JWmXyf2k6PVa1YhPLRQhztehRkx
Gwp1nTsS0YmhY2sd8FwbesD6R4BT7nN6dqKX/G9/8FOVx5HWdUhlnMAhJitWQCrw
03skEYRWHetn5FvCK3hvw4biGUy4+f0EDhXLak1WHajCtV/NrMF7Z8XuNU/3iPt1
ovmxitkLIV0CK64Ck0R5CA==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
CwuVZsrK5DFnAUsOdI40Z26IuLnS/jlnp5JXBOD/JJb+w96GRD79RGvpTlnNxTNu
UFXSPPcse7lrYiLfpcIVHmY+F4wFkhe5sXDeijKLJAujK4ysWbhZ4tfIkLdgy1On
Yd/tWVapnpP3CB2//GrZXYbSDeurlvJNXOP/gxi66L2jdW7x0kyq9tryXcYZpTLH
YDlouShR9EW27og1j/nOWqwDW7jmWQ7vaK8gcRo6dCE2iIEDKdUVLoV8NRzc4A8r
NClLcN6OaDuthE1UfhRVRrQsprFz5LfJXI4HguA4gA/7slzZ0rxPdRV9R33228bl
jkQ52QkIrT4lD8IGxHfYGw==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
NdRBC2dXM+kufXgjTb2OVpocoBNlRRtuag3cmNmjw+cSDw0haJr7G10tdbLonsxO
iZz/XUTMBiiKYKyicXZZuMuxV0iaJiMc3R7nBVFnpgwUHPX7ZhnajXLh4YJGA7g5
uDKjIcxfXYASCT/W5dUfKFltGEDre6R6Z/Y1UTcdxo8=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_13 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_13 (
    .i_clk  (i_clk),
    .i_rst  (i_rst),
    .i_first(w_task_input_first),
    .i_last (w_task_input_last),
    .i_data (w_task_input_data[0]),
    .i_valid(w_task_input_valid),
    .o_data (w_task_output_data[0]),
    .o_valid(w_task_output_valid),
    .o_last (w_task_output_last)
  );


`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="VCS"
`pragma protect encrypt_agent_info="X-2025.06-SP2_Full64 Build Date Dec 01 2025 00:16:42"
`pragma protect key_keyowner="Xilinx"
`pragma protect key_keyname="xilinxt_2023_11"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
LXPtnqOIDEFX5FnGSNSlz6vvZW8WAnjdqvquqfKFU/nqAlFJxns+nOIg2RwVZs6a
IMWVuVgB38+/5Uam4xACsgGED/UfT1fdLyQMQ8s6DiUyh4lb+GbRV9JjCXyZxQdQ
EbX/7DxHwYyQEl8KWca/OyEB1YWstTVFRvFt/PDZv/fAks675Zsx0MixmQlW4cEC
WbD5ogTl8GAi0yEU4t1fx9odHIxOT57pVcuFnMat8l6W6oI6W+YR0U9vgvOAgGbt
+8mNJRdzv1ojIR611amF8D7rEHAIOK52HK+2RkQK/j4KAp4vn7yOq4FYn+F6VMcW
a0zI/Sk8eFLM84mwrkY6MQ==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
TxcchvMNQAEVxCvZV5Nc1LkE98kcaUXnNiTdKGTPJPurxy3fPrqyeKM6Mf++P5y1
ozmOMsR6K6W9nOWAhU5kXrXxcFGPREGAPHFJ6zFaEQPzraM+eliT1pkxMeaGJExd
DQIyUdsM6ykrKYT4UrNUqwskzRlErBHleC+a7APFEl3rbu5g2mM6oTACJEzJfJmm
Y0OK80cp5MaDJMAaT7wzBpe3EJNsPk4mFdyRHb3Or49ZerSE/Z5n3KYxRo1CUmT2
u4TK3XZzJQfIPJz50uN0U5mpyV/9veFc0EsBv+ynInkjpyn/xnRe1eSisAvZiXei
A8QLnBt4+ifcmEQdKTSxLw==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
K9n2jTtOlBK+S4WjM9IgiBOVtLyHP3c+3CyluzumTF2QsUIW2rgR+naRQbG6x8UG
MHAaeBDXV7yyMSRtTnFdUY6BN4hRAi/S4bnyKovoyAErRUu3GK5it99Ympl5csx4
M7I0039WTtUEAwFTisKVgVn2IJsEzQ5Teo70k750uC4=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
