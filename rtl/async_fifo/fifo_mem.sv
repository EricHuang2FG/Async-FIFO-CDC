// memory array handler for the Async FIFO 
module fifo_mem #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_BIT_WIDTH = 5
) (
    input logic wr_clk,
    input logic wr_en,
    input logic [ADDR_BIT_WIDTH - 1:0] wr_addr,
    input logic [DATA_WIDTH - 1: 0] wr_data,
    input logic rd_en,
    input logic [ADDR_BIT_WIDTH - 1:0] rd_addr,
    output logic [DATA_WIDTH - 1:0] rd_data
);
    logic [DATA_WIDTH - 1:0] mem [2 ** ADDR_BIT_WIDTH - 1:0]; // the depth is 2 to the power of the binary bit width
    
    // handle data reading
    assign rd_data = rd_en ? mem[rd_addr] : '0;

    // handle data writing
    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

endmodule
