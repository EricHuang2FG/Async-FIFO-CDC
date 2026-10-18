`timescale 1ns/1ps

module async_fifo_tb;

    // constant definitions
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_BIT_WIDTH = 5;

    // write signal definitions
    logic wr_clk, wr_resetn, wr_inc;
    logic [DATA_WIDTH - 1:0] wr_data;
    logic wr_full;

    // read signal definitions
    logic rd_clk, rd_resetn, rd_inc;
    logic [DATA_WIDTH - 1:0] rd_data;
    logic rd_empty;

    // simulation variable definitions
    logic [DATA_WIDTH - 1:0] mem_expected [$]; // a queue
    logic [DATA_WIDTH - 1:0] expected_data;
    int num_errors, num_write, num_read;

    // instantiate
    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) dut (
        .wr_clk(wr_clk),
        .wr_resetn(wr_resetn),
        .wr_inc(wr_inc),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_resetn(rd_resetn),
        .rd_inc(rd_inc),
        .wr_full(wr_full),
        .rd_data(rd_data),
        .rd_empty(rd_empty)
    );

    // define and initialize two clocks
    initial wr_clk = 0;
    initial rd_clk = 0;

    always #9 wr_clk = ~wr_clk;
    always #6 rd_clk = ~rd_clk;

    // monitors that build the expected memory array
    always @(posedge wr_clk) begin
        if (wr_resetn && wr_inc && !wr_full) begin
            mem_expected.push_back(wr_data);
            num_write++;
            $display("Wrote %b to the FIFO", wr_data);
        end
    end

    always @(posedge rd_clk) begin
        if (rd_resetn && rd_inc && !rd_empty) begin
            if (mem_expected.size() == 0) begin
                $display("FAILED: Reading from FIFO but it is empty");
                num_errors++;
            end else begin
                expected_data = mem_expected.pop_front();
                if (rd_data !== expected_data) begin
                    $display("FAILED: Reading from FIFO. Expected %b but got %b", expected_data, rd_data);
                    num_errors++;
                end else
                    $display("PASSED: Read %b from FIFO", rd_data);
            end
            num_read++;
        end
    end


    // task definitions
    task reset();
        wr_resetn <= 1'b0;
        rd_resetn <= 1'b0;
        
        // reset both read and write at the same time
        fork
            begin
                repeat (3) @(posedge wr_clk);
                wr_resetn <= 1'b1;
            end
            begin
                repeat (3) @(posedge rd_clk);
                rd_resetn <= 1'b1;
            end
        join

        repeat (6) @(posedge wr_clk);
    endtask

    task write(input logic [DATA_WIDTH - 1:0] data);
        @(posedge wr_clk);
        wr_inc <= 1'b1;
        wr_data <= data;

        @(posedge wr_clk);
        wr_inc <= 1'b0;
    endtask

    task read();
        @(posedge rd_clk);
        rd_inc <= 1'b1;

        @(posedge rd_clk);
        rd_inc <= 1'b0;
    endtask

    task write_until_full();
        for (int i = 0; !wr_full; i++) begin
            write(i);

            @(negedge wr_clk);

            if (mem_expected.size() >= 2 ** ADDR_BIT_WIDTH && !wr_full) begin
                $display("FAILED: FIFO should be full but wr_full is not high");
                num_errors++;
                break;
            end
        end

        repeat (4) @(posedge wr_clk);

        if (mem_expected.size() < 2 ** ADDR_BIT_WIDTH) begin
            $display("FAILED: FIFO reported full but it is not");
            num_errors++;
        end
    endtask

    task read_until_empty();
        while (!rd_empty) begin
            read();

            @(negedge rd_clk);

            if (mem_expected.size() <= 0 && !rd_empty) begin
                $display("FAILED: FIFO should be empty but rd_empty is not high");
                num_errors++;
                break;
            end
        end

        repeat (4) @(posedge rd_clk);

        if (mem_expected.size() > 0) begin
            $display("FAILED: FIFO reported empty but it is not");
            num_errors++;
        end
    endtask

    // watchdog for timeout
    initial begin
        #1_000_000;
        $display("FAILED: SIMULATION TIMEOUT");
        $finish;
    end

    // do tests
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;

        // set initial values for signals
        wr_inc <= 1'b0;
        wr_data <= '0;
        rd_inc <= 1'b0;

        // and also the initial values for simulation variables
        num_errors <= 0;
        num_write <= 0;
        num_read <= 0;

        reset();

        // simple write and read
        write(8'b10110110);
        repeat (4) @(posedge rd_clk);
        read();

        write(8'b10101010);
        write(8'b10010101);
        repeat (4) @(posedge rd_clk);
        read();
        read();

        // overflow and drain test!
        write_until_full();
        write(8'b11110000); // attepmt to write while full
        read_until_empty();
        read(); // attempt to read while empty

        write(8'b10101100);
        repeat (4) @(posedge rd_clk);
        read();

        repeat (4) @(posedge rd_clk);

        if (num_errors == 0 && num_write > 0 && num_write == num_read)
            $display("ALL TESTS PASSED");
        else
            $display("FAILED");

        $display("Summary: writes=%0d, reads=%0d, errors=%0d", num_write, num_read, num_errors);

        $finish;
    end

endmodule
