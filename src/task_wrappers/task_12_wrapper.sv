module task_12_wrapper #(
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
KjUsZuxQz3ULfpVtOOVhNHZ/ex/p/FrG8bvEpcVUDvL7CXh9d5KxE8iQHiMSa6Er
WyAN9JTLhZR8ShbD/A3TRoyZRAisfy4tnvyIPtEjd6NaU1ZB75f+96SqCA9hczF8
YJKgMOi9fYJpoCC0M06PA28TZSEc1Vj121AVoNnP649H5ecIUG7Y3P1JIk6ZaeKJ
BP/z2FZeDOWX7+Ld1t9yqgYCUSvMM6Wv/xPtdsIo8GLNdX3FZrWU9HNR8vlwdtkk
iyzlUa2O3on/bucXgpeILWtC0OsiPduOWpxhWYt/QLF8nUvbaY1+qkNRIx4E4lxw
D54wRmKwdNlGd6Mm/10YqQ==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
mXx8Ioos8LjketJ29xJC7K8nN9u6e+f4/LpBSvDcSwmyJPzhaH1yN8dLau0i8A/D
wTPCW8ZmG56LoQtnYsHSSXxF9/E1y8XFib/IfiXI3J2sY81oDvweOCuyTI+Yhef1
VX9DuuvJo9qOsmwlk9Fq/sR7Z6THQZRugXMk6gQrtU9P8TzppQceckiU8Yv+768E
2KPM1hD19joN4N+gABm5WEzaXtUt40c1YKxaB5OE+rjPuf+GLvEvRcfpWop/Ji6R
/NlvBdoOwdIKtSO6bvAlpni+ohUCUShvUX7vvT13L6jLeaeKOdTx1ngY7UvWqm4e
G3u+7Ba6qo4WOA4YBjphTQ==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
bYugfZ3ywDeRKpVefeVKef3FZyVXolXVhIWfDzV5Myajims4heVZCJ6yZsssdfAC
cboKgafsZ9yZtDlKor4e4uvMaGN6dDUz/Q010eqwvR5tTLxlTzcrX29N3935cBfh
gzsaVsveMI0Ud64DJItsOkB2vx/mdPHuPkX+O0kyak4=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_12 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_12 (
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
FMy+FQOfsEJvfQ32Ial3OWHoMcKrfYImbv8KU0T28kQ0PchaCYfK0jw8z4szSAX5
aRTqtJ7a/YzmhlGsGo8lbm5g9l9bkcrdR/yrP/+u6mNxi5epMX2d8SIif2ECnHVP
azCHCNShUcV1Rtxex40iwZ7rPEGV1K+ySQXgW/pUDN98MXhJM95fW2O+ce4qhErK
iBWwEgVo2XG+BkZbftd32uELRCidRAspibjS5Blb+pe2S17Ke5MfQP7HVJy19ZpO
1BjEadjfXwLcaxOrzqiTP+JGllTOveT4gVQOnUor4bcVWLh68lwgHbXCG7S0Fs4a
wr9gFCkP6HTsbRwYR+iyrg==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
iJSYPNsv/oaZZIoxDejgArdB/kFDNtBG/PUNdhQyfAtB2r+2BB4gbcD0SGXebJJ+
VV7K2Gy1FRqj2b2GR/KkDVw16/ifqrwk9YGLV64XI51+kwAx74x4PEkNOuy6LieE
tQIWLen5PVb1jVtuCQcqqHZ1p84BiyMgQia9+Xw07a5GPFVGlnpzT5QydTJ/kqSo
g9B4lmFMlYCmVSA0OLSX6ecIkZ+kl2WF2wt0R8HXvLssL8YlQntJ4V2XyVlBRIUr
od3P3woXeJlwNiwfMU5mm1ARI8N341oMSXsUTrdhbqhmXvPnk/D4cS5MGJcC8Oqu
flSyl4HCSOTADucNDXRXlA==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
Zv9FNzoph5MGxVmmMFJlHQvoBVj44Rqi1m3DTZhpUZ8Ex+45PgGmrcAZaoRLMbX7
Fobwsa+NUfS2GXCOAZWej9nErNNFxqJnmNaFzQbmYyo6XtJ6hAZ/r3He0oH6dsl8
xOdbD7cu6ZPq8HSNUI1KWqmKltzgG3HsCyoZNp8Q0g8=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
