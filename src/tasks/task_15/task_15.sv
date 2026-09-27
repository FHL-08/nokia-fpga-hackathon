`timescale 1ns / 1ps

module task_15
#(
  parameter int TASK_INPUT_WIDTH  = 8,
  parameter int TASK_OUTPUT_WIDTH = 8
)(
  input  wire                         i_clk,
  input  wire                         i_rst,

  input  wire                         i_valid,
  input  wire                         i_first,
  input  wire                         i_last,
  input  wire [TASK_INPUT_WIDTH-1:0]  i_data,

  output logic                         o_valid,
  output logic                         o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  // The packet bounds imply k <= 8, m <= 13, and n <= 17.
  localparam int MAX_K    = 8;
  localparam int MAX_ROWS = 13;
  localparam int MAX_COLS = 17;

  typedef enum logic [2:0] {
    WAIT_M,
    GET_N,
    GET_H,
    START_OUTPUT,
    SEND_SYSTEMATIC,
    CHECK_GENERAL,
    SEND_GENERAL
  } state_t;

  state_t state;

  logic [7:0] m_rows;
  logic [7:0] n_cols;
  logic [7:0] k_cols;
  logic [7:0] input_row;
  logic [7:0] input_col;
  logic [MAX_K-1:0] a_rows [0:MAX_ROWS-1];
  logic [MAX_COLS-1:0] h_rows [0:MAX_ROWS-1];
  logic systematic_matrix;

  logic [MAX_K-1:0] message_index;
  logic [MAX_COLS-1:0] candidate_index;
  logic [7:0]  output_col;

  logic next_output_bit;
  logic final_message;
  logic candidate_is_codeword;
  integer bit_index;
  integer row_index;
  integer syndrome_row;

  always_comb begin
    next_output_bit = 1'b0;
    final_message   = 1'b1;
    candidate_is_codeword = 1'b1;

    if (output_col < k_cols) begin
      // Messages are enumerated 00...00, 00...01, ... and emitted MSB first.
      next_output_bit = message_index[k_cols - 1'b1 - output_col];
    end else begin
      // H*c^T = A*u^T + p = 0, hence p = A*u^T over GF(2).
      next_output_bit = ^(a_rows[output_col - k_cols] & message_index);
    end

    for (bit_index = 0; bit_index < MAX_K; bit_index = bit_index + 1) begin
      if (bit_index < k_cols)
        final_message = final_message & message_index[bit_index];
    end

    for (syndrome_row = 0; syndrome_row < MAX_ROWS; syndrome_row = syndrome_row + 1) begin
      if (syndrome_row < m_rows)
        candidate_is_codeword = candidate_is_codeword &
                                ~^(h_rows[syndrome_row] & candidate_index);
    end
  end

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      state         <= WAIT_M;
      m_rows        <= '0;
      n_cols        <= '0;
      k_cols        <= '0;
      input_row     <= '0;
      input_col     <= '0;
      message_index <= '0;
      candidate_index <= '0;
      output_col    <= '0;
      systematic_matrix <= 1'b1;
      o_data        <= '0;
      o_valid       <= 1'b0;
      o_last        <= 1'b0;
      for (row_index = 0; row_index < MAX_ROWS; row_index = row_index + 1) begin
        a_rows[row_index] <= '0;
        h_rows[row_index] <= '0;
      end
    end else begin
      o_valid <= 1'b0;
      o_last  <= 1'b0;

      // i_first is also a clean resynchronisation point if a new packet starts.
      if (i_valid && i_first) begin
        m_rows        <= i_data;
        state         <= GET_N;
        input_row     <= '0;
        input_col     <= '0;
        message_index <= '0;
        candidate_index <= '0;
        output_col    <= '0;
        systematic_matrix <= 1'b1;
        for (row_index = 0; row_index < MAX_ROWS; row_index = row_index + 1) begin
          a_rows[row_index] <= '0;
          h_rows[row_index] <= '0;
        end
      end else begin
        case (state)
          WAIT_M: begin
            if (i_valid) begin
              m_rows        <= i_data;
              state         <= GET_N;
              input_row     <= '0;
              input_col     <= '0;
              systematic_matrix <= 1'b1;
              for (row_index = 0; row_index < MAX_ROWS; row_index = row_index + 1) begin
                a_rows[row_index] <= '0;
                h_rows[row_index] <= '0;
              end
            end
          end

          GET_N: begin
            if (i_valid) begin
              n_cols        <= i_data;
              k_cols        <= i_data - m_rows;
              input_row     <= '0;
              input_col     <= '0;
              systematic_matrix <= 1'b1;
              state         <= GET_H;
            end
          end

          GET_H: begin
            if (i_valid) begin
              h_rows[input_row] <= {h_rows[input_row][MAX_COLS-2:0], i_data[0]};

              if (input_col < k_cols) begin
                a_rows[input_row] <= {a_rows[input_row][MAX_K-2:0], i_data[0]};
              end else if (i_data[0] != ((input_col - k_cols) == input_row)) begin
                systematic_matrix <= 1'b0;
              end

              if (input_col == n_cols - 1'b1) begin
                input_col <= '0;
                input_row <= input_row + 1'b1;
              end else begin
                input_col <= input_col + 1'b1;
              end

              if (i_last) begin
                message_index <= '0;
                candidate_index <= '0;
                output_col    <= '0;
                state         <= START_OUTPUT;
              end
            end
          end

          START_OUTPUT: begin
            message_index   <= '0;
            candidate_index <= '0;
            output_col      <= '0;
            if (systematic_matrix)
              state <= SEND_SYSTEMATIC;
            else
              state <= CHECK_GENERAL;
          end

          SEND_SYSTEMATIC: begin
            o_data  <= {{(TASK_OUTPUT_WIDTH-1){1'b0}}, next_output_bit};
            o_valid <= 1'b1;

            if (output_col == n_cols - 1'b1) begin
              output_col <= '0;

              if (final_message) begin
                o_last <= 1'b1;
                state  <= WAIT_M;
              end else begin
                message_index <= message_index + 1'b1;
              end
            end else begin
              output_col <= output_col + 1'b1;
            end
          end

          CHECK_GENERAL: begin
            if (candidate_is_codeword) begin
              output_col <= '0;
              state      <= SEND_GENERAL;
            end else begin
              candidate_index <= candidate_index + 1'b1;
            end
          end

          SEND_GENERAL: begin
            o_data  <= {{(TASK_OUTPUT_WIDTH-1){1'b0}},
                        candidate_index[n_cols - 1'b1 - output_col]};
            o_valid <= 1'b1;

            if (output_col == n_cols - 1'b1) begin
              output_col <= '0;

              if (final_message) begin
                o_last <= 1'b1;
                state  <= WAIT_M;
              end else begin
                message_index   <= message_index + 1'b1;
                candidate_index <= candidate_index + 1'b1;
                state           <= CHECK_GENERAL;
              end
            end else begin
              output_col <= output_col + 1'b1;
            end
          end

          default: state <= WAIT_M;
        endcase
      end
    end
  end

endmodule
