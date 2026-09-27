`timescale 1ns / 1ps
module task_5 #(
    parameter int TASK_INPUT_WIDTH  = 8,
    parameter int TASK_OUTPUT_WIDTH = 8,
    parameter int NUM_OF_ROTORS     = 2,
    parameter int MAX_MSG_LENGTH    = 1024,
    parameter int ALPHABET_SIZE     = 128
) (
    input wire                        i_clk,
    input wire                        i_rst,

    input wire                        i_valid,
    input wire                        i_first,
    input wire                        i_last,
    input wire [TASK_INPUT_WIDTH-1:0] i_data,

    output logic                         o_valid,
    output logic                         o_last,
    output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

    localparam int COUNT_W = (MAX_MSG_LENGTH < 2) ? 1 : $clog2(MAX_MSG_LENGTH + 1);
    localparam int ADDR_W = (MAX_MSG_LENGTH < 2) ? 1 : $clog2(MAX_MSG_LENGTH);
    localparam int PREFIX_LEN = 47;
    localparam logic [PREFIX_LEN*8-1:0] PREFIX =
        "Hello, FPGA Hackathon! Your secret message is: ";

    generate
        if (NUM_OF_ROTORS != 2 || ALPHABET_SIZE != 128 || MAX_MSG_LENGTH < 1) begin : unsupported_configuration
            initial $error("Task 5 requires two rotors, a 128-symbol alphabet and a positive message length.");
        end
    endgenerate

    // Buffer the packet, try each initial rotor pair, then replay the plaintext.
    // If several keys match the prefix, the first match is used.
    typedef enum logic [3:0] {
        IDLE, RECEIVE, CANDIDATE, READ_REQ, READ_WAIT, CHECK,
        OUT_SETUP, OUT_REQ, OUT_WAIT, OUT_SEND
    } state_t;

    state_t state;
    logic [6:0] memory [0:MAX_MSG_LENGTH-1];
    logic [COUNT_W-1:0] write_count, message_length;
    logic [COUNT_W-1:0] check_index, output_index;
    logic [ADDR_W-1:0] read_address;
    logic [6:0] read_data;
    logic [6:0] candidate_r0, candidate_r1;
    logic [6:0] check_r0, check_r1, check_reflector;
    logic [6:0] solution_r0, solution_r1, solution_reflector;
    logic [6:0] output_r0, output_r1;
    logic [3:0] check_steps, output_steps;

    function automatic logic [7:0] known_byte(input int unsigned index);
        known_byte = PREFIX[(PREFIX_LEN-index)*8-1 -: 8];
    endfunction

    function automatic logic [6:0] forward_half(
        input logic [6:0] value,
        input logic [6:0] r0,
        input logic [6:0] r1
    );
        logic [6:0] t;
        begin
            t = (value ^ r0) + 7'd1;
            forward_half = (t ^ r1) + 7'd1;
        end
    endfunction

    function automatic logic [6:0] reverse_half(
        input logic [6:0] value,
        input logic [6:0] r0,
        input logic [6:0] r1
    );
        logic [6:0] t;
        begin
            t = (value - 7'd1) ^ r0;
            reverse_half = (t - 7'd1) ^ r1;
        end
    endfunction

    function automatic logic [6:0] decode_byte(
        input logic [6:0] value,
        input logic [6:0] r0,
        input logic [6:0] r1,
        input logic [6:0] reflector
    );
        logic [6:0] t;
        begin
            t = (value - 7'd1) ^ r0;
            t = (t - 7'd1) ^ r1;
            t = t ^ reflector;
            t = (t - 7'd1) ^ r1;
            decode_byte = (t - 7'd1) ^ r0;
        end
    endfunction

    // The known first character determines the reflector for each rotor pair.
    wire [6:0] derived_reflector =
        forward_half(7'h48, candidate_r0, candidate_r1) ^
        reverse_half(read_data, candidate_r0, candidate_r1);
    wire [6:0] checked_plaintext =
        decode_byte(read_data, check_r0, check_r1, check_reflector);
    wire [6:0] output_plaintext =
        decode_byte(read_data, output_r0, output_r1, solution_reflector);
    wire [7:0] expected_plaintext = known_byte(int'(check_index));
    wire check_is_last =
        (check_index == message_length - 1'b1) ||
        (int'(check_index) == PREFIX_LEN - 1);

    always_ff @(posedge i_clk) begin
        read_data <= memory[read_address];
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state <= IDLE;
            write_count <= '0;
            message_length <= '0;
            check_index <= '0;
            output_index <= '0;
            read_address <= '0;
            candidate_r0 <= '0;
            candidate_r1 <= '0;
            check_r0 <= '0;
            check_r1 <= '0;
            check_reflector <= '0;
            solution_r0 <= '0;
            solution_r1 <= '0;
            solution_reflector <= '0;
            output_r0 <= '0;
            output_r1 <= '0;
            check_steps <= '0;
            output_steps <= '0;
            o_valid <= 1'b0;
            o_last <= 1'b0;
            o_data <= '0;
        end else begin
            o_valid <= 1'b0;
            o_last <= 1'b0;

            case (state)
                IDLE: begin
                    if (i_valid && i_first) begin
                        memory[0] <= i_data[6:0];
                        write_count <= 1;
                        if (i_last) begin
                            message_length <= 1;
                            candidate_r0 <= 0;
                            candidate_r1 <= 0;
                            state <= CANDIDATE;
                        end else begin
                            state <= RECEIVE;
                        end
                    end
                end

                RECEIVE: begin
                    if (i_valid && write_count < COUNT_W'(MAX_MSG_LENGTH)) begin
                        memory[write_count[ADDR_W-1:0]] <= i_data[6:0];
                        write_count <= write_count + 1'b1;
                        if (i_last) begin
                            message_length <= write_count + 1'b1;
                            candidate_r0 <= 0;
                            candidate_r1 <= 0;
                            state <= CANDIDATE;
                        end
                    end
                end

                CANDIDATE: begin
                    check_index <= 0;
                    check_r0 <= candidate_r0;
                    check_r1 <= candidate_r1;
                    check_steps <= 0;
                    state <= READ_REQ;
                end

                READ_REQ: begin
                    read_address <= check_index[ADDR_W-1:0];
                    state <= READ_WAIT;
                end

                READ_WAIT: state <= CHECK;

                CHECK: begin
                    if (check_index == 0) begin
                        check_reflector <= derived_reflector;
                        check_r0 <= candidate_r0 + 1'b1;
                        check_steps <= 1;
                        if (check_is_last) begin
                            solution_r0 <= candidate_r0;
                            solution_r1 <= candidate_r1;
                            solution_reflector <= derived_reflector;
                            state <= OUT_SETUP;
                        end else begin
                            check_index <= 1;
                            state <= READ_REQ;
                        end
                    end else if ({1'b0, checked_plaintext} == expected_plaintext) begin
                        check_r0 <= check_r0 + 1'b1;
                        if (check_steps == 9) begin
                            check_r1 <= check_r1 + 1'b1;
                            check_steps <= 0;
                        end else begin
                            check_steps <= check_steps + 1'b1;
                        end
                        if (check_is_last) begin
                            solution_r0 <= candidate_r0;
                            solution_r1 <= candidate_r1;
                            solution_reflector <= check_reflector;
                            state <= OUT_SETUP;
                        end else begin
                            check_index <= check_index + 1'b1;
                            state <= READ_REQ;
                        end
                    end else if (candidate_r1 != 7'h7f) begin
                        candidate_r1 <= candidate_r1 + 1'b1;
                        state <= CANDIDATE;
                    end else if (candidate_r0 != 7'h7f) begin
                        candidate_r0 <= candidate_r0 + 1'b1;
                        candidate_r1 <= 0;
                        state <= CANDIDATE;
                    end else begin
                        state <= IDLE;
                    end
                end

                OUT_SETUP: begin
                    output_index <= 0;
                    output_r0 <= solution_r0;
                    output_r1 <= solution_r1;
                    output_steps <= 0;
                    state <= OUT_REQ;
                end

                OUT_REQ: begin
                    read_address <= output_index[ADDR_W-1:0];
                    state <= OUT_WAIT;
                end

                OUT_WAIT: state <= OUT_SEND;

                OUT_SEND: begin
                    o_data <= TASK_OUTPUT_WIDTH'(output_plaintext);
                    o_valid <= 1'b1;
                    output_r0 <= output_r0 + 1'b1;
                    if (output_steps == 9) begin
                        output_r1 <= output_r1 + 1'b1;
                        output_steps <= 0;
                    end else begin
                        output_steps <= output_steps + 1'b1;
                    end
                    if (output_index == message_length - 1'b1) begin
                        o_last <= 1'b1;
                        state <= IDLE;
                    end else begin
                        output_index <= output_index + 1'b1;
                        state <= OUT_REQ;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
