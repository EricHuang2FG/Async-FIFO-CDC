module prbs7_checker #(
    parameter int DATA_WIDTH = 8,
    parameter logic [6:0] SEED = 7'b1111111
) (
    input logic clk,
    input logic resetn,
    input logic enable,
    input logic [DATA_WIDTH - 1:0] data,
    output logic [31:0] num_words,
    output logic [31:0] num_errors
);

    // first generate the sequence
    logic [DATA_WIDTH - 1:0] expected_data;
    logic [6:0] state, next_state;

    logic [6:0] state_copy;
    logic new_bit;

    always_comb begin
        state_copy = state;
        expected_data = '0;
        for (int i = 0; i < DATA_WIDTH; i++) begin
            new_bit = state_copy[6] ^ state_copy[5]; // polynomial x^7 + x^6 + 1
            expected_data[i] = new_bit;
            state_copy = {state_copy[5:0], new_bit}; 
            // keep the lower 6 bits of next state and concatenate the new bit
        end
        next_state = state_copy;
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            state <= SEED;
            num_errors <= '0;
            num_words <= '0;
        end
        else if (enable) begin
            state <= next_state;
            if (expected_data !== data) begin
                num_errors <= num_errors + 1;
            end
            num_words <= num_words + 1;
        end
    end

endmodule
