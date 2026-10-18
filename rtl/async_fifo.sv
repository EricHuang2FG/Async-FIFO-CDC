module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_BIT_WIDTH = 5
) (
    // write inputs
    input logic wr_clk,
    input logic wr_resetn,
    input logic wr_inc,
    input logic [DATA_WIDTH - 1:0] wr_data,

    // read inputs
    input logic rd_clk,
    input logic rd_resetn,
    input logic rd_inc,

    // write outputs
    output logic wr_full,

    // read outputs
    output logic [DATA_WIDTH - 1:0] rd_data,
    output logic rd_empty
);
    logic [ADDR_BIT_WIDTH:0] wr_ptr_gray, wr_ptr_gray_sync;
    logic [ADDR_BIT_WIDTH - 1:0] wr_addr;

    logic [ADDR_BIT_WIDTH:0] rd_ptr_gray, rd_ptr_gray_sync;
    logic [ADDR_BIT_WIDTH - 1:0] rd_addr;

    // write pointer module
    wr_ptr #(.WR_ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) wr_ptr_handler (
        .wr_clk(wr_clk),
        .wr_resetn(wr_resetn),
        .wr_inc(wr_inc),
        .rd_ptr_gray_sync(rd_ptr_gray_sync),
        .wr_full(wr_full),
        .wr_addr(wr_addr),
        .wr_ptr_gray(wr_ptr_gray)
    );

    // sync write pointer to the read clock domain
    sync_2ff #(.ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) wr_ptr_2ff (
        .clk(rd_clk),
        .ptr(wr_ptr_gray),
        .resetn(rd_resetn),
        .ptr_synced(wr_ptr_gray_sync)
    );

    // read pointer module
    rd_ptr #(.RD_ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) rd_ptr_handler (
        .rd_clk(rd_clk),
        .rd_resetn(rd_resetn),
        .rd_inc(rd_inc),
        .wr_ptr_gray_sync(wr_ptr_gray_sync),
        .rd_empty(rd_empty),
        .rd_addr(rd_addr),
        .rd_ptr_gray(rd_ptr_gray)
    );

    // sync read pointer to the write clock domain
    sync_2ff #(.ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) rd_ptr_2ff (
        .clk(wr_clk),
        .ptr(rd_ptr_gray),
        .resetn(wr_resetn),
        .ptr_synced(rd_ptr_gray_sync)
    );

    // memory array of the FIFO
    fifo_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH)) mem (
        .wr_clk(wr_clk),
        .wr_en(wr_inc && !wr_full),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_inc && !rd_empty),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

endmodule
