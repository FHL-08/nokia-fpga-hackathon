module task_11_wrapper #(
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
PNWQxN1zdA05cjywKMVoGRw5lYrpIvcXGQDAGvN173G6YRWyC93qqBfA2+g8fygY
4uzby4tUzYPYabZr/O44icgArv19+qdW2P2NnLN59tuy0UdtEUUNp/OTCJIES+Xy
XE4nDRko82aIl3ZD1twAIHdQCy35rAj05xPB/dEDTCdhGKmgnxDR6mVbMUksPFPz
cg7i/Q8yjLP9sQm29G4RMQnzXLhhBUrf3RlizXibPOhF7rCi8sEcxydpH37e/iZ4
VCN5VWRfjk82NkSDOqe7eaMtra2v/aQCmZppoAhBuOmacGRlQ5/VAQLzCs4nNs8Y
N2s3VjpKoT4mAS5pfHfaJg==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
N1d+7ElhT4+GXoA0rAIQbfnaLToyjuDCFtI8YqgejnuFbtuxwYlUgbTMmLodA+nx
8JxTdyX9NLMg0K8nyOXyE/fX36/ifPdyZnyv9LH8FLt255Zv2Nmzc7BBeMqv5PjL
Wr4H2hfl+Szi0BsaRvipnpCdXUO3Y/SwJzhAau6jUtVZqceyj3lfSMt1uQmWQof1
gOFNmSgmCKbQee+XEAI+PBX3pz4gUIKqa+Z6GKqQ5yx1v5iwUnMf/6Xo+JMQ/nic
VyGt7++tr4T2iTzPgBraRPqnsZCORPgFuhmp9TKdmrZHljGo2qfKsu7/PvBXSL/D
BDs/fxznRTgSE7X5DNmMgA==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
IVlFOZbxwCqtFWIgLo9g8pbDruwXw7dQpcCFoNWkQbMUZobHSX3lUQX4skHhUfpk
ZBmV7JXVDgoRnIkB4f53wYVjLACsfsGSzTlzLWt8Pghs0zgfdsr+ymEXeHGgTzjp
g8lXzoh9FaN20HqFn13/Jw4xKZPQFcZf0omA2LAPUEs=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_11 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_11 (
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
dOyfRp1+X3xytSONIajpBZgceTPrEs2iv82rIqy7d5CeESkLoxjsHDjfOJ4dJUb0
AGAdqxGCXvGZFVd39cNnNFpVecvcOr++T0YClm9IILktBo8RId+le3f+ROn0R4Be
awR0QZBxB0tDYfpLBC2K76tBD1Q4vZccgVUEhPT0z2oCcJRtmWTuG0GQG5LZ+nvS
43Z3xe39OtiT+jkwh+G6VlQzX7S3PcKL0Utr59us0s4Ukq/MsSPEuaJ9PMsNz5YK
J+pvu5T6eoImxZHPNVutljod3SyNvQ8IoZi5qY/0/f8xBHmFLpogTBpT+972earn
h33nBMAkh+LF35dR5NbM+Q==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
VIgFmXVKRZW8EXG1oH3+9LQG5ry3wRAXVfnOZgmlQFT4wJ2uKX1wwuxnreOIk9Bo
EsTZisbNP7eMAymOUCly7LUWCTy+nsd+HQce5unyKv3oS4l8lGF8fkfAUPR3QWno
V07m1jnGethbW4NimXy278glXgu9e6v9CbBrBLW8UxvrnNaH/hbi4CQR76LF0SvQ
bGcDN6sUDKbRn0ufCNSErSv8k2kX2SdPAHGyE63C8w7I/toUVQM3cplF1EfTZ2Ld
NO+j/C1UuUVrsxeBrSIk5VE4ZDvV24gJO4SFUXw5jYb4LFSlJzTWRXK5llsR92NC
FOyiSBiKVtl9bhtRA78/qw==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
Vy9b4qA6nfEx3E57n+yJASrmuJZTl3blAkEWaFHNqzJITwmh1PNQlzef/v/SpL5n
B6F7vlfjMmaR333UFQ7w4KdiAyYeUdyD0BzmDanROpPbCMVACkeDAKHzR7u4KAEW
mQfML6AQgMaoi4N1n2kwyL8cOnTOWvViV3OKrVk3d20=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
