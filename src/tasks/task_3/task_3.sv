`timescale 1ns / 1ps

module task_3
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

  localparam int MAX_PACKET_BYTES = 4096;

  typedef enum logic [3:0] {
    ST_IDLE,
    ST_CAPTURE,
    ST_DECODE,
    ST_DECODE_FLUSH_SYMBOL,
    ST_DECODE_FLUSH_CHAR,
    ST_OUTPUT_READ,
    ST_OUTPUT_SEND,
    ST_ENCODE_FIND,
    ST_ENCODE_READ,
    ST_ENCODE_CHAR,
    ST_ENCODE_GAP,
    ST_ENCODE_SYMBOL,
    ST_ENCODE_SEPARATOR,
    ST_FLUSH_MORSE
  } state_t;

  state_t state;

  (* ram_style = "block" *) logic [7:0] packet_mem [0:MAX_PACKET_BYTES-1];
  logic        mem_wen;
  logic [11:0] mem_waddr;
  logic [7:0]  mem_wdata;
  logic        mem_ren;
  logic [11:0] mem_raddr;
  logic [7:0]  mem_rdata;

  logic [12:0] input_len;
  logic        input_is_morse;

  logic [11:0] decode_addr;
  logic [12:0] decode_consume;
  logic        decode_rdata_valid;
  logic [12:0] decode_out_len;
  logic [2:0]  one_count;
  logic [3:0]  zero_count;
  logic [2:0]  symbol_len;
  logic [5:0]  symbol_code;
  logic        pending_word_gap;

  logic [12:0] output_idx;
  logic [12:0] output_len;

  logic [12:0] encode_idx;
  logic        encode_seen_char;
  logic        encode_seen_space;
  logic [2:0]  encode_gap_len;
  logic [2:0]  encode_gap_idx;
  logic [2:0]  encode_symbol_len;
  logic [2:0]  encode_symbol_idx;
  logic [5:0]  encode_symbol_code;
  logic [1:0]  encode_element_len;
  logic [1:0]  encode_element_idx;

  logic        morse_pending_valid;
  logic        morse_pending_bit;
  logic [12:0] morse_output_count;

  wire capture_write;
  wire decode_space_write;
  wire decode_char_write;
  wire decode_flush_write;
  wire [8:0] current_morse_encoding;

  assign capture_write = i_valid &&
                         (((state == ST_IDLE) && i_first) || (state == ST_CAPTURE));
  assign decode_space_write = (state == ST_DECODE) && decode_rdata_valid &&
                              mem_rdata[0] && pending_word_gap &&
                              (decode_out_len < MAX_PACKET_BYTES);
  assign decode_char_write = (state == ST_DECODE) && decode_rdata_valid &&
                             !mem_rdata[0] && !pending_word_gap &&
                             (zero_count == 4'd2) && (symbol_len != 0) &&
                             (decode_out_len < MAX_PACKET_BYTES);
  assign decode_flush_write = (state == ST_DECODE_FLUSH_CHAR) &&
                              (symbol_len != 0) &&
                              (decode_out_len < MAX_PACKET_BYTES);
  assign mem_wen = capture_write || decode_space_write || decode_char_write ||
                   decode_flush_write;
  assign mem_waddr = capture_write ?
                     ((state == ST_IDLE) ? 12'd0 : input_len[11:0]) :
                     decode_out_len[11:0];
  assign mem_wdata = capture_write ? i_data :
                     (decode_space_write ? 8'h20 :
                      decode_morse(symbol_len, symbol_code));
  assign current_morse_encoding = encode_morse(mem_rdata);

  always_comb begin
    mem_ren = 1'b0;
    mem_raddr = 12'd0;

    case (state)
      ST_DECODE: begin
        mem_ren = decode_addr < input_len;
        mem_raddr = decode_addr;
      end
      ST_ENCODE_READ: begin
        mem_ren = 1'b1;
        mem_raddr = encode_idx[11:0];
      end
      ST_OUTPUT_READ: begin
        mem_ren = 1'b1;
        mem_raddr = output_idx[11:0];
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge i_clk) begin
    if (mem_wen)
      packet_mem[mem_waddr] <= mem_wdata;
    if (mem_ren)
      mem_rdata <= packet_mem[mem_raddr];
  end

  function automatic logic [8:0] encode_morse(input logic [7:0] ascii);
    begin
      case (ascii)
        "A", "a": encode_morse = {3'd2, 6'b000010};
        "B", "b": encode_morse = {3'd4, 6'b000001};
        "C", "c": encode_morse = {3'd4, 6'b000101};
        "D", "d": encode_morse = {3'd3, 6'b000001};
        "E", "e": encode_morse = {3'd1, 6'b000000};
        "F", "f": encode_morse = {3'd4, 6'b000100};
        "G", "g": encode_morse = {3'd3, 6'b000011};
        "H", "h": encode_morse = {3'd4, 6'b000000};
        "I", "i": encode_morse = {3'd2, 6'b000000};
        "J", "j": encode_morse = {3'd4, 6'b000111};
        "K", "k": encode_morse = {3'd3, 6'b000101};
        "L", "l": encode_morse = {3'd4, 6'b000010};
        "M", "m": encode_morse = {3'd2, 6'b000011};
        "N", "n": encode_morse = {3'd2, 6'b000001};
        "O", "o": encode_morse = {3'd3, 6'b000111};
        "P", "p": encode_morse = {3'd4, 6'b000110};
        "Q", "q": encode_morse = {3'd4, 6'b001011};
        "R", "r": encode_morse = {3'd3, 6'b000010};
        "S", "s": encode_morse = {3'd3, 6'b000000};
        "T", "t": encode_morse = {3'd1, 6'b000001};
        "U", "u": encode_morse = {3'd3, 6'b000100};
        "V", "v": encode_morse = {3'd4, 6'b001000};
        "W", "w": encode_morse = {3'd3, 6'b000110};
        "X", "x": encode_morse = {3'd4, 6'b001001};
        "Y", "y": encode_morse = {3'd4, 6'b001101};
        "Z", "z": encode_morse = {3'd4, 6'b000011};
        "0":    encode_morse = {3'd5, 6'b011111};
        "1":    encode_morse = {3'd5, 6'b011110};
        "2":    encode_morse = {3'd5, 6'b011100};
        "3":    encode_morse = {3'd5, 6'b011000};
        "4":    encode_morse = {3'd5, 6'b010000};
        "5":    encode_morse = {3'd5, 6'b000000};
        "6":    encode_morse = {3'd5, 6'b000001};
        "7":    encode_morse = {3'd5, 6'b000011};
        "8":    encode_morse = {3'd5, 6'b000111};
        "9":    encode_morse = {3'd5, 6'b001111};
        ".":    encode_morse = {3'd6, 6'b101010};
        ",":    encode_morse = {3'd6, 6'b110011};
        "+":    encode_morse = {3'd5, 6'b001010};
        "-":    encode_morse = {3'd6, 6'b100001};
        "?":    encode_morse = {3'd6, 6'b001100};
        "_":    encode_morse = {3'd6, 6'b101100};
        "@":    encode_morse = {3'd6, 6'b010110};
        default: encode_morse = 9'd0;
      endcase
    end
  endfunction

  function automatic logic [7:0] decode_morse(input logic [2:0] len,
                                               input logic [5:0] code);
    begin
      case ({len, code})
        {3'd2, 6'b000010}: decode_morse = "A";
        {3'd4, 6'b000001}: decode_morse = "B";
        {3'd4, 6'b000101}: decode_morse = "C";
        {3'd3, 6'b000001}: decode_morse = "D";
        {3'd1, 6'b000000}: decode_morse = "E";
        {3'd4, 6'b000100}: decode_morse = "F";
        {3'd3, 6'b000011}: decode_morse = "G";
        {3'd4, 6'b000000}: decode_morse = "H";
        {3'd2, 6'b000000}: decode_morse = "I";
        {3'd4, 6'b000111}: decode_morse = "J";
        {3'd3, 6'b000101}: decode_morse = "K";
        {3'd4, 6'b000010}: decode_morse = "L";
        {3'd2, 6'b000011}: decode_morse = "M";
        {3'd2, 6'b000001}: decode_morse = "N";
        {3'd3, 6'b000111}: decode_morse = "O";
        {3'd4, 6'b000110}: decode_morse = "P";
        {3'd4, 6'b001011}: decode_morse = "Q";
        {3'd3, 6'b000010}: decode_morse = "R";
        {3'd3, 6'b000000}: decode_morse = "S";
        {3'd1, 6'b000001}: decode_morse = "T";
        {3'd3, 6'b000100}: decode_morse = "U";
        {3'd4, 6'b001000}: decode_morse = "V";
        {3'd3, 6'b000110}: decode_morse = "W";
        {3'd4, 6'b001001}: decode_morse = "X";
        {3'd4, 6'b001101}: decode_morse = "Y";
        {3'd4, 6'b000011}: decode_morse = "Z";
        {3'd5, 6'b011111}: decode_morse = "0";
        {3'd5, 6'b011110}: decode_morse = "1";
        {3'd5, 6'b011100}: decode_morse = "2";
        {3'd5, 6'b011000}: decode_morse = "3";
        {3'd5, 6'b010000}: decode_morse = "4";
        {3'd5, 6'b000000}: decode_morse = "5";
        {3'd5, 6'b000001}: decode_morse = "6";
        {3'd5, 6'b000011}: decode_morse = "7";
        {3'd5, 6'b000111}: decode_morse = "8";
        {3'd5, 6'b001111}: decode_morse = "9";
        {3'd6, 6'b101010}: decode_morse = ".";
        {3'd6, 6'b110011}: decode_morse = ",";
        {3'd5, 6'b001010}: decode_morse = "+";
        {3'd6, 6'b100001}: decode_morse = "-";
        {3'd6, 6'b001100}: decode_morse = "?";
        {3'd6, 6'b101100}: decode_morse = "_";
        {3'd6, 6'b010110}: decode_morse = "@";
        default: decode_morse = "?";
      endcase
    end
  endfunction

  task automatic emit_byte(input logic [TASK_OUTPUT_WIDTH-1:0] value,
                           input logic last);
    begin
      o_valid <= 1'b1;
      o_data  <= value;
      o_last  <= last;
    end
  endtask

  task automatic push_morse_bit(input logic bit_value);
    begin
      if (morse_pending_valid) begin
        if (morse_output_count == 0)
          emit_byte(TASK_OUTPUT_WIDTH'(8'h80 | morse_pending_bit), 1'b0);
        else
          emit_byte(TASK_OUTPUT_WIDTH'(morse_pending_bit), 1'b0);
        morse_output_count <= morse_output_count + 1'b1;
      end
      morse_pending_valid <= 1'b1;
      morse_pending_bit   <= bit_value;
    end
  endtask

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      state               <= ST_IDLE;
      input_len           <= '0;
      input_is_morse      <= 1'b0;
      decode_addr         <= '0;
      decode_consume      <= '0;
      decode_rdata_valid  <= 1'b0;
      decode_out_len      <= '0;
      one_count           <= '0;
      zero_count          <= '0;
      symbol_len          <= '0;
      symbol_code         <= '0;
      pending_word_gap    <= 1'b0;
      output_idx          <= '0;
      output_len          <= '0;
      encode_idx          <= '0;
      encode_seen_char    <= 1'b0;
      encode_seen_space   <= 1'b0;
      encode_gap_len      <= '0;
      encode_gap_idx      <= '0;
      encode_symbol_len   <= '0;
      encode_symbol_idx   <= '0;
      encode_symbol_code  <= '0;
      encode_element_len  <= '0;
      encode_element_idx  <= '0;
      morse_pending_valid <= 1'b0;
      morse_pending_bit   <= 1'b0;
      morse_output_count  <= '0;
      o_valid             <= 1'b0;
      o_last              <= 1'b0;
      o_data              <= '0;
    end else begin
      o_valid <= 1'b0;
      o_last  <= 1'b0;
      o_data  <= '0;

      case (state)
        ST_IDLE: begin
          if (i_valid && i_first) begin
            input_len           <= 13'd1;
            input_is_morse      <= i_data[7];
            decode_addr         <= '0;
            decode_consume      <= '0;
            decode_rdata_valid  <= 1'b0;
            decode_out_len      <= '0;
            one_count           <= '0;
            zero_count          <= '0;
            symbol_len          <= '0;
            symbol_code         <= '0;
            pending_word_gap    <= 1'b0;
            output_idx          <= '0;
            output_len          <= '0;
            encode_idx          <= '0;
            encode_seen_char    <= 1'b0;
            encode_seen_space   <= 1'b0;
            encode_gap_idx      <= '0;
            encode_symbol_idx   <= '0;
            encode_element_idx  <= '0;
            morse_pending_valid <= 1'b0;
            morse_output_count  <= '0;

            if (i_last)
              state <= i_data[7] ? ST_DECODE : ST_ENCODE_FIND;
            else
              state <= ST_CAPTURE;
          end
        end

        ST_CAPTURE: begin
          if (i_valid) begin
            if (input_len < MAX_PACKET_BYTES)
              input_len <= input_len + 1'b1;

            if (i_last)
              state <= input_is_morse ? ST_DECODE : ST_ENCODE_FIND;
          end
        end

        ST_DECODE: begin
          if (decode_addr < input_len)
            decode_addr <= decode_addr + 1'b1;
          decode_rdata_valid <= decode_addr < input_len;

          if (decode_rdata_valid) begin
            if (mem_rdata[0]) begin
              if (pending_word_gap && (decode_out_len < MAX_PACKET_BYTES))
                decode_out_len <= decode_out_len + 1'b1;
              pending_word_gap <= 1'b0;
              zero_count <= '0;
              if (one_count < 3'd3)
                one_count <= one_count + 1'b1;
            end else begin
              if (one_count != 0) begin
                if (symbol_len < 3'd6) begin
                  symbol_code[symbol_len] <= one_count >= 3'd3;
                  symbol_len <= symbol_len + 1'b1;
                end
                one_count <= '0;
              end

              if (!pending_word_gap && (zero_count < 4'd7))
                zero_count <= zero_count + 1'b1;

              if (!pending_word_gap && (zero_count == 4'd2) &&
                  (symbol_len != 0) && (decode_out_len < MAX_PACKET_BYTES)) begin
                decode_out_len <= decode_out_len + 1'b1;
                symbol_len <= '0;
                symbol_code <= '0;
              end

              if (!pending_word_gap && (zero_count == 4'd6) &&
                  (decode_out_len != 0))
                pending_word_gap <= 1'b1;
            end

            if (decode_consume == input_len - 1'b1)
              state <= ST_DECODE_FLUSH_SYMBOL;
            else
              decode_consume <= decode_consume + 1'b1;
          end
        end

        ST_DECODE_FLUSH_SYMBOL: begin
          if ((one_count != 0) && (symbol_len < 3'd6)) begin
            symbol_code[symbol_len] <= one_count >= 3'd3;
            symbol_len <= symbol_len + 1'b1;
            one_count <= '0;
          end
          state <= ST_DECODE_FLUSH_CHAR;
        end

        ST_DECODE_FLUSH_CHAR: begin
          output_idx <= '0;
          if ((symbol_len != 0) && (decode_out_len < MAX_PACKET_BYTES))
            output_len <= decode_out_len + 1'b1;
          else
            output_len <= decode_out_len;
          symbol_len <= '0;
          symbol_code <= '0;

          if (((symbol_len != 0) && (decode_out_len < MAX_PACKET_BYTES)) ||
              (decode_out_len != 0))
            state <= ST_OUTPUT_READ;
          else
            state <= ST_IDLE;
        end

        ST_OUTPUT_READ: begin
          state <= ST_OUTPUT_SEND;
        end

        ST_OUTPUT_SEND: begin
          emit_byte(mem_rdata, output_idx == output_len - 1'b1);
          if (output_idx == output_len - 1'b1) begin
            state <= ST_IDLE;
          end else begin
            output_idx <= output_idx + 1'b1;
            state <= ST_OUTPUT_READ;
          end
        end

        ST_ENCODE_FIND: begin
          if (encode_idx >= input_len)
            state <= ST_FLUSH_MORSE;
          else
            state <= ST_ENCODE_READ;
        end

        ST_ENCODE_READ: begin
          state <= ST_ENCODE_CHAR;
        end

        ST_ENCODE_CHAR: begin
          if (mem_rdata == 8'h20) begin
            encode_seen_space <= 1'b1;
            encode_idx <= encode_idx + 1'b1;
            state <= ST_ENCODE_FIND;
          end else if (current_morse_encoding[8:6] != 0) begin
            encode_symbol_len  <= current_morse_encoding[8:6];
            encode_symbol_code <= current_morse_encoding[5:0];
            encode_symbol_idx  <= '0;
            encode_element_idx <= '0;
            encode_element_len <= current_morse_encoding[0] ? 2'd3 : 2'd1;
            encode_idx <= encode_idx + 1'b1;

            if (encode_seen_char) begin
              encode_gap_len <= encode_seen_space ? 3'd7 : 3'd3;
              encode_gap_idx <= '0;
              state <= ST_ENCODE_GAP;
            end else begin
              state <= ST_ENCODE_SYMBOL;
            end

            encode_seen_char <= 1'b1;
            encode_seen_space <= 1'b0;
          end else begin
            encode_idx <= encode_idx + 1'b1;
            state <= ST_ENCODE_FIND;
          end
        end

        ST_ENCODE_GAP: begin
          push_morse_bit(1'b0);
          if (encode_gap_idx == encode_gap_len - 1'b1) begin
            encode_gap_idx <= '0;
            state <= ST_ENCODE_SYMBOL;
          end else begin
            encode_gap_idx <= encode_gap_idx + 1'b1;
          end
        end

        ST_ENCODE_SYMBOL: begin
          push_morse_bit(1'b1);
          if (encode_element_idx == encode_element_len - 1'b1) begin
            encode_element_idx <= '0;
            if (encode_symbol_idx == encode_symbol_len - 1'b1) begin
              state <= ST_ENCODE_FIND;
            end else begin
              encode_symbol_idx <= encode_symbol_idx + 1'b1;
              state <= ST_ENCODE_SEPARATOR;
            end
          end else begin
            encode_element_idx <= encode_element_idx + 1'b1;
          end
        end

        ST_ENCODE_SEPARATOR: begin
          push_morse_bit(1'b0);
          encode_element_len <= encode_symbol_code[encode_symbol_idx] ? 2'd3 : 2'd1;
          state <= ST_ENCODE_SYMBOL;
        end

        ST_FLUSH_MORSE: begin
          if (morse_pending_valid) begin
            if (morse_output_count == 0)
              emit_byte(TASK_OUTPUT_WIDTH'(8'h80 | morse_pending_bit), 1'b1);
            else
              emit_byte(TASK_OUTPUT_WIDTH'(morse_pending_bit), 1'b1);
            morse_pending_valid <= 1'b0;
          end
          state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule
