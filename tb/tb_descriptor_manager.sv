`timescale 1ns/1ps

module tb_descriptor_manager;
    localparam integer NUM_DESC = 5;
    localparam integer ID_WIDTH = (NUM_DESC <= 1) ? 1 : $clog2(NUM_DESC);
    localparam integer COUNT_WIDTH = $clog2(NUM_DESC + 1);

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic alloc_req = 1'b0;
    logic alloc_ready;
    logic [ID_WIDTH-1:0] alloc_id;
    logic free_valid = 1'b0;
    logic [ID_WIDTH-1:0] free_id = '0;
    logic free_error;
    logic [COUNT_WIDTH-1:0] allocated_count;
    integer i;
    logic [ID_WIDTH-1:0] saved_ids [0:NUM_DESC-1];

    always #5 clk = ~clk;

    descriptor_manager #(.NUM_DESC(NUM_DESC)) dut (
        .clk(clk), .rst_n(rst_n),
        .alloc_req(alloc_req), .alloc_ready(alloc_ready), .alloc_id(alloc_id),
        .free_valid(free_valid), .free_id(free_id), .free_error(free_error),
        .allocated_count(allocated_count)
    );

    task automatic allocate_one(output logic [ID_WIDTH-1:0] got_id);
        begin
            @(negedge clk);
            if (alloc_ready !== 1'b1) begin
                $display("FAIL: expected descriptor allocation to be ready");
                $fatal(1);
            end
            alloc_req = 1'b1;
            got_id = alloc_id;
            @(posedge clk);
            @(negedge clk);
            alloc_req = 1'b0;
        end
    endtask

    task automatic release_one(input logic [ID_WIDTH-1:0] id);
        begin
            @(negedge clk);
            free_valid = 1'b1;
            free_id = id;
            @(posedge clk);
            @(negedge clk);
            free_valid = 1'b0;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        if (allocated_count !== 0 || alloc_ready !== 1'b1) begin
            $display("FAIL: reset state is incorrect");
            $fatal(1);
        end

        // Allocate the complete pool and check first-fit ordering.
        for (i = 0; i < NUM_DESC; i = i + 1) begin
            allocate_one(saved_ids[i]);
            if (saved_ids[i] !== i[ID_WIDTH-1:0]) begin
                $display("FAIL: first-fit ID mismatch at allocation %0d: got %0d",
                         i, saved_ids[i]);
                $fatal(1);
            end
            if (allocated_count !== i + 1) begin
                $display("FAIL: allocated_count mismatch after allocation %0d: got %0d",
                         i, allocated_count);
                $fatal(1);
            end
        end

        @(negedge clk);
        if (alloc_ready !== 1'b0) begin
            $display("FAIL: alloc_ready should be low when pool is exhausted");
            $fatal(1);
        end
        alloc_req = 1'b1;
        @(posedge clk);
        @(negedge clk);
        alloc_req = 1'b0;
        if (allocated_count !== NUM_DESC) begin
            $display("FAIL: count changed on rejected allocation");
            $fatal(1);
        end

        // Duplicate release must be rejected and must not change the count.
        release_one(saved_ids[1]);
        if (free_error !== 1'b0 || allocated_count !== NUM_DESC-1) begin
            $display("FAIL: valid release did not update state correctly");
            $fatal(1);
        end
        release_one(saved_ids[1]);
        if (free_error !== 1'b1 || allocated_count !== NUM_DESC-1) begin
            $display("FAIL: duplicate release was not reported correctly");
            $fatal(1);
        end

        // NUM_DESC=5 leaves representable but out-of-range IDs 5, 6 and 7.
        release_one({ID_WIDTH{1'b1}});
        if (free_error !== 1'b1 || allocated_count !== NUM_DESC-1) begin
            $display("FAIL: invalid release was not rejected");
            $fatal(1);
        end

        // Allocate a free ID and release a different allocated ID together.
        @(negedge clk);
        alloc_req = 1'b1;
        free_valid = 1'b1;
        free_id = saved_ids[0];
        @(posedge clk);
        @(negedge clk);
        alloc_req = 1'b0;
        free_valid = 1'b0;
        if (allocated_count !== NUM_DESC-1) begin
            $display("FAIL: simultaneous allocate/free changed count: %0d",
                     allocated_count);
            $fatal(1);
        end
        if (free_error !== 1'b0) begin
            $display("FAIL: valid simultaneous release raised free_error");
            $fatal(1);
        end

        // Reset must clear allocation state and the registered error.
        @(negedge clk);
        rst_n = 1'b0;
        @(negedge clk);
        if (allocated_count !== 0 || alloc_ready !== 1'b1 || free_error !== 1'b0) begin
            $display("FAIL: reset did not restore descriptor manager state");
            $fatal(1);
        end

        $display("PASS: descriptor manager regression; descriptors=%0d", NUM_DESC);
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "TIMEOUT: descriptor manager testbench did not finish");
    end
endmodule
