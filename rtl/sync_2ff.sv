// 2-flop synchronizer for crossing pointers to the other clock domain
module sync_2ff #(
    parameter int ADDR_BIT_WIDTH = 5
) (
    input logic clk,
    input logic [ADDR_BIT_WIDTH:0] ptr,
    input logic resetn,
    output logic [ADDR_BIT_WIDTH:0] ptr_synced
);
    logic [ADDR_BIT_WIDTH:0] ptr_sync_intermediate;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            ptr_sync_intermediate <= '0;
            ptr_synced <= '0;
        end
        else begin
            ptr_sync_intermediate <= ptr;
            ptr_synced <= ptr_sync_intermediate;
        end
    end

endmodule
