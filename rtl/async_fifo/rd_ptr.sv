// handles 6-bit read pointer logic, ouputs read address, FIFO empty flag, 
// and the gray-coded read pointer for the 32-bit Async FIFO
module rd_ptr #(
    parameter int RD_ADDR_BIT_WIDTH = 5
) (
    input logic rd_clk,
    input logic rd_resetn,
    input logic rd_inc,
    input logic [RD_ADDR_BIT_WIDTH:0] wr_ptr_gray_sync,
    output logic rd_empty,
    output logic [RD_ADDR_BIT_WIDTH - 1:0] rd_addr,
    output logic [RD_ADDR_BIT_WIDTH:0] rd_ptr_gray // 6-bit gray-coded read pointer
);
    logic [RD_ADDR_BIT_WIDTH:0] rd_ptr;

    // compute next 6-bit read pointer
    logic [RD_ADDR_BIT_WIDTH:0] rd_ptr_next;
    assign rd_ptr_next = (rd_inc && !rd_empty) ? rd_ptr + 1: rd_ptr;

    // compute next gray-coded 6-bit read pointer
    logic [RD_ADDR_BIT_WIDTH:0] rd_ptr_gray_next;
    assign rd_ptr_gray_next = (rd_ptr_next >> 1) ^ rd_ptr_next;

    // check if FIFO is empty and compute the next empty signal
    // all 6-bits of the gray-coded read and write pointers must equal
    logic rd_empty_next;
    assign rd_empty_next = rd_ptr_gray_next == wr_ptr_gray_sync;

    // register computed values
    always_ff @(posedge rd_clk) begin
        if (!rd_resetn) begin
            rd_ptr <= '0;
            rd_ptr_gray <= '0;
            rd_empty <= 1'b1;
        end
        else begin
            rd_ptr <= rd_ptr_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            rd_empty <= rd_empty_next;
        end
    end

    // set output 5-bit read address
    assign rd_addr = rd_ptr[RD_ADDR_BIT_WIDTH - 1:0];

endmodule
