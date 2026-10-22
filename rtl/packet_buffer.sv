`timescale 1ns/1ps

module packet_buffer #(
    parameter integer DATA_WIDTH = 32,
    parameter integer KEEP_WIDTH = DATA_WIDTH / 8,
    parameter integer DEPTH = 8,
    parameter integer PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH),
    parameter integer COUNT_WIDTH = $clog2(DEPTH + 1)
) (
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   in_valid,
    output logic                   in_ready,
    input  logic [DATA_WIDTH-1:0]  in_data,
    input  logic [KEEP_WIDTH-1:0]  in_keep,
    input  logic                   in_last,

    output logic                   out_valid,
    input  logic                   out_ready,
    output logic [DATA_WIDTH-1:0]  out_data,
    output logic [KEEP_WIDTH-1:0]  out_keep,
    output logic                   out_last,

    output logic [COUNT_WIDTH-1:0] occupancy
);

    logic [DATA_WIDTH-1:0] data_mem [0:DEPTH-1];
    logic [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    logic                  last_mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;
    logic                 push;
    logic                 pop;

    // Permit a replacement beat on the same cycle that a full FIFO pops.
    assign out_valid = (occupancy != 0);
    assign in_ready  = (int'(occupancy) < DEPTH) || (out_valid && out_ready);

    assign out_data = data_mem[rd_ptr];
    assign out_keep = keep_mem[rd_ptr];
    assign out_last = last_mem[rd_ptr];

    assign push = in_valid && in_ready;
    assign pop  = out_valid && out_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr    <= '0;
            rd_ptr    <= '0;
            occupancy <= '0;
        end else begin
            if (push) begin
                data_mem[wr_ptr] <= in_data;
                keep_mem[wr_ptr] <= in_keep;
                last_mem[wr_ptr] <= in_last;
                if (wr_ptr == PTR_WIDTH'(DEPTH-1))
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (pop) begin
                if (rd_ptr == PTR_WIDTH'(DEPTH-1))
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            case ({push, pop})
                2'b10: occupancy <= occupancy + 1'b1;
                2'b01: occupancy <= occupancy - 1'b1;
                default: occupancy <= occupancy;
            endcase
        end
    end

    initial begin
        if (DEPTH < 1) begin
            $error("packet_buffer DEPTH must be at least 1");
        end
        if (DATA_WIDTH % 8 != 0) begin
            $error("packet_buffer DATA_WIDTH must be a multiple of 8");
        end
    end

endmodule
