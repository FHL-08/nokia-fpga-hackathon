`timescale 1ns / 1ps
module task_8 #(
    parameter int TASK_INPUT_WIDTH  = 32,
    parameter int TASK_OUTPUT_WIDTH = 32
)(
    input wire                          i_clk,
    input wire                          i_rst,

    input wire                          i_first,
    input wire                          i_last,
    input wire   [TASK_INPUT_WIDTH-1:0] i_data,
    input wire                          i_valid,

    output logic [TASK_OUTPUT_WIDTH-1:0] o_data,
    output logic                         o_last,
    output logic                         o_valid
);

    wire        mb_out_tvalid;
    wire        mb_out_tlast;
    wire [31:0] mb_out_tdata;
    wire [3:0]  mb_out_tkeep;
    wire        mb_out_tready;
    wire        mb_in_tready;

    microblaze_system_wrapper u_mb (
        .Clk                    (i_clk),
        .rstn                   (~i_rst),

        .M_AXIS_MM2S_0_tdata    (mb_out_tdata),
        .M_AXIS_MM2S_0_tkeep    (mb_out_tkeep),
        .M_AXIS_MM2S_0_tlast    (mb_out_tlast),
        .M_AXIS_MM2S_0_tvalid   (mb_out_tvalid),
        .M_AXIS_MM2S_0_tready   (1'b1),

        .S_AXIS_0_tdata         (i_data),
        .S_AXIS_0_tlast         (i_last),
        .S_AXIS_0_tvalid        (i_valid),
        .S_AXIS_0_tready        (mb_in_tready)
    );
    assign o_data  = mb_out_tdata[TASK_OUTPUT_WIDTH-1:0];
    assign o_valid = mb_out_tvalid;
    assign o_last  = mb_out_tlast;
endmodule