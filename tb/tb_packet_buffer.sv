`timescale 1ns/1ps

module tb_packet_buffer;

    localparam integer DEPTH = 8;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic in_valid = 1'b0;
    logic in_ready;
    logic [31:0] in_data = '0;
    logic [3:0] in_keep = '0;
    logic in_last = 1'b0;
    logic out_valid;
    logic out_ready = 1'b0;
    logic [31:0] out_data;
    logic [3:0] out_keep;
    logic out_last;
    logic [$clog2(DEPTH+1)-1:0] occupancy;
    integer sb_errors;
    integer sb_checked;
    integer i;
    logic stalled_prev = 1'b0;
    logic [31:0] stalled_data;
    logic [3:0] stalled_keep;
    logic stalled_last;

    always #5 clk = ~clk;

    packet_buffer #(.DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_data(in_data), .in_keep(in_keep), .in_last(in_last),
        .out_valid(out_valid), .out_ready(out_ready),
        .out_data(out_data), .out_keep(out_keep), .out_last(out_last),
        .occupancy(occupancy)
    );

    packet_buffer_scoreboard scoreboard (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_data(in_data), .in_keep(in_keep), .in_last(in_last),
        .out_valid(out_valid), .out_ready(out_ready),
        .out_data(out_data), .out_keep(out_keep), .out_last(out_last),
        .error_count(sb_errors), .checked_count(sb_checked)
    );

    // A valid output beat must remain asserted and unchanged while stalled.
    always @(posedge clk) begin
        if (!rst_n) begin
            stalled_prev <= 1'b0;
        end else begin
            if (stalled_prev &&
                ((!out_valid) || (out_data !== stalled_data) ||
                 (out_keep !== stalled_keep) || (out_last !== stalled_last))) begin
                $display("FAIL: output changed while stalled");
                $fatal(1);
            end
            stalled_prev <= out_valid && !out_ready;
            if (out_valid && !out_ready) begin
                stalled_data <= out_data;
                stalled_keep <= out_keep;
                stalled_last <= out_last;
            end
        end
    end

    task automatic send_beat(
        input logic [31:0] data,
        input logic [3:0] keep,
        input logic last
    );
        begin
            @(negedge clk);
            in_valid = 1'b1;
            in_data  = data;
            in_keep  = keep;
            in_last  = last;
            // Check ready before the active edge; a push may make the FIFO full
            // immediately after that edge, but the current beat was accepted.
            while (in_ready !== 1'b1)
                @(negedge clk);
            @(posedge clk);
            @(negedge clk);
            in_valid = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("results/packet_buffer.vcd");
        $dumpvars(0, tb_packet_buffer);

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Single-beat packet and multi-beat packet, including a partial final beat.
        send_beat(32'h11223344, 4'b1111, 1'b1);
        send_beat(32'hAABBCCDD, 4'b1111, 1'b0);
        send_beat(32'h01020304, 4'b1111, 1'b0);
        send_beat(32'hDEADBEEF, 4'b0011, 1'b1);

        // Hold the consumer off while the FIFO fills, then drain it.
        repeat (4) @(negedge clk);
        out_ready = 1'b1;
        repeat (8) @(negedge clk);
        out_ready = 1'b0;

        // Fill to capacity and verify the buffer reports not-ready.
        for (i = 0; i < DEPTH; i = i + 1)
            send_beat(32'h50000000 + i, 4'b1111, (i == DEPTH-1));

        @(negedge clk);
        if (in_ready !== 1'b0) begin
            $display("TEST ERROR: expected in_ready=0 when full; occupancy=%0d", occupancy);
            $fatal(1);
        end

        out_ready = 1'b1;
        repeat (DEPTH+2) @(negedge clk);

        // Randomized ready/valid traffic. The driver holds each beat stable
        // until its input handshake has completed.
        begin : randomized_traffic
            integer cycle;
            integer accepted_inputs;
            logic accepted_previous;
            accepted_inputs = 0;
            accepted_previous = 1'b0;
            @(negedge clk);
            for (cycle = 0; cycle < 400 && accepted_inputs < 64; cycle = cycle + 1) begin
                if (accepted_previous)
                    in_valid = 1'b0;
                if (!in_valid && accepted_inputs < 64 &&
                    ($urandom_range(0, 99) < 75)) begin
                    in_valid = 1'b1;
                    in_data = $urandom;
                    in_keep = $urandom_range(1, 15);
                    in_last = ($urandom_range(0, 3) == 0);
                end
                out_ready = ($urandom_range(0, 99) < 60);
                @(posedge clk);
                accepted_previous = in_valid && in_ready;
                if (accepted_previous)
                    accepted_inputs = accepted_inputs + 1;
                @(negedge clk);
            end
            if (accepted_inputs != 64) begin
                $display("FAIL: randomized driver accepted only %0d of 64 beats",
                         accepted_inputs);
                $fatal(1);
            end
            in_valid = 1'b0;
            out_ready = 1'b1;
            while (occupancy != 0)
                @(negedge clk);
            out_ready = 1'b0;
        end

        // Allow scoreboard and output logic to settle.
        repeat (2) @(negedge clk);
        if (sb_errors != 0) begin
            $display("FAIL: scoreboard errors=%0d checked=%0d", sb_errors, sb_checked);
            $fatal(1);
        end
        if (occupancy != 0) begin
            $display("FAIL: FIFO not empty at end; occupancy=%0d", occupancy);
            $fatal(1);
        end

        $display("PASS: packet buffer regression; checked=%0d beats, errors=%0d", sb_checked, sb_errors);
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "TIMEOUT: packet buffer testbench did not finish");
    end

endmodule
