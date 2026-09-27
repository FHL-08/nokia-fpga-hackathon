module task_15_wrapper #(
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
eR6g1dJTe69pBoEb6TPZgsOlSmx4JLuau/FdjZBP2pQSYXHxjoKkM/f5rHXhB+zc
YINFmsQRIJfvYrBHuPGUclTOyuZoJfBeieuQFxNI46Vso6I7rdzkDH+EgBLZXG3N
r/Al98UgOBvaEpOFLxPhZ9ZU1nwrpGhNlLrkRPT6bzD1vaZzOOR12vVCnG5+5y+s
/cnC5wfKm7xJoy5+HJWSa60PgnbXrjSfXlGs9wwUkgYXmWdPTX5AQRM7Qsuu2Cws
uzm2S4v10D43riD22dzJMsb2dndq7ch8yy0C5AiKhZSIsRJl5cFiAHqEdAQiMdVy
8XEBRaPgnZqFEAr2wDw+OA==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
E9aIBaB4PnuZXi7PYbjg6z9hCsB+opXgky8sRMj7kji3oISFJiS73FEKkWAIZglU
DbFRxm3PPnWXUbQhmI2Wg3d4C4vhV5LycYf8kitLtMPwBOVwZz6NjXRPdbMgUiNf
PbuacvvZGnJxC636hsdobTytVxTzFrD3D6YZDwdyJopc/Qs5TfegtN0Ox51dk2eE
P07GQeg/HcWZLsi0IwPa89nMN8Zkyb8NHIGTioWl0AhvVLJoS1lybW2ILbC0Liv+
2gFadrh8DVFCfoMV7aU7HXYIS1Orv70S/qtQgC/6AUukMotkxe628lYRyYF6/dT3
wUt4vll1AXyvl5Rn8i043w==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
NNyUiD8TezF2InvPrMfxFiz+ggytHvsPQzCQCuqbffnzPCUalXCd5sOQ8TeYBrDf
6W6JyB7ks4Dvwpcyrz4VXukuS7SG55jSjsBePMGsZEPw7an2CrT46/OUYrviubK0
mKLaL0o5W6G81qYfq6pDZoQD1wmyFPQeyYFT2MBh6WQ=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 2288 )
`pragma protect data_block
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
q3bCR0hFYlDhyNAI+1EiraWQTRQxOZ/SGv0kx5enTwvj7JBdfPEann0fT2peuj/j
K/dnaERoY/laFSuFBclvKIk5k9M/siFLv9gyDAWbf+oYfu0U1st7YTpG/muB1GLq
W4IJFxaVPd5Y37YzmPuoTQ/PZEDXacGPbOAUDD+qeo3X4LLWbHn0yaeNdBd28gtg
aujwOOcTPLPoSNBvGr04cHCdY6t+70libO2MVM9y70pjaj8gsyme6ZAKlpUdK5+p
Enxuz1IF5IQn3ibkGJTCHqU16O0y6IWqYAo5XghV5TcMmAlmBfdd4jurF3XZQ9XQ
Q/29oTVzytk/Zj1cAL8G3Jvkhsu97k8ieqsuF2JGFAJCiRitzbmONAXYN5QhClI6
D93xrmpTpEekYamMZafd2V8MVnvsAnIeaOjpJmjlK0Czevn1R1J4vnPnjf9L4IE0
otoO+dNyuLOtLJHLNadXQMfZZNs7NkzqDSeWqzw5fvA2oKueaXxXnGOb9uO4ONci
hAhbjNAXCtdGuF7Vr0wUHJl+Hu+/BGO1IgadvYOaFHudOrp3sqKxu2OtFGr0UBxL
mSz83nIZUxahmenU4av0374n0fsdn2UtbrUlb72j33I=

`pragma protect end_protected

  task_15 #(
    .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
    .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH)
  ) task_15 (
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
TpfI4UeolNrzmSVtAfK68RJu/v8YdrbLBNx4rnPWIP5Itp48roj62PEbinkHfwns
jeAmubzYP15K6VvIjCs52eaKi0Y+g/2plNsT4JtiwSUxzVLQfbhd8/SWnV/1pkiJ
95mxP6hDhZErYXWKlJEJhFGcPj6LX4KmcEoDWNoyyyBULONsJWJshtNUfy7saKRM
ya+yhEpPgcU+BLAK2pIcQKdmAu8HMV1YN1nN23ZXVIlTEDL6zEn/1NMvlAXZqXXT
vfX7j11p6rki1YJl42+mzbjf0zJnNznQuLVMeV1jO8lFNPVQIJkV+a2ce+v54n/i
tl49BxOpuYUQTyE9853m2w==

`pragma protect key_keyowner="Siemens"
`pragma protect key_keyname="SIEMENS-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256 )
`pragma protect key_block
qrbF9sqRyzIYthsehwfsuIGi/rVxMHz0LXbPRg8EqwdkaCbFhJEIjqt15F3gGnyq
pNDg4xB7obGUoGDrVCqSx5T6JDRZyPcm+vPgCFNPukGZF8P/hsGP4/68qP2D2u65
aJZIgIinbFnpmyk+kM87W5yXSymHL1pd/XZ9afC6iY/7Ga2+dlufHzfrhZtpxy9T
yZ1WNlJamKuluchzsTa2a6hkNPE2OUz3hUJCEsmtCCePZy6Lv9BPFMNoQ7h+n3ER
tL3C8+TanLyGPmigDQJ/MNt5CI1BfcmC/ynJUHnqHJCW9n8VH/UnfZqIJOLY0e/d
1Fm9Z6GsxjFsU273h6h6kg==

`pragma protect key_keyowner="Synopsys"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect key_method="rsa"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 128 )
`pragma protect key_block
BRKmI4zcPh3f9yo8oRwLhODR0nuJJ5/fG99FS23Gyf24zsqNp4podYF+wqJt1Zkx
KsIVT/WZzZx+qkCNb2tiCdu7GI5IwVmlQC9+pwu8uCrRbBObQ/BbVNbMtTegQ7Cv
WqucyMlaFwairVvEe7HycJhiXUUm5kFK5ZWy/rB9UG4=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 1904 )
`pragma protect data_block
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

`pragma protect end_protected
