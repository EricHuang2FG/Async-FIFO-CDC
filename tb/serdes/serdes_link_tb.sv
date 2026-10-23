`timescale 1ns/1ps

module serdes_link_tb;

    // constant definitions
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_BIT_WIDTH = 5;
    localparam logic [6:0] SEED = 7'b1111111;

    // definitions of clock and reset signals
    logic tx_clk, tx_resetn;
    logic bit_clk, bit_resetn;
    logic rx_clk, rx_resetn;

    // TX-side signals
    logic tx_wr_inc;
    logic [DATA_WIDTH - 1:0] tx_wr_data;
    logic tx_wr_full;

    // RX-side signals
    logic rx_rd_inc;
    logic [DATA_WIDTH - 1:0] rx_rd_data;
    logic rx_rd_empty;

    // error signals and observation signals
    logic serializer_out;
    logic rx_overflow;

    // evaluation counters
    logic [31:0] num_words, num_errors;
    logic overflow_seen;

    assign tx_wr_inc = !tx_wr_full;
    assign rx_rd_inc = !rx_rd_empty;

    // instantiate generator, checker and the dut!
    prbs7_generator #(.DATA_WIDTH(DATA_WIDTH), .SEED(SEED)) gen (
        .clk(tx_clk),
        .resetn(tx_resetn),
        .enable(tx_wr_inc),
        .data(tx_wr_data)
    );

    serdes_link #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)
    ) dut (
        .tx_clk(tx_clk),
        .tx_resetn(tx_resetn),
        .bit_clk(bit_clk),
        .bit_resetn(bit_resetn),
        .rx_clk(rx_clk),
        .rx_resetn(rx_resetn),

        .tx_wr_inc(tx_wr_inc),
        .tx_wr_data(tx_wr_data),
        .tx_wr_full(tx_wr_full),

        .rx_rd_inc(rx_rd_inc),
        .rx_rd_data(rx_rd_data),
        .rx_rd_empty(rx_rd_empty),

        .serializer_out(serializer_out),
        .rx_overflow(rx_overflow)
    );


    prbs7_checker #(.DATA_WIDTH(DATA_WIDTH), .SEED(SEED)) chk (
        .clk(rx_clk),
        .resetn(rx_resetn),
        .enable(rx_rd_inc),
        .data(rx_rd_data),
        .num_words(num_words),
        .num_errors(num_errors)
    );

    // clock driving
    initial bit_clk = 0;
    initial tx_clk = 0;
    initial rx_clk = 0;

    always #5  bit_clk = ~bit_clk;
    always #7  tx_clk  = ~tx_clk;
    always #11 rx_clk  = ~rx_clk;

    // monitor for overflow_seen
    always @(posedge bit_clk) begin
        if (rx_overflow) 
            overflow_seen <= 1'b1;
    end

    // task definitions
    task reset();
        tx_resetn <= 1'b0;
        bit_resetn <= 1'b0;
        rx_resetn <= 1'b0;
        
        // reset both read and write at the same time
        fork
            begin
                repeat (6) @(posedge tx_clk);
                tx_resetn <= 1'b1;
            end
            begin
                repeat (6) @(posedge bit_clk);
                bit_resetn <= 1'b1;
            end
            begin
                repeat (6) @(posedge rx_clk);
                rx_resetn <= 1'b1;
            end
        join

        repeat (6) @(posedge tx_clk);
    endtask

    // watchdog for timeout
    initial begin
        #1_000_000;
        $display("FAILED: SIMULATION TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;

        overflow_seen <= 1'b0;

        reset();

        // run 250 words and let the checker do the monitoring
        wait (num_words >= 250);
        repeat (4) @(posedge rx_clk);

        if (num_errors == 0 && num_words >= 250 && !overflow_seen)
            $display("ALL TESTS PASSED");
        else
            $display("FAILED");

        $display("Summary: num_words=%0d, num_errors=%0d, overflow_seen=%d", num_words, num_errors, overflow_seen);

        $finish;
    end

endmodule
