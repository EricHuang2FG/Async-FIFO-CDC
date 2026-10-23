module prbs7_generator #(
    parameter int DATA_WIDTH = 8,
    parameter logic [6:0] SEED = 7'b1111111
) (
    input logic clk,
    input logic resetn,
    input logic enable,
    output logic [DATA_WIDTH - 1:0] data
);

    // 7 bits because PRBS7
    logic [6:0] state, next_state;

    logic [6:0] state_copy;
    logic new_bit;

    always_comb begin
        state_copy = state;
        data = '0;
        for (int i = 0; i < DATA_WIDTH; i++) begin
            new_bit = state_copy[6] ^ state_copy[5]; // polynomial x^7 + x^6 + 1
            data[i] = new_bit;
            state_copy = {state_copy[5:0], new_bit}; 
            // keep the lower 6 bits of next state and concatenate the new bit
        end
        next_state = state_copy;
    end

    always_ff @(posedge clk) begin
        if (!resetn)
            state <= SEED;
        else if (enable)
            state <= next_state;
    end

endmodule
