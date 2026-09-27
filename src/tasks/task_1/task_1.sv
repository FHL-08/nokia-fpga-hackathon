`timescale 1ns / 1ps
module task_1
#(
    parameter int TASK_INPUT_WIDTH = 8,
    parameter int TASK_OUTPUT_WIDTH = 8
)(
    input  wire                          i_clk,
    input  wire                          i_rst,
    input  wire                          i_valid,
    input  wire                          i_first,
    input  wire                          i_last,
    input  wire [TASK_INPUT_WIDTH-1:0]   i_data,
    output logic                         o_valid,
    output logic                         o_last,
    output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

    typedef enum logic [2:0] {
        S_IDLE, S_C2, S_DATA, S_DIV, S_DRAIN
    } state_t;
    state_t state;

    (* ram_style = "block" *) logic [7:0] mem_a [0:4095];
    (* ram_style = "block" *) logic [7:0] mem_b [0:4095];
    logic [7:0] qa, qb;

    logic        rot, rgt, shl, shr;
    logic [10:0] bsh;
    logic [2:0]  r_r;
    logic [11:0] pa;
    logic        va;
    logic [12:0] wr;
    logic [11:0] e;

    logic fire, hit_a, va_d1, vb_d1, fire_d1, last_d1;
    logic [7:0]  lo_b, hi_b, out_b;
    logic [15:0] osh;
    logic [10:0] B_c;
    logic [11:0] pa_c, pb_c;
    logic [12:0] rem_t, pw, pe;
    logic [11:0] sb_c, pa_n;
    logic [3:0]  a_sh;

    assign B_c   = {bsh[10:5], i_data[7:3]};
    assign pa_c  = {1'b0, B_c} ^ {12{rgt}};
    assign pw    = {1'b0, pa} + 13'd1;
    assign pe    = {1'b0, e} + 13'd1;
    assign pb_c  = hit_a ? 12'd0 : pw[11:0];
    assign rem_t = {pa[11:0], bsh[10]};
    assign sb_c  = (rem_t >= wr) ? rem_t - wr : rem_t;
    assign pa_n  = rgt ? (wr[11:0] - sb_c - 12'd1) : sb_c;
    assign a_sh  = rgt ? (4'd8 - {1'b0, r_r}) : {1'b0, r_r};
    assign shl   = ~rot & ~rgt;
    assign shr   = ~rot & rgt;

    always_comb begin
        fire = 1'b0;
        if (state == S_DRAIN)
            fire = (e < wr);
        else if (state == S_DATA && !rot)
            fire = rgt ? (pe < wr) : (pw < wr);
        hit_a = shr ? pw[12] : (pw == wr);
        lo_b  = va_d1 ? qa : 8'd0;
        hi_b  = vb_d1 ? qb : 8'd0;
        osh   = {lo_b, hi_b} << a_sh;
        out_b = osh[15:8];
        o_valid = fire_d1;
        o_last  = fire_d1 && last_d1;
        o_data  = out_b;
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state   <= S_IDLE;
            rot     <= 1'b0;
            rgt     <= 1'b0;
            bsh     <= 11'd0;
            r_r     <= 3'd0;
            wr      <= 13'd0;
            e       <= 12'd0;
            pa      <= 12'd0;
            va      <= 1'b0;
            fire_d1 <= 1'b0;
            va_d1   <= 1'b0;
            vb_d1   <= 1'b0;
            last_d1 <= 1'b0;
        end else begin
            qa      <= mem_a[pa];
            qb      <= mem_b[pb_c];
            fire_d1 <= fire;
            if (fire) begin
                va_d1   <= va;
                vb_d1   <= rot | (shr & (va | hit_a)) | (shl & va & ~hit_a);
                last_d1 <= (pe == wr);
                e  <= e + 12'd1;
                pa <= pb_c;
                if (rot)
                    va <= 1'b1;
                else
                    va <= shr ? (va | hit_a) : (va & ~hit_a);
            end
            case (state)
                S_IDLE: begin
                    if (i_valid && i_first) begin
                        rot    <= i_data[7];
                        rgt    <= i_data[6];
                        bsh    <= {i_data[5:0], 5'd0};
                        wr     <= 13'd0;
                        e      <= 12'd0;
                        state  <= S_C2;
                    end
                end

                S_C2: begin
                    if (i_valid) begin
                        bsh[4:0] <= i_data[7:3];
                        r_r  <= i_data[2:0];
                        pa   <= pa_c;
                        va   <= ~rgt;
                        state <= S_DATA;
                    end
                end

                S_DATA: begin
                    if (i_valid) begin
                        mem_a[wr[11:0]] <= i_data;
                        mem_b[wr[11:0]] <= i_data;
                        wr <= wr + 13'd1;
                        if (i_last) begin
                            if (rot) begin
                                pa    <= 12'd0;
                                e     <= 12'd0;
                                state <= S_DIV;
                            end else begin
                                if (shl)
                                    va <= ({2'b00, bsh} <= wr);
                                state <= S_DRAIN;
                            end
                        end
                    end
                end

                S_DIV: begin
                    bsh <= {bsh[9:0], 1'b0};
                    if (e == 12'd10) begin
                        pa    <= pa_n;
                        va    <= 1'b1;
                        e     <= 12'd0;
                        state <= S_DRAIN;
                    end else begin
                        pa <= sb_c;
                        e  <= e + 12'd1;
                    end
                end

                S_DRAIN: begin
                    if (fire && (pe == wr))
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
