// handles 6-bit write pointer logic, ouputs write address, FIFO full flag, 
// and the gray-coded write pointer for the 32-bit Async FIFO
module wr_ptr #(
    parameter int WR_ADDR_BIT_WIDTH = 5
) (
    input logic wr_clk,
    input logic wr_resetn,
    input logic wr_inc,
    input logic [WR_ADDR_BIT_WIDTH:0] rd_ptr_gray_sync, // 6-bit input read pointer already gray-coded and 2FF synced
    output logic wr_full,
    output logic [WR_ADDR_BIT_WIDTH - 1:0] wr_addr,
    output logic [WR_ADDR_BIT_WIDTH:0] wr_ptr_gray // 6-bit gray-coded write pointer
);
    logic [WR_ADDR_BIT_WIDTH:0] wr_ptr;

    // compute next 6-bit write pointer 
    logic [WR_ADDR_BIT_WIDTH:0] wr_ptr_next;
    assign wr_ptr_next = (wr_inc && !wr_full) ? wr_ptr + 1 : wr_ptr;

    // compute next gray-coded 6-bit write pointer
    logic [WR_ADDR_BIT_WIDTH:0] wr_ptr_gray_next;
    assign wr_ptr_gray_next = (wr_ptr_next >> 1) ^ wr_ptr_next;

    // check if FIFO is full/set next full signal
    // lower 4 bits equal and the two MSB both do not equal, meaning that it is full and not empty
    logic wr_full_next;
    assign wr_full_next = (
        wr_ptr_gray_next[WR_ADDR_BIT_WIDTH - 2:0] == rd_ptr_gray_sync[WR_ADDR_BIT_WIDTH - 2:0] &&
        ~wr_ptr_gray_next[
            WR_ADDR_BIT_WIDTH:WR_ADDR_BIT_WIDTH - 1
        ] == rd_ptr_gray_sync[
            WR_ADDR_BIT_WIDTH:WR_ADDR_BIT_WIDTH - 1
        ]
    );

    // register values
    always_ff @(posedge wr_clk) begin
        if (!wr_resetn) begin
            wr_ptr <= '0;
            wr_ptr_gray <= '0;
            wr_full <= 1'b0;
        end
        else begin
            wr_ptr <= wr_ptr_next;
        
            // register the gray-coded pointer
            wr_ptr_gray <= wr_ptr_gray_next;

            // register the full signal
            wr_full <= wr_full_next;
        end
    end

    // set the output 5-bit write address
    assign wr_addr = wr_ptr[WR_ADDR_BIT_WIDTH - 1:0];

endmodule
