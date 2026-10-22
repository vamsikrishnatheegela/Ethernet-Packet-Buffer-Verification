`timescale 1ns/1ps

module packet_buffer_scoreboard #(
    parameter integer DATA_WIDTH = 32,
    parameter integer KEEP_WIDTH = DATA_WIDTH / 8,
    parameter integer DEPTH = 256,
    parameter integer PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
) (
    input logic                  clk,
    input logic                  rst_n,
    input logic                  in_valid,
    input logic                  in_ready,
    input logic [DATA_WIDTH-1:0] in_data,
    input logic [KEEP_WIDTH-1:0] in_keep,
    input logic                  in_last,
    input logic                  out_valid,
    input logic                  out_ready,
    input logic [DATA_WIDTH-1:0] out_data,
    input logic [KEEP_WIDTH-1:0] out_keep,
    input logic                  out_last,
    output integer               error_count,
    output integer               checked_count
);

    logic [DATA_WIDTH-1:0] exp_data [0:DEPTH-1];
    logic [KEEP_WIDTH-1:0] exp_keep [0:DEPTH-1];
    logic                  exp_last [0:DEPTH-1];
    logic [PTR_WIDTH-1:0]  wr_ptr;
    logic [PTR_WIDTH-1:0]  rd_ptr;
    integer                queued;
    logic                  push;
    logic                  pop;

    assign push = in_valid && in_ready;
    assign pop  = out_valid && out_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr       <= '0;
            rd_ptr       <= '0;
            queued       <= 0;
            error_count  <= 0;
            checked_count <= 0;
        end else begin
            if (push) begin
                exp_data[wr_ptr] <= in_data;
                exp_keep[wr_ptr] <= in_keep;
                exp_last[wr_ptr] <= in_last;
                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (pop) begin
                if (queued <= 0) begin
                    $display("SCOREBOARD ERROR: output beat observed with empty reference queue at %0t", $time);
                    error_count <= error_count + 1;
                end else begin
                    if ((out_data !== exp_data[rd_ptr]) ||
                        (out_keep !== exp_keep[rd_ptr]) ||
                        (out_last !== exp_last[rd_ptr])) begin
                        $display("SCOREBOARD ERROR at %0t: got data=%h keep=%h last=%b; expected data=%h keep=%h last=%b",
                                 $time, out_data, out_keep, out_last,
                                 exp_data[rd_ptr], exp_keep[rd_ptr], exp_last[rd_ptr]);
                        error_count <= error_count + 1;
                    end
                    checked_count <= checked_count + 1;
                    if (rd_ptr == DEPTH-1)
                        rd_ptr <= '0;
                    else
                        rd_ptr <= rd_ptr + 1'b1;
                end
            end

            case ({push, pop})
                2'b10: queued <= queued + 1;
                2'b01: queued <= queued - 1;
                default: queued <= queued;
            endcase
        end
    end

endmodule
