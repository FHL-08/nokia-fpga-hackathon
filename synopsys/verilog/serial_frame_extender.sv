// File: serial_frame_extender.sv
// RX: in_clk domain (data sampled on the true in_clk rising edge).
// TX: clk64 domain; out_clk toggles every ~64/17 clk64 -> 8.5 MHz,
//     so one 136-bit extended frame occupies exactly one 128-bit
//     input frame period (1024 clk64 cycles), keeping streams gap-free.

module serial_frame_extender #(
  parameter int unsigned FRAME_START_MSB_FIRST = 8'h4E,  // 0100_1110
  parameter int unsigned START_LSBF            = 8'h72   // 0111_0010 (0x4E LSB-first)
) (
  input  logic clk64,      // 64 MHz system clock (synchronous to in_clk)
  input  logic rst_n,
  input  logic in_clk,     // ~8 MHz, free-running, 50% +/-10%
  input  logic in_data,    // sampled on rising edge of in_clk
  output logic out_clk,    // derived clock, free-running
  output logic out_data    // changes on falling edge of out_clk; sample on rising
);

  // ================= receive side : in_clk domain =================
  logic         locked;
  logic [7:0]   win8;        // last 8 received bits, bit[0] = newest
  logic [6:0]   rx_pos;      // bit position within frame, 0..127
  logic [127:0] rx_shift;    // after full frame, [127] = first received bit
  logic [6:0]   cur_pos;     // index (0..119) of the '1' payload bit
  logic [135:0] done_word;   // packed output frame: {frame[127:0], ~pos[7:0]}
  logic         tag;         // toggles once per completed frame

  wire [7:0] win8_next = {win8[6:0], in_data};
  wire [6:0] pos_now   = rx_pos - 7'd8;

  always_ff @(posedge in_clk or negedge rst_n) begin
    if (!rst_n) begin
      locked    <= 1'b0;
      win8      <= 8'd0;
      rx_pos    <= 7'd0;
      rx_shift  <= 128'd0;
      cur_pos   <= 7'd0;
      done_word <= 136'd0;
      tag       <= 1'b0;
    end else begin
      win8     <= win8_next;
      rx_shift <= {rx_shift[126:0], in_data};
      if (!locked) begin
        if (win8_next == FRAME_START_MSB_FIRST[7:0]) begin
          locked <= 1'b1;
          rx_pos <= 7'd8;
        end
      end else begin
        // re-verify start pattern once per frame; drop lock on mismatch
        if (rx_pos == 7'd7 && win8_next != FRAME_START_MSB_FIRST[7:0])
          locked <= 1'b0;
        if (rx_pos >= 7'd8 && in_data)
          cur_pos <= pos_now;
        if (rx_pos == 7'd127) begin
          rx_pos    <= 7'd0;
          tag       <= ~tag;
          done_word <= {rx_shift[126:0], in_data,
                        {1'b0, (in_data ? pos_now : cur_pos)}};
        end else begin
          rx_pos <= rx_pos + 7'd1;
        end
      end
    end
  end

  // ================= frame handshake : in_clk -> clk64 =================
  logic [2:0] tag_sync;
  always_ff @(posedge clk64 or negedge rst_n) begin
    if (!rst_n) tag_sync <= 3'b000;
    else        tag_sync <= {tag_sync[1:0], tag};
  end
  wire new_frame = tag_sync[2] ^ tag_sync[1];

  // ================= transmit side : clk64 domain =================
  // Half-period accumulator: 17/64 toggles per clk64 -> 272 toggles/1024 clk
  // -> 136 full out_clk periods per input frame.
  logic [6:0]   acc;
  logic         oclk;
  logic         tx_en;      // transmission started (first frame anchored)
  logic         arm;        // force frame start at next falling edge
  logic [7:0]   tx_bit;     // 0..135
  logic [135:0] tx_word;    // [135] shifts out first
  logic         odata;

  wire [6:0] acc_sum  = acc + 7'd17;
  wire       htick    = (acc_sum >= 7'd64);
  wire [6:0] acc_next = htick ? (acc_sum - 7'd64) : acc_sum;

  always_ff @(posedge clk64 or negedge rst_n) begin
    if (!rst_n) begin
      acc     <= 7'd0;
      oclk    <= 1'b0;
      tx_en   <= 1'b0;
      arm     <= 1'b0;
      tx_bit  <= 8'd0;
      tx_word <= 136'd0;
      odata   <= 1'b0;
    end else begin
      acc <= acc_next;
      if (new_frame && !tx_en)
        arm <= 1'b1;
      if (htick) begin
        oclk <= ~oclk;
        if (oclk) begin                 // falling edge -> update data
          if (arm) begin
            arm     <= 1'b0;
            tx_en   <= 1'b1;
            tx_bit  <= 8'd0;
            tx_word <= {done_word[134:0], 1'b0};
            odata   <= done_word[135];
          end else if (tx_en) begin
            if (tx_bit == 8'd135) begin
              tx_bit  <= 8'd0;
              tx_word <= {done_word[134:0], 1'b0};
              odata   <= done_word[135];
            end else begin
              tx_bit  <= tx_bit + 8'd1;
              tx_word <= {tx_word[134:0], 1'b0};
              odata   <= tx_word[135];
            end
          end
        end
      end
    end
  end

  assign out_clk  = oclk;
  assign out_data = odata;

endmodule
