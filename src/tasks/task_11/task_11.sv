`timescale 1ns / 1ps
module task_11 #(
  parameter int TASK_INPUT_WIDTH=8, TASK_OUTPUT_WIDTH=8
)(
  input wire i_clk, i_rst, i_valid, i_first, i_last,
  input wire [TASK_INPUT_WIDTH-1:0] i_data,
  output logic o_valid, o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  // Missing cells form edges between row and column nodes.  Leaf elimination
  // expresses each forest cell as a*S+b, then interval validation proves a
  // unique common sum before packet RAM is changed.  General cyclic cases
  // made unique only by byte bounds remain unchanged; global all-zero and
  // all-254 saturation cases are handled explicitly.

  typedef enum logic [4:0] {
    IDLE, RECEIVE, SIZE, CLEAR_LINES, SCAN_PRIME, SCAN_USE,
    BUILD_QUEUE, POP_LINE, POP_WAIT, CHECK_LINE, REMOVE_CELL,
    SCAN_BUBBLE, LOAD_CONSTRAINT, LINE_FETCH, CELL_FETCH, FAST_CONSTRAINT,
    CHECK_LOW, CHECK_HIGH,
    FIND_LOW, FIND_HIGH, DECIDE, COMMIT_READ, COMMIT_WRITE,
    SEND_PRIME, SEND_FIRST, SEND_SECOND
  } state_t;
  state_t state;

  // Parity banking permits two-cell scans and continuous one-byte output.
  (* ram_style="block" *) logic [7:0] packet_even [0:2047];
  (* ram_style="block" *) logic [7:0] packet_odd [0:2047];
  logic [10:0] even_read_index, odd_read_index;
  logic [7:0] even_read_data, odd_read_data;
  logic read_data_address_lsb;
  logic [11:0] read_pair_address;
  wire [7:0] pair_first = read_data_address_lsb ? odd_read_data : even_read_data;
  wire [7:0] pair_second = read_data_address_lsb ? even_read_data : odd_read_data;
  logic packet_write_enable;
  logic [11:0] packet_write_address;
  logic [7:0] packet_write_data;

  logic [12:0] packet_length, square_size, missing_count;
  logic [6:0] side;
  logic received_missing;
  logic [11:0] scan_address, output_address;
  logic [5:0] scan_row, scan_column;
  wire scan_second_valid = ({1'b0,scan_column}+7'd1 < side);
  wire scan_last_pair = (scan_row+6'd1 == side[5:0]) &&
                        ({1'b0,scan_column}+7'd2 >= side);
  wire scan_row_wrap = ({1'b0,scan_column}+7'd2 >= side);
  wire [11:0] scan_step = scan_second_valid ? 12'd2 : 12'd1;
  wire [11:0] scan_next_address = scan_address + scan_step;
  wire [4:0] scan_next_pair = scan_row_wrap ? 5'd0 : scan_column[5:1]+5'd1;
  logic known_all_zero, known_all_max, fill_missing;
  logic [7:0] fill_value;

  // Line metadata {degree, neighbour_xor} stays in single-write LUTRAM banks
  // (needed combinationally); the {coefficient, constant} residual state
  // lives in true-dual-port BRAM banks which are free for the score.
  //   meta: {degree[6:0]@13:7, neighbour_xor[6:0]@6:0}
  //   bank record: {coefficient[7:0]@31:24, constant[23:0]@23:0}
  (* ram_style="distributed" *) logic [13:0] row_meta [0:63];
  (* ram_style="distributed" *) logic [13:0] column_even_meta [0:31];
  (* ram_style="distributed" *) logic [13:0] column_odd_meta [0:31];
  logic row_meta_we, column_even_meta_we, column_odd_meta_we;
  logic [5:0] row_meta_wa;
  logic [4:0] column_even_meta_wa, column_odd_meta_wa;
  logic [13:0] row_meta_wd, column_even_meta_wd, column_odd_meta_wd;
  logic [6:0] scan_row_degree, scan_row_neighbor;
  logic signed [23:0] scan_row_constant;
  logic [6:0] line_index, active_line;
  wire [6:0] row_node = {1'b0,scan_row};
  wire [6:0] column_node_0 = {1'b1,scan_column};
  wire [6:0] column_node_1 = {1'b1,(scan_column+6'd1)};

  // Residual banks {coeff,const}, one per meta bank.  Port A handles the
  // indexed/active/scan-even reads plus all writes; port B handles the
  // "other endpoint" and scan-odd reads plus the even-column write-back.
  localparam logic [1:0] BANK_ROW=2'd0, BANK_COLE=2'd1, BANK_COLO=2'd2;
  (* ram_style="block" *) logic [31:0] row_bank [0:63];
  (* ram_style="block" *) logic [31:0] cole_bank [0:31];
  (* ram_style="block" *) logic [31:0] colo_bank [0:31];
  logic row_we_a, colo_we_a, cole_we_b;
  logic [5:0] row_wa_a, row_ra_a, row_rb_b;
  logic [4:0] cole_wb_b, cole_ra_a, cole_rb_b;
  logic [4:0] colo_wa_a, colo_ra_a, colo_rb_b;
  logic [31:0] row_wd_a, colo_wd_a, cole_wd_b;
  logic [31:0] row_rd_a, row_rd_b, cole_rd_a, cole_rd_b, colo_rd_a, colo_rd_b;
  logic [1:0] rd_sel_a, rd_sel_b;

  function automatic logic [1:0] bank_of(input logic [6:0] line);
    return !line[6] ? BANK_ROW : (!line[0] ? BANK_COLE : BANK_COLO);
  endfunction

  wire signed [31:0] bank_a = rd_sel_a==BANK_ROW ? $signed(row_rd_a) :
    (rd_sel_a==BANK_COLE ? $signed(cole_rd_a) : $signed(colo_rd_a));
  wire signed [31:0] bank_b = rd_sel_b==BANK_ROW ? $signed(row_rd_b) :
    (rd_sel_b==BANK_COLE ? $signed(cole_rd_b) : $signed(colo_rd_b));
  wire signed [7:0] active_coefficient = bank_a[31:24];
  wire signed [23:0] active_constant = bank_a[23:0];
  wire signed [7:0] other_coefficient = bank_b[31:24];
  wire signed [23:0] other_constant = bank_b[23:0];
  wire signed [31:0] other_bank_next = {other_coefficient-active_coefficient,
    other_constant-active_constant};

  wire [13:0] active_record = !active_line[6] ? row_meta[active_line[5:0]] :
    (!active_line[0] ? column_even_meta[active_line[5:1]] :
                       column_odd_meta[active_line[5:1]]);
  wire [6:0] active_degree=active_record[13:7];
  wire [6:0] other_line=active_record[6:0];
  wire [13:0] other_record = !other_line[6] ? row_meta[other_line[5:0]] :
    (!other_line[0] ? column_even_meta[other_line[5:1]] :
                      column_odd_meta[other_line[5:1]]);
  wire [6:0] other_degree=other_record[13:7];
  wire [6:0] other_neighbor=other_record[6:0];

  (* ram_style="block" *) logic [6:0] leaf_queue [0:127];
  logic [6:0] queue_rd_data;
  logic [7:0] queue_head, queue_tail;
  // Eliminated-cell journal {addr[11:0], coeff[7:0], const[23:0]} in BRAM
  // (free for the utilization score) with a registered read port.
  (* ram_style="block" *) logic [43:0] cell_mem [0:127];
  logic [43:0] cell_rd_data;
  logic [7:0] cell_count, constraint_index;
  logic cell_constraints;

  wire signed [7:0] cell_rec_coeff = $signed(cell_rd_data[31:24]);
  wire signed [23:0] cell_rec_const = $signed(cell_rd_data[23:0]);

  // When set, cells whose value is uniquely determined are restored even if
  // the square as a whole is not uniquely restorable (undetermined cells keep
  // their 0xFF input value).  When clear, the packet is echoed unless every
  // missing cell can be restored.
  localparam bit PARTIAL_FILL = 1'b1;
  logic commit_const_only;

  wire [7:0] line_count = {side,1'b0};
  wire [6:0] indexed_line = ({1'b0,constraint_index} < {2'b0,side}) ?
    constraint_index[6:0] : 7'd64 + constraint_index[6:0] - side;
  wire [13:0] indexed_record = !indexed_line[6] ? row_meta[indexed_line[5:0]] :
    (!indexed_line[0] ? column_even_meta[indexed_line[5:1]] :
                        column_odd_meta[indexed_line[5:1]]);
  // 254*x computed as (x<<8)-(x<<1): an adder instead of a multiplier.
  wire [14:0] line_deg_x256 = {indexed_record[13:7],8'b0};
  wire [14:0] line_deg_x2 = {7'b0,indexed_record[13:7],1'b0};
  wire [13:0] line_capacity = line_deg_x256[13:0] - line_deg_x2[13:0];
  wire signed [23:0] raw_limit = cell_constraints ?
    24'sd254 : $signed({10'd0,line_capacity});

  logic [13:0] sum_low, sum_high, search_low, search_high;
  logic signed [8:0] gain;
  logic signed [23:0] offset, value_low, value_high;
  logic tighten_low, tighten_high;
  logic [13:0] probe_sum;
  logic [14:0] midpoint;
  logic signed [8:0] evaluation_gain;
  logic signed [23:0] evaluation_offset, expression_value;
  logic signed [23:0] fast_lower, fast_upper;
  wire [14:0] side_x256 = {side,8'b0};
  wire [14:0] side_x2 = {7'b0,side,1'b0};
  wire [13:0] maximum_sum = side_x256[13:0] - side_x2[13:0];
  // Removed cell coordinates: {row,column} pair of the leaf edge.
  wire [11:0] cell_row_or_col = active_line[6] ? {other_line[5:0],active_line[5:0]} : {active_line[5:0],other_line[5:0]};
  wire [13:0] scan_col0_record=column_even_meta[scan_column[5:1]];
  wire [13:0] scan_col1_record=column_odd_meta[scan_column[5:1]];
  wire [6:0] scan_row_degree_next=scan_row_degree+
    {6'd0,(pair_first==8'hff)}+{6'd0,(scan_second_valid && pair_second==8'hff)};
  wire [6:0] scan_row_neighbor_next=scan_row_neighbor^
    ((pair_first==8'hff)?column_node_0:7'd0)^
    ((scan_second_valid && pair_second==8'hff)?column_node_1:7'd0);
  wire signed [23:0] scan_row_constant_next=scan_row_constant-
    ((pair_first==8'hff)?24'sd0:$signed({16'd0,pair_first}))-
    ((!scan_second_valid || pair_second==8'hff)?24'sd0:$signed({16'd0,pair_second}));

  // One multiplier serves interval searches, address flattening, writes.
  always_comb begin
    midpoint = {1'b0,search_low}+{1'b0,search_high};
    if (state==FIND_HIGH) midpoint = midpoint+15'd1;
    probe_sum = sum_low;
    if (state==CHECK_HIGH) probe_sum=sum_high;
    else if (state==FIND_LOW || state==FIND_HIGH) probe_sum=midpoint[14:1];
    evaluation_gain=gain;
    evaluation_offset=offset;
    if (state==REMOVE_CELL) begin
      // Reuse the shared multiplier to flatten the removed cell's
      // {row,column} pair into its packet address: side*row+col.
      evaluation_gain=$signed({2'b0,side});
      evaluation_offset={18'd0,cell_row_or_col[5:0]};
      probe_sum={8'd0,cell_row_or_col[11:6]};
    end else if (state==COMMIT_WRITE) begin
      evaluation_gain=$signed({cell_rec_coeff[7],cell_rec_coeff});
      evaluation_offset=cell_rec_const;
      probe_sum=sum_low;
    end
    expression_value=evaluation_gain*$signed({1'b0,probe_sum})+evaluation_offset;
    fast_lower=value_low-offset;
    fast_upper=value_high-offset;
  end

  always_comb begin
    read_pair_address=scan_address;
    if (state==SCAN_USE) read_pair_address=scan_next_address;
    else if (state==SEND_PRIME || state==SEND_FIRST) read_pair_address=output_address;
    else if (state==SEND_SECOND) read_pair_address=output_address+12'd2;
    odd_read_index=read_pair_address[11:1];
    even_read_index=read_pair_address[11:1]+{10'd0,read_pair_address[0]};

    packet_write_enable=1'b0;
    packet_write_address=12'd0;
    packet_write_data=i_data[7:0];
    if (!i_rst) begin
      if (state==IDLE && i_valid && i_first) packet_write_enable=1'b1;
      else if (state==RECEIVE && i_valid && packet_length<13'd4096) begin
        packet_write_enable=1'b1;
        packet_write_address=packet_length[11:0];
      end else if (state==COMMIT_WRITE) begin
        packet_write_enable=
          !commit_const_only || cell_rec_coeff==8'sd0;
        packet_write_address=cell_rd_data[43:32];
        packet_write_data=expression_value[7:0];
      end
    end
  end

  // Residual bank ports.  Every bank keeps a single write port so each
  // infers as true-dual-port BRAM: row/colo writes on port A, all cole
  // writes on port B.  Read muxes: port A = indexed / active / even-column
  // scan prefetch; port B = other endpoint / odd-column scan prefetch.
  always_comb begin
    row_we_a=1'b0; row_wa_a=6'd0; row_wd_a=32'd0;
    colo_we_a=1'b0; colo_wa_a=5'd0; colo_wd_a=32'd0;
    cole_we_b=1'b0; cole_wb_b=5'd0; cole_wd_b=32'd0;
    row_ra_a=indexed_line[5:0]; row_rb_b=other_line[5:0];
    cole_ra_a=indexed_line[5:1]; cole_rb_b=other_line[5:1];
    colo_ra_a=indexed_line[5:1]; colo_rb_b=other_line[5:1];
    if (state==CLEAR_LINES) begin
      row_we_a=1'b1; row_wa_a=line_index[5:0]; row_wd_a={8'sd1,24'sd0};
      if (!line_index[0]) begin
        cole_we_b=1'b1; cole_wb_b=line_index[5:1]; cole_wd_b={8'sd1,24'sd0};
      end else begin
        colo_we_a=1'b1; colo_wa_a=line_index[5:1]; colo_wd_a={8'sd1,24'sd0};
      end
    end else if (state==SCAN_PRIME || state==SCAN_USE || state==SCAN_BUBBLE) begin
      // Prefetch the residual record of the next consumed column pair.
      cole_ra_a=(state==SCAN_PRIME) ? 5'd0 : scan_next_pair;
      colo_rb_b=(state==SCAN_PRIME) ? 5'd0 : scan_next_pair;
      if (state==SCAN_USE) begin
        cole_we_b=1'b1; cole_wb_b=scan_column[5:1];
        cole_wd_b={8'sd1,bank_a[23:0]-
          ((pair_first==8'hff)?24'sd0:$signed({16'd0,pair_first}))};
        colo_we_a=1'b1; colo_wa_a=scan_column[5:1];
        colo_wd_a={8'sd1,bank_b[23:0]-
          ((!scan_second_valid || pair_second==8'hff)?24'sd0:$signed({16'd0,pair_second}))};
        if (scan_row_wrap) begin
          row_we_a=1'b1; row_wa_a=scan_row; row_wd_a={8'sd1,scan_row_constant_next};
        end
      end
    end else if (state==CHECK_LINE) begin
      row_ra_a=active_line[5:0]; cole_ra_a=active_line[5:1]; colo_ra_a=active_line[5:1];
    end else if (state==REMOVE_CELL) begin
      // Both endpoints write every cycle: the eliminated line is zeroed and
      // the surviving neighbour absorbs the cell's coefficient and constant.
      // Edges always join a row node to a column node, so the two writes
      // never target the same bank.
      if (!active_line[6]) begin
        row_we_a=1'b1; row_wa_a=active_line[5:0]; row_wd_a=32'd0;
      end else if (!active_line[0]) begin
        cole_we_b=1'b1; cole_wb_b=active_line[5:1]; cole_wd_b=32'd0;
      end else begin
        colo_we_a=1'b1; colo_wa_a=active_line[5:1]; colo_wd_a=32'd0;
      end
      if (!other_line[6]) begin
        row_we_a=1'b1; row_wa_a=other_line[5:0]; row_wd_a=other_bank_next;
      end else if (!other_line[0]) begin
        cole_we_b=1'b1; cole_wb_b=other_line[5:1]; cole_wd_b=other_bank_next;
      end else begin
        colo_we_a=1'b1; colo_wa_a=other_line[5:1]; colo_wd_a=other_bank_next;
      end
    end
  end

  always_comb begin
    row_meta_we=1'b0; column_even_meta_we=1'b0; column_odd_meta_we=1'b0;
    row_meta_wa=6'd0; column_even_meta_wa=5'd0; column_odd_meta_wa=5'd0;
    row_meta_wd=14'd0; column_even_meta_wd=14'd0; column_odd_meta_wd=14'd0;
    if (state==CLEAR_LINES) begin
      row_meta_we=1'b1; row_meta_wa=line_index[5:0];
      row_meta_wd=14'd0;
      if (!line_index[0]) begin
        column_even_meta_we=1'b1; column_even_meta_wa=line_index[5:1];
        column_even_meta_wd=14'd0;
      end else begin
        column_odd_meta_we=1'b1; column_odd_meta_wa=line_index[5:1];
        column_odd_meta_wd=14'd0;
      end
    end else if (state==SCAN_USE) begin
      column_even_meta_we=1'b1; column_even_meta_wa=scan_column[5:1];
      column_even_meta_wd={scan_col0_record[13:7]+{6'd0,(pair_first==8'hff)},
        scan_col0_record[6:0]^((pair_first==8'hff)?row_node:7'd0)};
      if (scan_second_valid) begin
        column_odd_meta_we=1'b1; column_odd_meta_wa=scan_column[5:1];
        column_odd_meta_wd={scan_col1_record[13:7]+{6'd0,(pair_second==8'hff)},
          scan_col1_record[6:0]^((pair_second==8'hff)?row_node:7'd0)};
      end
      if (scan_row_wrap) begin
        row_meta_we=1'b1; row_meta_wa=scan_row;
        row_meta_wd={scan_row_degree_next,scan_row_neighbor_next};
      end
    end else if (state==REMOVE_CELL) begin
      if (!active_line[6]) begin
        row_meta_we=1'b1; row_meta_wa=active_line[5:0]; row_meta_wd=14'd0;
        if (!other_line[0]) begin
          column_even_meta_we=1'b1; column_even_meta_wa=other_line[5:1];
          column_even_meta_wd={other_degree-7'd1,other_neighbor^active_line};
        end else begin
          column_odd_meta_we=1'b1; column_odd_meta_wa=other_line[5:1];
          column_odd_meta_wd={other_degree-7'd1,other_neighbor^active_line};
        end
      end else begin
        row_meta_we=1'b1; row_meta_wa=other_line[5:0];
        row_meta_wd={other_degree-7'd1,other_neighbor^active_line};
        if (!active_line[0]) begin
          column_even_meta_we=1'b1; column_even_meta_wa=active_line[5:1]; column_even_meta_wd=14'd0;
        end else begin
          column_odd_meta_we=1'b1; column_odd_meta_wa=active_line[5:1]; column_odd_meta_wd=14'd0;
        end
      end
    end
  end

  always_ff @(posedge i_clk) begin
    cell_rd_data<=cell_mem[constraint_index[6:0]];
    queue_rd_data<=leaf_queue[queue_head[6:0]];
    if (row_meta_we) row_meta[row_meta_wa]<=row_meta_wd;
    if (column_even_meta_we) column_even_meta[column_even_meta_wa]<=column_even_meta_wd;
    if (column_odd_meta_we) column_odd_meta[column_odd_meta_wa]<=column_odd_meta_wd;
  end

  // Residual banks; one write port per bank so Vivado keeps TDP BRAM.
  always_ff @(posedge i_clk) begin
    row_rd_a<=row_bank[row_ra_a];
    if (row_we_a) row_bank[row_wa_a]<=row_wd_a;
    cole_rd_a<=cole_bank[cole_ra_a];
    colo_rd_a<=colo_bank[colo_ra_a];
    if (colo_we_a) colo_bank[colo_wa_a]<=colo_wd_a;
  end
  always_ff @(posedge i_clk) begin
    row_rd_b<=row_bank[row_rb_b];
    cole_rd_b<=cole_bank[cole_rb_b];
    if (cole_we_b) cole_bank[cole_wb_b]<=cole_wd_b;
    colo_rd_b<=colo_bank[colo_rb_b];
    rd_sel_a<=(state==SCAN_PRIME || state==SCAN_USE || state==SCAN_BUBBLE) ? BANK_COLE :
      (state==CHECK_LINE ? bank_of(active_line) : bank_of(indexed_line));
    rd_sel_b<=(state==SCAN_PRIME || state==SCAN_USE || state==SCAN_BUBBLE) ? BANK_COLO :
      bank_of(other_line);
  end

  always_ff @(posedge i_clk) begin
    even_read_data<=packet_even[even_read_index];
    odd_read_data<=packet_odd[odd_read_index];
    read_data_address_lsb<=read_pair_address[0];
    if (packet_write_enable) begin
      if (packet_write_address[0]) packet_odd[packet_write_address[11:1]]<=packet_write_data;
      else packet_even[packet_write_address[11:1]]<=packet_write_data;
    end
  end

  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      state<=IDLE; o_valid<=1'b0; o_last<=1'b0; o_data<='0;
      packet_length<=13'd0; fill_missing<=1'b0; commit_const_only<=1'b0;
    end else begin
      o_valid<=1'b0; o_last<=1'b0;
      case (state)
        IDLE: if (i_valid && i_first) begin
          packet_length<=13'd1; side<=7'd1; square_size<=13'd1;
          output_address<=12'd0; fill_missing<=1'b0;
          received_missing<=(i_data[7:0]==8'hff);
          if (i_last) state<=SIZE;
          else state<=RECEIVE;
        end

        RECEIVE: if (i_valid) begin
          if (packet_length<13'd4096) packet_length<=packet_length+13'd1;
          if (i_data[7:0]==8'hff) received_missing<=1'b1;
          if (i_last) state<=SIZE;
        end

        SIZE: begin
          if (square_size==packet_length) begin
            if (!received_missing) begin output_address<=12'd0; state<=SEND_PRIME; end
            else begin
              line_index<=7'd0; missing_count<=13'd0;
              known_all_zero<=1'b1; known_all_max<=1'b1;
              queue_head<=8'd0; queue_tail<=8'd0; cell_count<=8'd0;
              scan_address<=12'd0; scan_row<=6'd0; scan_column<=6'd0;
              state<=CLEAR_LINES;
            end
          end else if (square_size>packet_length || side==7'd64) begin
            output_address<=12'd0; state<=SEND_PRIME;
          end else begin
            side<=side+7'd1;
            square_size<=square_size+{5'd0,side,1'b0}+13'd1;
          end
        end

        CLEAR_LINES: begin
          if ({1'b0,line_index}+8'd1=={1'b0,side}) begin
            scan_row_degree<=7'd0; scan_row_neighbor<=7'd0; scan_row_constant<=24'sd0;
            state<=SCAN_PRIME;
          end
          else line_index<=line_index+7'd1;
        end

        SCAN_PRIME: state<=SCAN_USE;

        SCAN_USE: begin
          if (pair_first!=8'hff) begin
            if (pair_first!=8'd0) known_all_zero<=1'b0;
            if (pair_first!=8'd254) known_all_max<=1'b0;
          end
          if (scan_second_valid) begin
            if (pair_second!=8'hff) begin
              if (pair_second!=8'd0) known_all_zero<=1'b0;
              if (pair_second!=8'd254) known_all_max<=1'b0;
            end
          end
          missing_count<=missing_count+{12'd0,(pair_first==8'hff)}+
            {12'd0,(scan_second_valid && pair_second==8'hff)};
          if (scan_last_pair) begin line_index<=7'd0; constraint_index<=8'd0; state<=BUILD_QUEUE; end
          else begin
            scan_address<=scan_next_address;
            if (scan_row_wrap) begin
              scan_column<=6'd0; scan_row<=scan_row+6'd1;
              scan_row_degree<=7'd0; scan_row_neighbor<=7'd0; scan_row_constant<=24'sd0;
              // side<=2 wraps onto the same bank index the write-back just
              // committed; the prefetched record is stale, so re-read it.
              if (side<=7'd2) state<=SCAN_BUBBLE;
            end else begin
              scan_column<=scan_column+6'd2;
              scan_row_degree<=scan_row_degree_next;
              scan_row_neighbor<=scan_row_neighbor_next;
              scan_row_constant<=scan_row_constant_next;
            end
          end
        end

        // One idle cycle after a wrap on a narrow square: let the residual
        // write-back land before the next pair's record is fetched.
        SCAN_BUBBLE: state<=SCAN_USE;

        BUILD_QUEUE: begin
          if (indexed_record[13:7]==7'd1) begin
            leaf_queue[queue_tail[6:0]]<=indexed_line; queue_tail<=queue_tail+8'd1;
          end
          if (line_index+7'd1==line_count[6:0]) state<=POP_LINE;
          else begin line_index<=line_index+7'd1; constraint_index<=constraint_index+8'd1; end
        end

        POP_LINE: begin
          if (queue_head==queue_tail) begin
            sum_low<=14'd0; sum_high<=maximum_sum;
            constraint_index<=8'd0; cell_constraints<=1'b0; state<=LOAD_CONSTRAINT;
          end else begin
            queue_head<=queue_head+8'd1; state<=POP_WAIT;
          end
        end

        // leaf_queue is BRAM: the dequeue read lands one cycle after POP_LINE.
        POP_WAIT: begin
          active_line<=queue_rd_data; state<=CHECK_LINE;
        end

        CHECK_LINE: begin
          if (active_degree==7'd1) state<=REMOVE_CELL;
          else state<=POP_LINE;
        end

        REMOVE_CELL: begin
          cell_mem[cell_count[6:0]]<={expression_value[11:0],
              active_coefficient[7:0],active_constant[23:0]};
          cell_count<=cell_count+8'd1; missing_count<=missing_count-13'd1;
          if (other_degree==7'd2) begin
            leaf_queue[queue_tail[6:0]]<=other_line; queue_tail<=queue_tail+8'd1;
          end
          state<=POP_LINE;
        end

        LOAD_CONSTRAINT: begin
          if (!cell_constraints && constraint_index==line_count) begin
            cell_constraints<=1'b1; constraint_index<=8'd0;
          end else if (cell_constraints && constraint_index==cell_count) state<=DECIDE;
          else if (cell_constraints) state<=CELL_FETCH;
          else state<=LINE_FETCH;
        end

        // Line residual {coeff,const} arrives one cycle after LOAD_CONSTRAINT.
        LINE_FETCH: begin
          if (bank_a[31:24]==8'sd0 && bank_a[23:0]==24'sd0) begin
            constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT;
          end else if ($signed(bank_a[31:24])<0) begin
            gain<=-$signed({bank_a[31],bank_a[31:24]});
            offset<=-$signed(bank_a[23:0]); value_low<=-raw_limit; value_high<=24'sd0;
            state<=FAST_CONSTRAINT;
          end else begin
            gain<=$signed({1'b0,bank_a[31:24]});
            offset<=$signed(bank_a[23:0]); value_low<=24'sd0; value_high<=raw_limit;
            state<=FAST_CONSTRAINT;
          end
        end

        CELL_FETCH: begin
          if (cell_rec_coeff==8'sd0 && cell_rec_const==24'sd0) begin
            constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT;
          end else if (cell_rec_coeff<0) begin
            gain<=-$signed({cell_rec_coeff[7],cell_rec_coeff});
            offset<=-cell_rec_const; value_low<=-24'sd254; value_high<=24'sd0;
            state<=FAST_CONSTRAINT;
          end else begin
            gain<=$signed({1'b0,cell_rec_coeff});
            offset<=cell_rec_const; value_low<=24'sd0; value_high<=24'sd254;
            state<=FAST_CONSTRAINT;
          end
        end

        FAST_CONSTRAINT: begin
          if (gain==0) begin
            if (offset<value_low || offset>value_high) begin output_address<=12'd0; state<=SEND_PRIME; end
            else begin constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT; end
          end else if (sum_low==sum_high) begin
            if (expression_value<value_low || expression_value>value_high) begin output_address<=12'd0; state<=SEND_PRIME; end
            else begin constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT; end
          end else if (gain==9'sd1) begin
            if (fast_lower>$signed({10'd0,sum_high}) || fast_upper<$signed({10'd0,sum_low})) begin
              output_address<=12'd0; state<=SEND_PRIME;
            end else begin
              if (fast_lower>$signed({10'd0,sum_low})) sum_low<=fast_lower[13:0];
              if (fast_upper<$signed({10'd0,sum_high})) sum_high<=fast_upper[13:0];
              constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT;
            end
          end else state<=CHECK_LOW;
        end

        CHECK_LOW: begin
          if (expression_value>value_high) begin output_address<=12'd0; state<=SEND_PRIME; end
          else begin tighten_low<=expression_value<value_low; state<=CHECK_HIGH; end
        end

        CHECK_HIGH: begin
          if (expression_value<value_low) begin output_address<=12'd0; state<=SEND_PRIME; end
          else begin
            tighten_high<=expression_value>value_high; search_low<=sum_low; search_high<=sum_high;
            if (tighten_low) state<=FIND_LOW;
            else if (expression_value>value_high) state<=FIND_HIGH;
            else begin constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT; end
          end
        end

        FIND_LOW: begin
          if (search_low==search_high) begin
            if (expression_value>value_high) begin output_address<=12'd0; state<=SEND_PRIME; end
            else begin
              sum_low<=search_low;
              if (tighten_high) begin search_high<=sum_high; state<=FIND_HIGH; end
              else begin constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT; end
            end
          end else if (expression_value>=value_low) search_high<=probe_sum;
          else search_low<=probe_sum+14'd1;
        end

        FIND_HIGH: begin
          if (search_low==search_high) begin
            sum_high<=search_low; constraint_index<=constraint_index+8'd1; state<=LOAD_CONSTRAINT;
          end else if (expression_value<=value_high) search_low<=probe_sum;
          else search_high<=probe_sum-14'd1;
        end

        DECIDE: begin
          output_address<=12'd0;
          constraint_index<=8'd0;
          commit_const_only<=1'b0;
          if (sum_low==sum_high) begin
            // S unique: every eliminated cell is determined; uneliminated
            // (cyclic) cells keep 0xFF unless the saturation shortcut applies.
            if (missing_count!=13'd0) begin
              if (sum_low==14'd0 && known_all_zero) begin fill_missing<=1'b1; fill_value<=8'd0; end
              else if (sum_low==maximum_sum && known_all_max) begin fill_missing<=1'b1; fill_value<=8'd254; end
            end
            if (cell_count==8'd0) state<=SEND_PRIME;
            else state<=COMMIT_READ;
          end else if (PARTIAL_FILL && sum_low<sum_high && cell_count!=8'd0) begin
            // S free but consistent: only coefficient-0 cells are determined.
            commit_const_only<=1'b1; state<=COMMIT_READ;
          end else state<=SEND_PRIME;
        end

        COMMIT_READ: state<=COMMIT_WRITE;
        COMMIT_WRITE: begin
          if (constraint_index+8'd1==cell_count) begin output_address<=12'd0; state<=SEND_PRIME; end
          else begin constraint_index<=constraint_index+8'd1; state<=COMMIT_READ; end
        end

        SEND_PRIME: state<=SEND_FIRST;
        SEND_FIRST: begin
          o_valid<=1'b1;
          o_data<=TASK_OUTPUT_WIDTH'((fill_missing && pair_first==8'hff)?fill_value:pair_first);
          if ({1'b0,output_address}+13'd1==packet_length) begin o_last<=1'b1; state<=IDLE; end
          else state<=SEND_SECOND;
        end
        SEND_SECOND: begin
          o_valid<=1'b1;
          o_data<=TASK_OUTPUT_WIDTH'((fill_missing && pair_second==8'hff)?fill_value:pair_second);
          if ({1'b0,output_address}+13'd2==packet_length) begin o_last<=1'b1; state<=IDLE; end
          else begin output_address<=output_address+12'd2; state<=SEND_FIRST; end
        end
        default: state<=IDLE;
      endcase
    end
  end
endmodule
