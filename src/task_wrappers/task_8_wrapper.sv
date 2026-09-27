module task_8_wrapper #(
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
JHsH6nO8ltTFV41HoRzlF/PGAnbeOTSfdu/0f5CU6vzlZZu/D+v4S0osvF2RM083
b6v6bDIxhH0/DncsarSwUqTx088oTZTV06hkQgb4Jpz8xnFYy3TaqdXxQm3JRjpo
uiqH82d8RW8wvcbnNwNeyUp3+GI3MZukKS3+ZbDfPo0SusYpRlpeR0mkingRTrUL
pNhVIw9Z3sUDY6hUH0JrQFO7RiJF8p2EDtViwAK0688zPHmcXbK5K1XkIc1uqSmE
jOtxKFFNKG4DUq/HiUIoeZ1P+48EwGA702QzDO8/bpFuLPH0bLQ37GETUCP6wE1z
dQWZPlsaa0vWXqyaKt5F+A==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
l1x6hCyCmRRFJtrHLnPZYVfAKp2NonYS6eu2Ga2knw5VNqji0n4nXEMLvabM8EV0
RH+GE1Gq7hYVcqgg2etwLXKUgyvCgRWImsHnEjydoK216XFyT8qjh7DDATVNuReA
a3jwmZ1OfOgoW/pG2EfUMjgoXlihXmaW4Ejv8pxJsp7Qc6Tn2lHWdrl997DjLy2W
mOXG4O/ZZl+Izm6tjMOigj+PRI1UvKi/+g+mFaNsIFMApNmewYTY3FgV1ExF109J
lpau/6fQWoi0EtQtklKqklD8jyTqcjw9RxVzhVv98Pbaqz21DRtQYxv8sY6XdERy
j4TsVNBSpIF9znscy8vf6w==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
UfDSu/9o14KzMRBdZa9c+lB/M+y5R+uIe9yZQj6u4rg7/2Idw2BuLRKg84ZY9lW5
vW30tAoxbv2yxI2802s8LPw7+A8a9PcpdBWalxsI1+r2t72/n1qoVaYwg7OYb2Mu
v9dxe7VsaKV4VTd8Fzg2SRrEMmZ/Iy5oIzU8N5ssRDk=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_8 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_8 (
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
M6R0CYO+VO3niUrElQRqF5YMqNgoKyr5aHTgt95mb3YGAR0FHiKgVeJbNlZfx1aC
jlcsHi/ewNpa43gACqfHpwfDOwCvQWatv4UQLEuTv5UIq2bnjzorBzsGU6UUXEd0
cNxjp+YClZQ/WY3c6bY8UG9qetbZrStiJbtb1/ndCc+jn11CatozWXyKi4DvhzUR
THsRyxwNI5wlZHLfRuWjGtO/egZMVTdUmk99sHnH0QVtBGE/JsvLYuClsBUhR+rV
tqwR2o+eQSXcVvOw7TXX5MV6CnrUAtb0G2HUoAAvyi5W+rqHaHR2SxAo/jJ7y5ni
fvN5YHn/z23Q/5C4PX2N4A==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
a2SRNkIRdkMapPORtgC989QtthvfCf7YAnpl/PKD+fuMWw/xUc8utr2ylGAID9GW
cyqmpMrOp2x0bDcCWQQqjw/LFFHXZapAU1ByLOcom8Ad61QPRnzd7odyaVhEormN
cgc/0+4azLPIMoOPOPcN80Tno86ComfbVeTKws+nmQetSe2VPcMPRaZXuSGbg96b
dhQCmdPIzVYRoPc3m5ZpxUU9q4j+j7gQZ4SBci91q8J7vrBU23hMnqvInaUqWjrF
JEACGERadkYvPzh9n5B9e4GZZOZ0y15cADJDzg0g9eEYX/W7t1iZxpgJuMzVNwZF
rXsE8Nh7LrLfBwqOw2nDKQ==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
TXDnvxEWV4W4Y/IXph0tpvlX3j8JpRErIDDw+lnNx8UWa9IGdn0fnLtYtnGK3thg
BSO58Pb17A+bbrSVFmoKjzw/M9kcDaxwWYKTggGyhtTXNMHHpndIZN8C82MOsM3E
0AksdKqGyPQpFnkyUzrYLhr1A/kYc6aSNvBdC7Htuuo=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
