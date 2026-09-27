module task_10_wrapper #(
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
kAjV/17aLO6usOhQZFPL3U21uVZ8JeIMstKYNmvwAwNduOnwN4bLhCcThbq4kQbe
kxrgL77F2HgWyggBLtEKPHASvavmfYmKwmi2mHfDCQbo1SNQ8rD0iizZTmWjFMuY
eS/5Zo8XAlSyZbuw9G67Y6lBrc1OIV0/kJjeC4C/MT/pcIUnqQR0bQsuKFyFV5Xn
TZS0N/hhe6ewojzlRK0gcTm5xiXdmwHXuoPF4GGN4PAjSZ/A6H736D0tIC9J4HNT
dtyGA7J99ZqtgcqdhAXwnEU4qHqwKbPLdJc76ws6hJz3TGSBfNPqzupsSTnxBQgq
iY4f3+VBSk73C+oD9ybflA==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
OmXtjW8frr+4Ff1pC2STpc04pnP6rhGvUtP/ypGDl+CyUixmcvSCwIyfzDrK77z6
kAcs2zTTUaGXkKMyU/8aZSp8Dc1hQ4PQde78qZOYQWOnq/WTsDMPMlsdemDPujjg
7QWG2/WRTckOaTGWtLK1PJwD73w+RBPV7Dr42nFOLju3wa/zDoUI0nzTwuiEadO/
9/X43z8FZHg3pBpqymYQj/5ah5mxlpPNIiYxsKQ784Tnhq34G4zU5HU7HOsAiWb6
7j41ldz7U4VjlSjCaBwE7mnWw6kl+yh4GCQnUweRZQV4GPql6mx5xylLY+jrH0Wu
yPKrgKR0GZJJcd9eDLKkSQ==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
gbQHF81xffsYX48Ac559v4Fh8IntoUYloJyWIcbiICkdjGqNe7JeuNg3035kULeF
e9f9B2UazQZ1oINJxEjfFFA9Zq90bvXbhRS9DuDCtI4eX+qSt1mEan1On/065K5g
vi0sJHOQg95WwwKXDQwaIUccK7UrXR2/1NNhnb07tyA=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_10 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_10 (
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
Cv67IY7F8QSmAn3LZG93KMfcinjWi/CwKjXsu/OKodA8wzb5vp2t9GTdSC6NN/1u
qHl7wNdnkHEFMXwHEtHmpTaTR+xsSUZ2L72KNdKQ01pFdubZpA6J02RVZ2aPcPW8
BogA71YZCs9dW06SyTqHUrM/fP7Fc6FFVzwvS9Z4w7zoc1D20sbSOH5bHs2M807r
D7YFSXYUF+TSUwzT9BEPVPcarukJTTB+RtJN3aFy0FZjhYOd0wV8yvC1TDds6s3g
PaOsmCE8ZZDWVD4SPHqB7OOHr21orYFQVY09IpgyPe/hLmOBIPGiNFfALcoeSXtZ
MaDtSyibBVdOV3+HKILlrQ==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
MIs9l2VHrA/zW9cilGIZK3Xm7RRRksl5al4jevtwH2x5RomvZWPlqEeglxDBlo4n
h86m9opvqjRP2iIU/1YMFc632MsNv0rdYBBQoC0xJxHarrBSgzodFe1kfPy3eTJi
n692D5pSoej5MGFzirg4faEE1cDF8kMK6ObR1glJqTvUpO01uur5vVlxH60YsrCm
rRm4y7sYCipvYv3IQJmFPZt3XxbjanpBXRsbszpnZfYzb0smi02gsxMrq7PZOqwX
Dx5x/oaYWjmYO3rbTUM6warv8W54YQuS3WME7J3+KoRD/o30yEIFApRY3vOzjTKt
ix+rP+MTmPPyg9UxM64QkQ==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
FIk+gFDLLaDLUoVOoqjG9u+jA1pQf9bJqKa8frnGjTesZHEfgUFkrjLhgHbwIVMu
bxLODgeFk2b3wDLZW2Su40HD0bL/OwovHdsN8ZMiHk2oO7rEnn49NmyYTzSeyWQh
uvHh7YgmYmX3RsA4ZjbeKFaEa4QwHACggPuJG/Cq4Xo=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
