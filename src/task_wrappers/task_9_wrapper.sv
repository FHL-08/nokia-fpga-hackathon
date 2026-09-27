module task_9_wrapper #(
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
GvhzEhu4K+xJLf8ThpSmii9wKf2F3DmuwTmcHktIb9xjSrUFccn+yKkLUd3ox5Uz
Od8bsn7DIBCF4ylgjQclB3AC8Q5SM9Dy4Q2j736BvhlGS+l9MAfIvvMfyPh6jQT0
p+zCuyvkA2HloS6nZ7WVXovbHkYtX3HFg4lPIgQ7wijzAL2i7WNwsHJxwyqsfGAB
bLhINA+627LUCzwMZ6vmobmX51FEMuDcUz2a7VexBtinJT0O9qiNH+f0E0odAx1a
90NgJF3P0LCyXGsJYZ5d5PlC+fdDbnmwkXheN5ky97Ue62B+rnMr5VFlAiR1y2i/
V/wwRojFOAyuWW21t5LtbQ==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
wPgswemR9vNZXteg9002xYK96N/9WJYE9cQZkbbSoAfEesWUjo7WK9JcLLYf3bl9
GptVjoDw4GOI/sGg6qwZp/WIDY/Zj9Hac27fCdZMJr63UogT99S4UQTgJ0PssjaH
O7EAkk/Vrh56MxuaP+8vEw8PushdYbiVPFvif+J4aeMkru/HD1bwUkkD0zfycGCg
M9KPmS5Ty0lYK754KZ9wdBY/Fzb2ak4Lc1ZpSQHcj30/4pzSx86uIMj97rq26/YY
rbyj0/JipXNwa6o7Slaw9Lln11HPJM4TfqS2LbagQ16WI9N+YNPBSjTe1g/rv6GV
u7elGvw2K5eAOVMZ/aKz0w==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
N3AyZxx3Xbt47OFplQ1V4k2u0KhQfCuSFDiNeZR+5Iu/4VxFLxxeXpLtM4zbgz2X
yNh1kY6nuZV4C0Kpzs9rp/AUaqq8pGfC3HlbsxnEGkKc4fCugp2hxEQsRoTKQUj3
Psp9b7/RwTUkovz4KasxXVDW0zdWugRdp7y1ZeHGKTk=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2336 )
`pragma protect data_block
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

`pragma protect end_protected

  task_9 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_9 (
    .i_clk  (i_clk),
    .i_rst  (i_rst),
    .i_first(w_task_input_first),
    .i_last (w_task_input_last),
    .i_data (w_task_input_data[0]),
    .i_valid(w_task_input_valid),
    .o_data (w_task_output_data[0]),
    .o_valid(w_task_output_valid),
    .o_first(w_task_output_first),
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
RDfLEYIludbELTK89sLOBi/9JP4STCCvF4u799LyLkiUg/VKQwE7ZsIt8NAcba4d
lRD5+4ukZmX4RiVrzVEo6rw0GqwpeXIX0tHvajhoVaRoIwdnqYofczo8UX2A1k+3
bhRi5tAwJJkMh0+Rh9J57MhkRe/QAwtMQHoONf/IEL60v2xYRJsb6cTKhd1IV1zJ
7SpsgUPtE1wvtUTmquhMbSUbO5HFa1ToVlt24ZxaUpfczbZQQwGqHQq+qgpBek2P
9jPyquT1wBASXSUd+eS0geICXzsEHdruMHthsM4eczjnimfBBDB0h3HKrF+7g285
lK0p6rCp44EJ8cTy5g+KjA==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
lAKXiofiZqfWf1toKs292SOINrcXbOz1AUbcU9Rk5gJp9iWaSjIYuiEJi00xceJF
tLEr4xuu08DhcSBYZZLsTvrAj8zRTs1eL9/KxxGBXY/AFsRttEwfXcbqST9igauL
Nga4Qed0wRJqgMF44horyTzZ42iq8r+xKdoUBJkYKJUDQy8X9eOIv6EWK46W8IKG
tbVXwlUyRlvW7eAfA8ssl30gTQEsKlk/m7XLhSukb52xv5uUr8KMXhar18tJyKwP
c53Ep3uneUEHsoeNseBBDj77ro/7vCDbEEW6YV0uVLTR+5h5NdBIqVfHyQObYOgm
pa+JKj1JOiYQz4XpHP7tjw==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
Kt7i1G1ndfTY8RV5eggVyYvTrXDVMNwZqC9hz3ld2oVoQcjGuWk1WgFoPpumoH17
gaw8JHs3fDriVcbCRUtsJwwVo/RlJmMWiwIgyUi1E/fjc+Bavc0exU5U+TcH7eiE
QlS9GBnoCzeZJjR6z7ckcashoyOvw1YP4kZQeAAIe3o=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1968 )
`pragma protect data_block
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

`pragma protect end_protected
