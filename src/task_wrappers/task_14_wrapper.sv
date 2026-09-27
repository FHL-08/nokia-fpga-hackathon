module task_14_wrapper #(
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
Ji2xYPamGl9fpvdx9hQPNbs8LfeOVK00qnEUokfnRgW2D6sKBXfGQtjb3Mpe2oTD
dmx2K+xrirjmMkPVHp3jZrUd7/+QQJMucj1sLnkpeCIeYwsLL2XAY1/0fgPmBgyf
6Vhmlp+wdFKoqijKpZCk32G3D53y3xcRG3d+omXpuHNS1HlePwkHF8ozadEuYGVI
3uHqhSmIwRpuXbbj6JL58blzBbbSU4ZUW/Vrus4ceyZr4fo7htKd157zAfPn6EQF
Sa+81/nmioIkYVPTMlWhlIpKI3oDABVYmaZ3tMffyhlQ2/tv0I0zhczVVKhWDTLu
DWtjxD98eb0ylp+kOIgjKQ==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
Nk5qRUJEDNIy1SBa8ultQtfk+72c95vHaOq70K9olhD2Bg6hWJAQthNXK18IqLgn
EpsiFKjLPCyditkogfFlnalwkQYLbdHxHtikdtS2Vn74zi8IsHCEVxa+2byn8amh
+RGRPTLln6UvVNQ9JTU+lt5y0T7LcQ1PuecoOL8jOVYaO4+c/LmHfqA2EiQwHjME
OR42csgH3dr76M8rjt6x+KkH1YwhYQYCjDXZy+MssYx90uV2pwn0vcWtLaKZOgHG
9cvfubmJn+jwzkZz136Yzm1wrILCpuGlVlU7cFXDuQXYVk3WHW8TMUWpNGCwYKOK
ATSWZFO7E9F+/GQDPyzVpA==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
DOkAyh80MFKF5a6aEs0Xyp/2b691zuQ8uGS00Gd5zC/ag8AsIwqTt67SfYLO/hyy
w3wJcX8MzmBjAf7ppf323WUg7C+qi0+r52qt3RbIgsaBfuCaYICcfaEb4Pheo8WH
hLz6HkfOvh2y+VYERvdeX3/xlp5jPhnfNDrsQduw2JA=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_14 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_14 (
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
SzxR30LSmhnl6wntvduTNIgSO6xy85xfPM2Cw+4YT6GpwvdF+DP1KpEuNwfuZb76
nC1kt1wczlZCbu8O6r0n7amzpEwQhn4NLlb1u+D0wwO12esIh7dzR1potOmfU+Vq
raGwd/YhNG0Ihcm6RbLmjdYaQcBGHbz8aAzoa4oPLqGvc16aOMvOvgM2Dh+naB+a
+pOAWxt8AEnza+3fBIrxOyuAnqsCQ3pW5Rvk+dWyiwnhoxWW6r6EnISfK7gGqf5Q
ZjaY/Sk/uA4z9NvXdJhQaXjs26sAXEKHQ2tEcybduGTvgkSxAiz571Lapv8D2g93
dCuDF74Ac20/n3EI3vf17g==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
J5PsrALGZJF6WvSDesvzMeeI36bWaCCTPOmKEajLYM7fXnat7Ze1N6CanTHdsniV
aUDyrCvJ3KNYWJv78MidG89LiVOLnUUXSa5Ibw4rkiFg8GxChT+DKab3TgUd5mXl
nG4RakP6RCQz7ITCw2+69s7HKCIfU7TxrzLF1NJbBBLxVjqiw421gJWM+kNpIfyg
SrFAWkcFgW4Sahv6QyJjepjIKvM6v4bMY4l1vve6NgGgM+mNr0RxbmRpFNt6D4LD
Z1aQ3drm6ZCtBTuRSf1TlypNuXcrcfQUB92xrR2b0ok3KsHDmKzWVQ8fJr/jLZeE
0z9+NPyVvBQHAnJSAjhkTA==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
leDG5Cnnr3mjgCGMBjq2Z8RnjtncJtdvif21snpSJO95y6bK4MxMi+SHvCpKk+7P
Yb0tzQRAv4YFKOkRPMg4ikyf84etXrZ5nQAofQ4qvWN1+rF4kdGcFpVkXUclDXKR
2OSPBPCy0jYyTMVZ8ZY329rZ6n1Jh6J6SRoP50fho1U=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
