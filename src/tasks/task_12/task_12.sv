`timescale 1ns / 1ps
module task_12
#(
  parameter int TASK_INPUT_WIDTH  = 8,
  parameter int TASK_OUTPUT_WIDTH = 8
)(
  input wire                          i_clk,
  input wire                          i_rst,

  input wire                          i_valid,
  input wire                          i_first,
  input wire                          i_last,
  input wire  [TASK_INPUT_WIDTH-1:0]  i_data,

  output logic                         o_valid,
  output logic                         o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  localparam int MAX_TOKENS   = 4096;
  localparam int MAX_OPERANDS = 2048;
  localparam logic [31:0] MAX_VALUE = 32'd399999;

  localparam logic [1:0] TOK_OPERAND = 2'd0;
  localparam logic [1:0] TOK_OP      = 2'd1;
  localparam logic [1:0] TOK_PAIR    = 2'd2;

  localparam logic [1:0] OP_ADD = 2'd0;
  localparam logic [1:0] OP_SUB = 2'd1;
  localparam logic [1:0] OP_MUL = 2'd2;

  typedef enum logic [3:0] {
    S_INPUT,
    S_EVAL_REQ,
    S_EVAL_ACT,
    S_EVAL_RIGHT,
    S_EVAL_COMPUTE,
    S_EVAL_RESULT,
    S_OUTPUT,
    S_DONE
  } state_t;

  state_t state;

  (* ram_style = "block" *) logic [22:0] token_mem [0:MAX_TOKENS-1];


  logic        finish_pending;
  logic        num_active;
  logic [18:0] num_value;
  logic [18:0] prev_value;
  logic        parse_error;

  logic [12:0] token_count;
  logic [12:0] token_index;
  logic [11:0] eval_ptr;
  logic        token_re;
  logic [11:0] token_raddr;
  logic [22:0] token_rdata;
  logic        pair_pending;
  logic [18:0] pair_value;
  logic        eval_we;
  logic        eval_re;
  logic [10:0] eval_addr;
  logic [18:0] eval_wdata;
  logic [18:0] eval_rdata;
  logic [18:0] left_value;
  logic [37:0] calc_value;
  logic        eval_error;

  logic        output_error;
  logic [31:0] output_remaining;
  logic        output_pending;
  logic [7:0]  output_pending_char;
  logic [2:0]  error_index;

  function automatic logic [19:0] roman_digit(input logic [7:0] ch);
    case (ch)
      8'h49: roman_digit = {1'b1, 19'd1};
      8'h56: roman_digit = {1'b1, 19'd5};
      8'h58: roman_digit = {1'b1, 19'd10};
      8'h4C: roman_digit = {1'b1, 19'd50};
      8'h43: roman_digit = {1'b1, 19'd100};
      8'h44: roman_digit = {1'b1, 19'd500};
      8'h4D: roman_digit = {1'b1, 19'd1000};
      8'h41: roman_digit = {1'b1, 19'd5000};
      8'h47: roman_digit = {1'b1, 19'd10000};
      8'h50: roman_digit = {1'b1, 19'd50000};
      8'h46: roman_digit = {1'b1, 19'd100000};
      default: roman_digit = {1'b0, 19'd0};
    endcase
  endfunction

  function automatic logic [2:0] operator_code(input logic [7:0] ch);
    case (ch)
      8'h2B: operator_code = {1'b1, OP_ADD};
      8'h2D: operator_code = {1'b1, OP_SUB};
      8'h2A: operator_code = {1'b1, OP_MUL};
      default: operator_code = {1'b0, OP_ADD};
    endcase
  endfunction

  function automatic logic [22:0] operand_token(input logic [18:0] value);
    operand_token = {TOK_OPERAND, 2'b00, value};
  endfunction

  function automatic logic [22:0] operator_token(input logic [1:0] op);
    operator_token = {TOK_OP, op, 19'd0};
  endfunction

  function automatic logic [22:0] pair_token(input logic [1:0] op, input logic [18:0] value);
    pair_token = {TOK_PAIR, op, value};
  endfunction

  function automatic logic [7:0] error_char(input logic [2:0] index);
    case (index)
      3'd0: error_char = 8'h45;
      3'd1: error_char = 8'h52;
      3'd2: error_char = 8'h52;
      3'd3: error_char = 8'h4F;
      default: error_char = 8'h52;
    endcase
  endfunction

  function automatic logic [48:0] roman_chunk(input logic [31:0] value);
    if (value >= 32'd100000)
      roman_chunk = {8'h46, 8'h00, 1'b0, 32'd100000};
    else if (value >= 32'd90000)
      roman_chunk = {8'h47, 8'h46, 1'b1, 32'd90000};
    else if (value >= 32'd50000)
      roman_chunk = {8'h50, 8'h00, 1'b0, 32'd50000};
    else if (value >= 32'd40000)
      roman_chunk = {8'h47, 8'h50, 1'b1, 32'd40000};
    else if (value >= 32'd10000)
      roman_chunk = {8'h47, 8'h00, 1'b0, 32'd10000};
    else if (value >= 32'd9000)
      roman_chunk = {8'h4D, 8'h47, 1'b1, 32'd9000};
    else if (value >= 32'd5000)
      roman_chunk = {8'h41, 8'h00, 1'b0, 32'd5000};
    else if (value >= 32'd4000)
      roman_chunk = {8'h4D, 8'h41, 1'b1, 32'd4000};
    else if (value >= 32'd1000)
      roman_chunk = {8'h4D, 8'h00, 1'b0, 32'd1000};
    else if (value >= 32'd900)
      roman_chunk = {8'h43, 8'h4D, 1'b1, 32'd900};
    else if (value >= 32'd500)
      roman_chunk = {8'h44, 8'h00, 1'b0, 32'd500};
    else if (value >= 32'd400)
      roman_chunk = {8'h43, 8'h44, 1'b1, 32'd400};
    else if (value >= 32'd100)
      roman_chunk = {8'h43, 8'h00, 1'b0, 32'd100};
    else if (value >= 32'd90)
      roman_chunk = {8'h58, 8'h43, 1'b1, 32'd90};
    else if (value >= 32'd50)
      roman_chunk = {8'h4C, 8'h00, 1'b0, 32'd50};
    else if (value >= 32'd40)
      roman_chunk = {8'h58, 8'h4C, 1'b1, 32'd40};
    else if (value >= 32'd10)
      roman_chunk = {8'h58, 8'h00, 1'b0, 32'd10};
    else if (value >= 32'd9)
      roman_chunk = {8'h49, 8'h58, 1'b1, 32'd9};
    else if (value >= 32'd5)
      roman_chunk = {8'h56, 8'h00, 1'b0, 32'd5};
    else if (value >= 32'd4)
      roman_chunk = {8'h49, 8'h56, 1'b1, 32'd4};
    else
      roman_chunk = {8'h49, 8'h00, 1'b0, 32'd1};
  endfunction

  always_ff @(posedge i_clk) begin
    if (token_re)
      token_rdata <= token_mem[token_raddr];
  end

  xpm_memory_spram #(
    .ADDR_WIDTH_A(11),
    .BYTE_WRITE_WIDTH_A(19),
    .MEMORY_SIZE(38912),
    .MEMORY_PRIMITIVE("block"),
    .READ_DATA_WIDTH_A(19),
    .READ_LATENCY_A(1),
    .WRITE_DATA_WIDTH_A(19),
    .WRITE_MODE_A("no_change")
  ) eval_mem_inst (
    .clka(i_clk),
    .rsta(1'b0),
    .ena(eval_we || eval_re),
    .wea(eval_we),
    .addra(eval_addr),
    .dina(eval_wdata),
    .douta(eval_rdata)
  );

  always_comb begin
    token_re = 1'b0;
    token_raddr = 12'd0;
    eval_we = 1'b0;
    eval_re = 1'b0;
    eval_addr = 11'd0;
    eval_wdata = 19'd0;

    case (token_rdata[20:19])
      OP_ADD: calc_value = {19'd0, left_value} + {19'd0, eval_rdata};
      OP_SUB: calc_value = (left_value > eval_rdata) ? {19'd0, left_value - eval_rdata} : 38'd0;
      default: calc_value = {19'd0, left_value} * {19'd0, eval_rdata};
    endcase

    case (state)
      S_EVAL_REQ: begin
        if (!eval_error) begin
          if (pair_pending) begin
            eval_we = (eval_ptr < MAX_OPERANDS[11:0]);
            eval_addr = eval_ptr[10:0];
            eval_wdata = pair_value;
          end else if (token_index != 13'd0) begin
            token_re = 1'b1;
            token_raddr = token_index[11:0] - 12'd1;
          end else if (eval_ptr == 12'd1) begin
            eval_re = 1'b1;
            eval_addr = 11'd0;
          end
        end
      end
      S_EVAL_ACT: begin
        case (token_rdata[22:21])
          TOK_OPERAND: begin
            eval_we = (eval_ptr < MAX_OPERANDS[11:0]);
            eval_addr = eval_ptr[10:0];
            eval_wdata = token_rdata[18:0];
          end
          TOK_OP, TOK_PAIR: begin
            eval_re = (eval_ptr >= 12'd2);
            eval_addr = eval_ptr[10:0] - 11'd1;
          end
          default: begin
          end
        endcase
      end
      S_EVAL_RIGHT: begin
        eval_re = 1'b1;
        eval_addr = eval_ptr[10:0] - 11'd2;
      end
      S_EVAL_COMPUTE: begin
        eval_we = (calc_value != 38'd0 && calc_value <= {6'd0, MAX_VALUE});
        eval_addr = eval_ptr[10:0] - 11'd2;
        eval_wdata = calc_value[18:0];
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge i_clk) begin
    logic [19:0] digit;
    logic [2:0]  op;
    logic [31:0] next_num;
    logic [48:0] chunk;

    if (i_rst) begin
      state <= S_INPUT;
      finish_pending <= 1'b0;
      num_active <= 1'b0;
      num_value <= 19'd0;
      prev_value <= 19'd0;
      parse_error <= 1'b0;
      token_count <= 13'd0;
      token_index <= 13'd0;
      eval_ptr <= 12'd0;
      pair_pending <= 1'b0;
      pair_value <= 19'd0;
      left_value <= 19'd0;
      eval_error <= 1'b0;
      output_error <= 1'b0;
      output_remaining <= 32'd0;
      output_pending <= 1'b0;
      output_pending_char <= 8'd0;
      error_index <= 3'd0;
      o_valid <= 1'b0;
      o_last <= 1'b0;
      o_data <= {TASK_OUTPUT_WIDTH{1'b0}};
    end else begin
      o_valid <= 1'b0;
      o_last <= 1'b0;

      case (state)
        S_INPUT: begin
          if (finish_pending) begin
            finish_pending <= 1'b0;
            token_index <= token_count;
            eval_ptr <= 12'd0;
            pair_pending <= 1'b0;
            eval_error <= 1'b0;
            error_index <= 3'd0;
            output_pending <= 1'b0;
            if (parse_error || token_count == 13'd0) begin
              output_error <= 1'b1;
              state <= S_OUTPUT;
            end else begin
              output_error <= 1'b0;
              state <= S_EVAL_REQ;
            end
          end else if (i_valid && !parse_error) begin
            op = operator_code(i_data);
            if (i_data == 8'h20) begin
              if (num_active) begin
                if (token_count < MAX_TOKENS[12:0]) begin
                  token_mem[token_count] <= operand_token(num_value);
                  token_count <= token_count + 13'd1;
                end else begin
                  parse_error <= 1'b1;
                end
                num_active <= 1'b0;
              end
            end else if (op[2]) begin
              if (num_active) begin
                if (token_count < MAX_TOKENS[12:0]) begin
                  token_mem[token_count] <= pair_token(op[1:0], num_value);
                  token_count <= token_count + 13'd1;
                end else begin
                  parse_error <= 1'b1;
                end
                num_active <= 1'b0;
              end else begin
                if (token_count < MAX_TOKENS[12:0]) begin
                  token_mem[token_count] <= operator_token(op[1:0]);
                  token_count <= token_count + 13'd1;
                end else begin
                  parse_error <= 1'b1;
                end
              end
            end else begin
              digit = roman_digit(i_data);
              if (!digit[19]) begin
                parse_error <= 1'b1;
              end else begin
                next_num = num_active ? {13'd0, num_value} : 32'd0;
                if (num_active && digit[18:0] > prev_value)
                  next_num = next_num - {13'd0, prev_value} - {13'd0, prev_value} + {13'd0, digit[18:0]};
                else
                  next_num = next_num + {13'd0, digit[18:0]};

                if (next_num == 32'd0 || next_num > MAX_VALUE)
                  parse_error <= 1'b1;
                else if (i_last) begin
                  if (token_count < MAX_TOKENS[12:0]) begin
                    token_mem[token_count] <= operand_token(next_num[18:0]);
                    token_count <= token_count + 13'd1;
                  end else begin
                    parse_error <= 1'b1;
                  end
                  num_active <= 1'b0;
                end else begin
                  num_active <= 1'b1;
                  num_value <= next_num[18:0];
                  prev_value <= digit[18:0];
                end
              end
            end
          end

          if (i_valid && i_last)
            finish_pending <= 1'b1;
        end

        S_EVAL_REQ: begin
          if (eval_error) begin
            output_error <= 1'b1;
            error_index <= 3'd0;
            state <= S_OUTPUT;
          end else if (pair_pending) begin
            if (eval_ptr < MAX_OPERANDS[11:0]) begin
              eval_ptr <= eval_ptr + 12'd1;
              pair_pending <= 1'b0;
            end else begin
              eval_error <= 1'b1;
            end
          end else if (token_index != 13'd0) begin
            token_index <= token_index - 13'd1;
            state <= S_EVAL_ACT;
          end else if (eval_ptr == 12'd1) begin
            state <= S_EVAL_RESULT;
          end else begin
            output_error <= 1'b1;
            error_index <= 3'd0;
            state <= S_OUTPUT;
          end
        end

        S_EVAL_ACT: begin
          case (token_rdata[22:21])
            TOK_OPERAND: begin
              if (eval_ptr < MAX_OPERANDS[11:0]) begin
                eval_ptr <= eval_ptr + 12'd1;
                state <= S_EVAL_REQ;
              end else begin
                eval_error <= 1'b1;
                state <= S_EVAL_REQ;
              end
            end
            TOK_OP: begin
              if (eval_ptr >= 12'd2)
                state <= S_EVAL_RIGHT;
              else begin
                eval_error <= 1'b1;
                state <= S_EVAL_REQ;
              end
            end
            TOK_PAIR: begin
              pair_pending <= 1'b1;
              pair_value <= token_rdata[18:0];
              if (eval_ptr >= 12'd2)
                state <= S_EVAL_RIGHT;
              else begin
                eval_error <= 1'b1;
                state <= S_EVAL_REQ;
              end
            end
            default: begin
              eval_error <= 1'b1;
              state <= S_EVAL_REQ;
            end
          endcase
        end

        S_EVAL_RIGHT: begin
          left_value <= eval_rdata;
          state <= S_EVAL_COMPUTE;
        end

        S_EVAL_COMPUTE: begin
          if (calc_value == 38'd0 || calc_value > {6'd0, MAX_VALUE}) begin
            eval_error <= 1'b1;
          end else begin
            eval_ptr <= eval_ptr - 12'd1;
          end
          state <= S_EVAL_REQ;
        end

        S_EVAL_RESULT: begin
          output_remaining <= {13'd0, eval_rdata};
          output_pending <= 1'b0;
          output_error <= 1'b0;
          state <= S_OUTPUT;
        end

        S_OUTPUT: begin
          if (output_error) begin
            o_data <= error_char(error_index);
            o_valid <= 1'b1;
            o_last <= (error_index == 3'd4);
            if (error_index == 3'd4)
              state <= S_DONE;
            else
              error_index <= error_index + 3'd1;
          end else if (output_pending) begin
            o_data <= output_pending_char;
            o_valid <= 1'b1;
            o_last <= (output_remaining == 32'd0);
            output_pending <= 1'b0;
            if (output_remaining == 32'd0)
              state <= S_DONE;
          end else begin
            chunk = roman_chunk(output_remaining);
            o_data <= chunk[48:41];
            o_valid <= 1'b1;
            output_remaining <= output_remaining - chunk[31:0];
            if (chunk[32]) begin
              output_pending_char <= chunk[40:33];
              output_pending <= 1'b1;
            end else if (output_remaining == chunk[31:0]) begin
              o_last <= 1'b1;
              state <= S_DONE;
            end
          end
        end

        default: begin
          state <= S_INPUT;
          finish_pending <= 1'b0;
          num_active <= 1'b0;
          num_value <= 19'd0;
          prev_value <= 19'd0;
          parse_error <= 1'b0;
          token_count <= 13'd0;
          token_index <= 13'd0;
          eval_ptr <= 12'd0;
          pair_pending <= 1'b0;
          eval_error <= 1'b0;
          output_error <= 1'b0;
          output_remaining <= 32'd0;
          output_pending <= 1'b0;
          error_index <= 3'd0;
        end
      endcase
    end
  end

endmodule
