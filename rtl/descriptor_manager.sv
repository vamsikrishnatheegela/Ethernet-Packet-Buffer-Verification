`timescale 1ns/1ps

module descriptor_manager #(
    parameter integer NUM_DESC = 8,
    parameter integer ID_WIDTH = (NUM_DESC <= 1) ? 1 : $clog2(NUM_DESC),
    parameter integer COUNT_WIDTH = $clog2(NUM_DESC + 1)
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  alloc_req,
    output logic                  alloc_ready,
    output logic [ID_WIDTH-1:0]   alloc_id,

    input  logic                  free_valid,
    input  logic [ID_WIDTH-1:0]   free_id,
    output logic                  free_error,

    output logic [COUNT_WIDTH-1:0] allocated_count
);

    logic [NUM_DESC-1:0] allocated;
    logic                free_found;
    logic [ID_WIDTH-1:0] free_candidate;
    integer i;

    // First-fit allocation: choose the lowest-numbered unallocated descriptor.
    always_comb begin
        free_found     = 1'b0;
        free_candidate = '0;
        for (integer j = NUM_DESC-1; j >= 0; j = j - 1) begin
            if (!allocated[j]) begin
                free_found     = 1'b1;
                free_candidate = j[ID_WIDTH-1:0];
            end
        end
    end

    assign alloc_ready = free_found;
    assign alloc_id    = free_candidate;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            allocated       <= '0;
            allocated_count <= '0;
            free_error      <= 1'b0;
        end else begin
            free_error <= 1'b0;

            // A release is accepted only for an in-range, currently allocated ID.
            if (free_valid) begin
                if ((free_id < NUM_DESC) && allocated[free_id]) begin
                    allocated[free_id] <= 1'b0;
                    allocated_count    <= allocated_count - 1'b1;
                end else begin
                    free_error <= 1'b1;
                end
            end

            // Allocation and release may occur in the same cycle for different IDs.
            if (alloc_req && alloc_ready) begin
                allocated[alloc_id] <= 1'b1;
                if (!free_valid || free_error || !((free_id < NUM_DESC) && allocated[free_id]))
                    allocated_count <= allocated_count + 1'b1;
            end
        end
    end

    initial begin
        if (NUM_DESC < 1)
            $error("descriptor_manager NUM_DESC must be at least 1");
    end

endmodule
