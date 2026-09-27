module task_7_wrapper #(
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
EQVPnQjUKqWth4SauJLTaaV9DOOw9J6BTFf8qiLfug2Di1SNYhpbrZhGXhsCgnd8
RK2iiCrky0tovdO9n1bsiHLBl6WIvoJ/b0lmAo4pkWEJUUg9hPx+SgXsGZv1v34T
RJUyJ7fPAjHbVGw8q7hLBVDzCwZSU8jhE+yL4ep9Z71VH+a8fUhr30r4xVdzg6A4
LMRyi4rDAzVSydMwMBwRDfzxZkLasKDVL/dJ/+Ui9cDY8YuEB6x71jJYVdilixdN
/VkcbY7KMMh+kbMtptZmuuT8+tUrO6FvDoykJV0u68RBy9pSMpP4tdxD+f3cizH9
r3TYWt+e5HBOPOX38sSu2A==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
lMTziwKbAAk2niTxYm4hvgh6OQa7T64JSI8xzRMQtXqEmXPnhbkpifYIcGGRjMiY
cxDBiNoF3gQTfZLqvjqIXeUUlbd0hlw4n4mcSHoBYsCQKzJD682O0MPHI8PbcTPx
7xNXbApjzgiJcIw2Pl1eOoEEqRn7YtOKZAj66X/RWanMw9hR21BTstt1WDMllxCU
GCR2NvLYkEZXYP4YpWT+HuZh+WrgyF89odwQvSu2W/Dv+VDHJJkYqXyQnK5jFzs9
FmRPbX2/FARmZ47c7jmAYA8N1E3255n2jz9sj6a6T9xEghLGTxkdVM3CHGz6+CY6
XfxMmX/cL+7+AOBfdv1uQg==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
AiK0+xcpLw360ay4cP52ZTY/LOGUSiOkNmwc76VBgV8k2zpwaHVKRWc3O1ZaY8w6
tr8y6XxEweIn49NfQ5KwQgLMylyDVJojvgON9Dh6d/1DeRqmCccvbCtz0UVMhRS3
hpS8PYv3yjbgxloKX8Y7He49CY6gOfQJzkozzmDjrz4=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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

`pragma protect end_protected

  task_7 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_7 (
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
EeLn2fUWr9mT+rvzDEgQpgB1eMdIUhf2B499yMBiN6R3zxufxPTUfbODwI7dZESW
884jFCnwiXung35otRXPBBEfKO1MflZqqz7JsWUb52F8Joa8P2r0aWhKCf7x+1L/
crOX4uINRTIXohYqEtIMQPoozC98Rl/c1OAjgYEeurf2Gj5x0/YQxJKB+sT1q6Xw
92ZnJpsPU/tkQCkae0YRjvgvUXvjFzvoIgPptR+QEnOZHMI/j/i8uA8kcYi58Qd8
ENlu7c8bvSUt+DBHnGAzURfyluwDeATYt14S/s6Hier5RbHojxLlLipulzBubBh2
JXisl2TASjs1dWCMzxV13A==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
VRvfqQsBJdUeG6uC4atksAGMRI+utSJ7+PMZMoz1JJjUBYuuIfPYhZEm9m6uZII3
TBewRol04FQEja4goTZl/idKWQE0Vg4lgpso02gh1QZSyAL4zfM0qTMVzJIIwD+c
onjqqZhl35IU/bbbHDaTJqIbcF0cAIMLvvlUeM95UNfRuYZ8eg5KtcTBaNsMbDAe
Of+L3JB1sRNcvIQeeR2duVLHbfCjbn0RHd/PqVzB4cDjsUJKAHyVpMEt6usMVZw+
LUUiPDZjhZ4fuD/sP9LgO0U0VjVWmEAuJDScihSTb9MiW2KIQih7Oi76z10/LDrQ
5SSv6Rod9AmnTPk+L36Zyw==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
Hj1tuiVcV2CXDDolWT4z0ZZ9M8Oyq21qOxl+G0krF00SVv94Nr1BVDuqO/SwqVtq
XcPp++GHTrBKSd2tF5EWwntxhLiJBkEPWSAkWXC6uiP8y0RmeWPjND5CtcPGzQC8
YxKCmWMU+nju7J8O0wGUF6wq8wKaToj6y32CfAX2jyM=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
