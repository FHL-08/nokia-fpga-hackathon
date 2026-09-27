module task_1_wrapper #(
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
ST3hV0i+di8dEyCte3aoZJSduYBQzUxJtKjA3C9o7UuEf/XCMyTdzj2TTAtOE02B
Ik5kQLaj25u5D/wD4s0dfFsqENEaKaGvQJigh2A+wP1mvdON5z8IolZzM/AM8YDs
rup+qtY6oHcahQpHHC5dDfYS3RgJk0Gj3cCdXcPZlaaBwtN2apbNeZLNz3Ds72KS
oaPIV4cxUfvV9wDfQ53yKfUOhEqrMsPBlz0oWOQ/a9m3o5LwimEuGIXNJVjHjTNa
vrS5Mx2qc340IEF4HkrW2bdbv7a0pFpk7mZrpZ6XmwvmWkI13jlgQa3QlTqKaT/7
OO8O6uLxZ2SsX2qsW7W/Tw==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
i5tr1gaqDAkRUCTlLpHlPl7cI+oH07dP9n4wqBum607hf7BqC0qZP+RXnqUV4bQu
IU4LcOhqCXzwhegY+2r7DDGNXbMw0X1iLCL4UKWiHwgxubHkfPSFFdFM7z+N2Hfp
d5DHs+At40YpYe8yvPlG+532mjXVdMSPdROmFdVDAvbjjfl50lelLKp2JpQvd5JJ
rHCW+GWp1o6ZzD2DSxWA9g6Q4Ne7d/1lrAJ++/ekwx5UnTwDl2tljZ8KnDvlzS7c
2PIT6OTVbuTgTb+GaWZjc/8/NthbSL8U8ZaNpRmezTgyWXoMndriDpixFR+Hp4NK
lp8jzy6o+CqWa+SnKYFjjA==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
HAY6r9yEPKCeFhOan/t+P//Lo2syvC5qUXnpR8DcGPl2+M2QlNfFVtJoErb15tu3
OLPN21atsRuOANGo80jK7i7gB90dKTtuEqd9byGbxP8vm+03l+ZTsGoIxrD928NQ
fNCvLjP+H9TRKw2raOGkzZYavFx1bwAAfGA3gQhhNVY=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_1 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_1 (
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
roMw/3l+Pzuh5FVnLSWZHIovAYaTxeV1F13lqSGZQCyXjmY9w6bqQu6adJzh0l+J
VrGeKuD0F/OdfWQergWGcS2EfndTSARq/D4TgHO/O1sRkgXQ9Z0OQXDzUMiRVcG+
ZiUlin8FKZIiEDtrIbbIJ4MzHEzvuGhJmLkQVDFzGHtWKrhID+oWsZmEG+u8bgkn
DPC18uECXJepZocfTOhEAt6DXB28+e6aePXt/mrJsiZcDP7jizvktmjkIW6Jq27h
QVujkk35mi/8SVQDQA/7c0KdqwtvSe502MeO9tAbX6HXZUI6+yi1prMhXOOeVAjz
w0DTCiuQBrhbCecW1D3F6w==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
eb5GUb/GT/St0GhkN6sbIApfXdTfQ5F38WwdZi5jvW8nPvJ0KsPdCQLJ5oIW5iNT
1ZpRk4BOtGHAGqIB8QfWA2H31+I8w5HFvZI5O8dRBddCzDizXrly/t6Ov5RZ/AAl
RvO345rM5I/clKb8zvKq8SELUajVwmOA6ueIKM3bTD49UqZr2P15gbug/rbHj9iE
+O+XpATxzxZdv9RclmjmU8KsrHlbEr91QVHfgXxuQHfKHbirp6x4j8UuojlOrTrC
iMU1kIDRRPsblIzXBmsHp219pCA/fn8MgSXUYjTSyb2gKarPyujAHV095zKNGwxq
iIpzn1jrSvYu8vz5/0jKEQ==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
rNlXRUGeZlMCWP2oDwqinuajvD13gFRpbPQIsy3NlXagMBIqbIyOi92FL+vu7ro8
LuLpHnve4B5YyEsKy+1SJAliog2nrEJsk4pszk6X6LisuGRG4MI+5wGnHWm6+oXA
LKwEqSj16WI67I8c0LTAiZidTZ6etLfKKa/Hx9j9ut4=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
