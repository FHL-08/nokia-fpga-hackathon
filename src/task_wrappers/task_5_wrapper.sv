module task_5_wrapper #(
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
mGDPyMLqonNY70DAVJ5zN9eo2HGQyaakKuIdzKusVE618YBszRsRowQE3yYflZfZ
Y6rBTA6di/FJJTE24EtZg0WYUc8faqdFRV+kBTruVvJcit/NJ5swxqUx3I5hERXo
9ZidhqxtiV793J16A1O3js7yzElYjSQkXvHOehDpapNM11sYpvsFAyndgKpd8hCI
8T03tV7dHr5MiBz18niIzA11gIrwK7oUP7pkShhq6Qx1tIobYxtQg1apbx7m9Kld
dmurLH3p523k3zpFvBI6vhi7oPM7MrhpRpHSsTbwt7Qq9CEtIXUEW7WQdR7zm0ls
hauV/FdQJ/3rZbNX6j+7pA==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
h11dr4PT0V+S91JimlcyNDG/oNTCTaF40ilJt5bGfx+ZjKCKupskknUTCvpeaVpu
UT5NU7N+baGEUBTAWuLrhBfmcfsFuWWV6le5kjm7iTlOjgGZ0NKyVjTG7xiI2UoU
DZ5XGmAgYx8E7Av9K1VECuv3O19Nt01QI35Anx8Lrw/wvRMwozhpPgmGFAK7CxWl
EpY+c0MXfMz4eTR0UsjaqZ1fvBwopQ7EMe8UdKhS71NyDNu7Gfb4hGrbfzFgrS+p
b7P6yrDCq3nta/BH8oWWZiShXi2AWkAvWb/brAzDzy5ot/Tari9SyIFZ9IxOtUk8
OwV0+DuuS+0gYqIKWDpVeg==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
UdwfTiE/AYJe+QF0Of6OUItdN65QhxJ/0sBftA0w7b8p/CnpPuXNVMl6yxCagxiz
sEBquTH7FLtxTlMhRe7Fo1SquyoGJMiMAHO3b9JN2BwYaYr/0w1x00ervcUGm8kH
BFe6kmDoviRTQsjzOT8h8xMXTyRuf0xJvgKHH3Mr+BQ=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_5 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH),
    .MAX_MSG_LENGTH(MAX_SAMPLES_IN)
  ) task_5 (
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
rama5EaAeuk1jR3euVyqjxogIvSJTraODr62Hqrxa5Q6vfdlftEOGkkYdg/yo0+h
XRQvq8mtJs0s0h5Co3NJPva1qbD2B/dV43w7N/wHWlabQ42J58zLFtC//FT1hAOz
i7J+1pFL4qvU5eH49fcJdC1kUTtUWTN5Ix2iQvKl2njOY5poSKJV8BhW24f6l6L3
SWXhzLyQ7FA5QrESEiRHHhW3LgqNf6KDORI2i+ALWh8pacJJ1WCzmEjOwGJbZqLE
FhpIXiMVrvUCmlc2nkPM/6hqcPTgblUVRzbc0FUzWr2G4TkGTzm8ZB5WwhBOOrG/
Bul7QKuXBP5cWEaEqztWRw==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
zjgz0kZ9GM4s2+yJJp/YK4m6s4XAE/vyAp9jiBl6+fJg2u0muBsz13KK9kkAApQH
hHM7P+2DrgE/Y77I3quzLrqPbboxR/Ooy5Cop9IEvyG1saXzN0/yVinesPNh8o/u
q8ZwoRkkRvAOd5Ot/iuC+0FDPB8TDyqa7R2TcVQ0EolUDBqJDg1Z1Y0Ks9RdRTbm
hKHaTyG1ra8itzgTwCE0w9Dj830SxshSvtr4rVGF9ot5ECI4NnRTI7JYIfA7ovnL
GoOcDOi5oREgCbSx630plHyVrT9p8BsM34dDZajeYSC/XdKP/mTbu9ZYGR9zqiSi
1iThT1rGfEQA3bc+IRIt+g==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
iIIAw0THsD9Ai7tOZQNKrWECjQCV5NLZTf4pZ0oQ/1ZP6jfIDvU26mTdECrYe/9C
3WSB99r31bXMYJ7bqeOmT0vIOl6Vjyf36mPblJWOGK1CVHeP2a026LSW4cZyKCvi
wo/XdSe56v9dAROLpXj6/eUxgo6JArVZFmP53qhALi4=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
