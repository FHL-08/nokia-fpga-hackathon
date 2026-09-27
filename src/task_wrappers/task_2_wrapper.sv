module task_2_wrapper #(
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
ZR17r/U7a3uW4gmeV9GXHZ1rYab+b5uXOPZ3r6FFCfYMuMMRYD/YbwmwQ8stPbYl
9oKdbvtNiqpoWflRLU9Uz7X8puZffLonPKZ4ppeNwfbQS/+q3f+7Y7A2IBslcNzb
BuDzXE8rjbVnPQT8+zhSFlpF2KA1Ydom762rBHA8GCz3walfI86Vxu7q1gh/OzKC
QMukjiHbwpPnfQcvmrlrUrU6r1IjnhGpveoGTSoyPw/FTM1z01VrY6VNJm9H8JgD
rBgLKO6793B1s1gurErdi8QQbT10US+BvJ4glNPtU30Kvk7+7u/HgdGx4KbOrUtN
SHenaslL1UBPaTYgkKTrvg==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
y9JtrLMYTmsJ3eLOhenBHKfreEjndfZ2Z++XUS5i16GIq/KyQeL39HgNZwZsuFmq
sTwkQaBjs762MSSR47YrOhqgceRhTNEQOrX+ARzk1tueTui1Yo1UoNZCp6XvDUa7
2MaAXPOS+B9c5sJwpamuLoS+06FMh6YKH2zAAWFSzahSB5z52s1+T6p18eXKlEAH
HQmZ+k4VLbIYTfW+vdwiE8NigFeRPlZCDWBvE6V0xp274cDKMnzMHb3GunmXMTHD
o9to2Tot3p7l5Ox2Pf2bbzv3EfvuvQ9mTZXbtAj+KDISZWAgLU1SJLzvMF5I/Fu9
Lqi/kzBCoTwr53yMmxvbcw==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
h7/84GqyynVLhsUq05uHO++c5ThAuyuAycE8wa1lIhxBrIhceXW/6J1ETasgM6IA
GGQ2FhEFKlHySvzpQfASd/5QsGyumGqkYzypCuU6YDR5DgQWMVlatOF/Nt+n8T8z
bHPJq4BK7bcPEXH/F4FQziYgmKNzQ9mi7qIki5KBc7o=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_2 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_2 (
    .i_clk  (i_clk),
    .i_rst  (i_rst),
    .i_first(w_task_input_first),
    .i_last (w_task_input_last),
    .i_data0 (w_task_input_data[0]),
    .i_data1 (w_task_input_data[1]),
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
Ys8iAkAdJ1yY+Uh5i5fSYTG6b7RXH7qTeuhsq8Hbzu9clMdC193tNrO7XKXH9FlQ
h/jTgYJOonLyakTCJTUlspb3ZH09b02fAfJnezrSA60t7ppY8uufxDmV1m0Oi6uc
DOJJQfkx4lNQEuhOoujltrz+aUQuaDl2iHbde8APUyovAmdCS5ImpTEo/zJbNWEN
sCy26RQdDq6vsTL3czJZWab4WKUwAU+v9rvRZYJBoHuqZ2i55KnIcJOyCR2ipG57
YY42WU/uszrfrDZtJS/K2AyX3zHsl19TwUmcHaMk7nmqlhepIZ1FbBSSAMYfVg0X
X8LJHkLlqiNoCi4Q6AYpBA==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
bAvSol+jWRD5sH+N7rfbeGLI2MGNdoBGM0aTtbuC0QqDb3CWnkeBJGcXChKdPVbH
tuUFSiexH8G6PxA2n+Dqkf9w6ee02b8WC2Gu0m1lbmwXvGce6EUq5hFcwjx0p4Cv
dHP+iMWAn+JBeSaUMrFO/Ru4TIIAzyfy9aTCl4T3Ue+dA62OOCkCq/WK4NR3AH7b
rwOMr/ox8ADOobFCxhl7M/xloAvUJPmcbxCxoTRziaUp9xxVBTtEvMigoeieLu1P
NBK6x5yq0Q4L+8EqGzypAZaE4lY1PdIz9gd1EUhsFoFZgAZs7dU/PNeyU7PcUP0Q
UdDZYO6oGKuLpfgcx7/deA==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
AQVhi9lc/ML8oF9wrYtt1McJzcuD30jIfs5eemnlfHtmuCp/mTFD75YprJd8uk0I
apEnVBj1qyMu/nRwjk9XyBr8/eV9+MCE/tPfnP7LGBcGt9v/X0G3T/eTjIrqhUDD
oTyGsShyl+3P9HrMpiigf93Gw5TQ2N0mIkTAzz0xols=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
