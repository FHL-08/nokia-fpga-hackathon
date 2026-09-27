module task_3_wrapper #(
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
s23CcgqXPR9fN59lYXjx/8mVtuN2ShHEyqILydYK9qs+xcm2s5Ai51EvFDpHNklR
i3ZDmEZPcUx8mcscTaFicdu2jmFbmRYEEFP0QZndyykfciF9dTnot4XCrgZ46MsI
QiPFKSPl66DiaFCNrb0pm/6KTIBYdbfzjXrZONddP8pKnxHzex5Jn/MEnESHMtTr
mehyG+iVnA8ESQQz/+lZXRVcamgwk9011+i+tRvdEpdsUE7F7jlrCabDYqZ7d20Y
Rx+0AV+xJriDX2snf8kNA/qKiSgeeTwHxAI1Bjuem19Ku543mnL1SvS5OuDvyD+6
dlG/Bkd/VsepWu/r//ez2g==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
XZY9lTvKZH+b8zu+mLEGE6+P7h99jzk8GOCZnH70NqchwLjaiiMklIpcKMzn9+wF
9RpIEN0Cr1Znxhw3E+/PCutl6VobirHWxp9V94wFrRqcFckRStHZfZ1NwEkIhvxV
53QHV78XkBRFNNkUOqgGhHQNe1IxD7Albm+akrTmv7UnQhPfuApwIag9JLd+ptSW
ihGUu3xjIN5kls9o8OceZESxV+zChZQVRkpzxPeO952yUurgThdC5nG9Ms7OgypA
P519RWIKoj0kB6xhTqHbGSlGXLg5TfUDOGtKGV0fozYpTA7CYAoay9hq9rjbgXZI
MVnlhpvk6VaHzBzauEzhYw==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
ellk3r3EcQckvDdaHxEXasqRwz3D4iO3Nerpreo0nu1E+MHT3ds0tgMxOwPXXWZN
MIx8ajUmFsqJ9+vRGxKVFB3ZxirUq1x7RZ9NOZESlqmwAHhZ8Fq+mUz6Cu4wbWB/
UHqHn2brXq2dqTHN50CqqCda9Xs2QdhBRfWbqTk8bWI=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_3 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_3 (
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
msNE/rsTv0dz8NiX+ct+2ciHZ5dDnkXKYeSf+WebLzMnNRCgbtvCY9Xnn460gtIk
JT/ZVr8cE4c+2c52smgbM7FZm3g0it6Q7hE2hjnx79fk6TV6rAnHOPT5+yj5QwIf
T7S0Ym9gALxlXU0PB1XiglMrUOG89QurR85fAi0/L8ssIhWt2bnd/AyoEDU8heNU
WtSlDgtUK5p5YweUniCQfnEhnV132iitu7x21FEH9H0WhpWVjZN6OYPxTVm9A8Jn
CJZFwV2n7NNoR6UoP76rmTF4gc46PYAH312XnSNenNY6KfKUFpJrwrzYSrU8faFt
5pIksUg9I2IrdMWEs1nqPA==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
SbeA/u5vUHvGuO++ze9M9KX+R+flRPmTP9JWmvCD1fveqTsrHMzaLp5tabkj/+Ge
MoASgl3boV4sAP+PG/VKn1uPSeVubIpNUl+FPFMMTZVfv8dyDjN7U8nUKjEiRQWF
2pavRepYwxOW7o0Jkb/nHDwMlvQUmAIkTitA87Km1WvtJnQGGpQ1rNIG2Tx6PVa/
pUraQV7AdqMtc/g1iBtM2vseoOoYWDE8go2FhZSMzyMwJU4vws9D5Qg0QFrMpb1Z
Wvw7AIwCkTIzhhCrRrjLF3XB9q8nnR5DKtRzCKFe/F2Ld6ShTQL/6xOUHBpb/QlG
ESkRHwRu0/qVUJUCHrStAA==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
Ga1qyhpnKnFTFcJ5FZ2tRvldyIJvaE/yS151UAjAE8QS3AGGC1GHUz1MV3g6VAd/
vagGVX5J1460OZc1is8t3Qj1gAD1MttQP3bG1E7zp5Yx7OrFvTpFUn/0nUZR4xyX
H1vbwa7uxoj844n9+IjdjF4+P/78l/gqdJKuE/nNH9Q=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
