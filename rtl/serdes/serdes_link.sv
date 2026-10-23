module serdes_link #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_BIT_WIDTH = 5
) (
    // clocks and reset signals
    input logic tx_clk, tx_resetn,
    input logic bit_clk, bit_resetn,
    input logic rx_clk, rx_resetn,

    // TX signals
    input logic tx_wr_inc,
    input logic [DATA_WIDTH - 1:0] tx_wr_data,
    output logic tx_wr_full,

    // RX signals
    input logic rx_rd_inc,
    output logic [DATA_WIDTH - 1:0] rx_rd_data,
    output logic rx_rd_empty,

    // error signals and observation signals
    output logic serializer_out,
    output logic rx_overflow // deserializer tries to write to already full RX FIFO
);

    logic serializer_rd_inc;
    logic [DATA_WIDTH - 1:0] serializer_rd_data;
    logic tx_fifo_empty;
    logic serializer_word_start;
    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) fifo_tx (
        .wr_clk(tx_clk),
        .wr_resetn(tx_resetn),
        .wr_inc(tx_wr_inc),
        .wr_data(tx_wr_data),
        .rd_clk(bit_clk),
        .rd_resetn(bit_resetn),
        .rd_inc(serializer_rd_inc),
        .wr_full(tx_wr_full),
        .rd_data(serializer_rd_data),
        .rd_empty(tx_fifo_empty)
    );

    serializer #(.DATA_WIDTH(DATA_WIDTH)) serializer_unit (
        .bit_clk(bit_clk),
        .resetn(bit_resetn),
        .fifo_data_in(serializer_rd_data),
        .fifo_empty(tx_fifo_empty),
        .fifo_rd_inc(serializer_rd_inc),
        .serial_out(serializer_out),
        .word_start(serializer_word_start)
    );

    logic rx_fifo_wr_inc;
    logic [DATA_WIDTH - 1:0] rx_fifo_wr_data;
    logic rx_fifo_full;
    deserializer #(.DATA_WIDTH(DATA_WIDTH)) deserializer_unit (
        .bit_clk(bit_clk),
        .resetn(bit_resetn),
        .serial_in(serializer_out),
        .word_start(serializer_word_start),
        .fifo_data_out(rx_fifo_wr_data),
        .fifo_wr_inc(rx_fifo_wr_inc)
    );

    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) fifo_rx (
        .wr_clk(bit_clk),
        .wr_resetn(bit_resetn),
        .wr_inc(rx_fifo_wr_inc),
        .wr_data(rx_fifo_wr_data),
        .rd_clk(rx_clk),
        .rd_resetn(rx_resetn),
        .rd_inc(rx_rd_inc),
        .wr_full(rx_fifo_full),
        .rd_data(rx_rd_data),
        .rd_empty(rx_rd_empty)
    );

    assign rx_overflow = rx_fifo_full && rx_fifo_wr_inc;

endmodule
