`timescale 1ns/1ps

module descriptor_manager #(
    parameter integer NUM_DESC = 8,
    parameter integer ID_WIDTH = (NUM_DESC <= 1) ? 1 : $clog2(NUM_DESC),
    parameter integer COUNT_WIDTH = $clog2(NUM_DESC + 1)
) (
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   alloc_req,
    output logic                   alloc_ready,
    output logic [ID_WIDTH-1:0]    alloc_id,

    input  logic                   free_valid,
    input  logic [ID_WIDTH-1:0]    free_id,
    output logic                   free_error,

    output logic [COUNT_WIDTH-1:0] allocated_count
);

    logic [NUM_DESC-1:0] allocated;
    logic                free_found;
    logic [ID_WIDTH-1:0] free_candidate;
    logic                free_accept;
    logic                alloc_accept;

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
    assign alloc_accept = alloc_req && alloc_ready;

    // Guard the dynamic bit-select with the range check.
    always_comb begin
        free_accept = 1'b0;
        if (free_valid && (free_id < NUM_DESC))
            free_accept = allocated[free_id];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            allocated       <= '0;
            allocated_count <= '0;
            free_error      <= 1'b0;
        end else begin
            free_error <= free_valid && !free_accept;

            if (free_accept)
                allocated[free_id] <= 1'b0;

            if (alloc_accept)
                allocated[alloc_id] <= 1'b1;

            // Account for both operations explicitly, including simultaneous
            // allocation and release in the same cycle.
            case ({alloc_accept, free_accept})
                2'b10: allocated_count <= allocated_count + 1'b1;
                2'b01: allocated_count <= allocated_count - 1'b1;
                default: allocated_count <= allocated_count;
            endcase
        end
    end

    initial begin
        if (NUM_DESC < 1)
            $error("descriptor_manager NUM_DESC must be at least 1");
    end

endmodule
