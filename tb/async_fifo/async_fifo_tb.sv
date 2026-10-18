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

    always #5 wr_clk = ~wr_clk;
    always #9 rd_clk = ~rd_clk;

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

    initial begin
        // set initial values for signals
        wr_inc <= 1'b0;
        wr_data <= '0;
        rd_inc <= 1'b0;

        // and also the initial values for simulation variables
        num_errors <= 0;
        num_write <= 0;
        num_read <= 0;

        reset();

        $finish;
    end

endmodule
