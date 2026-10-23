module deserializer #(
    parameter int DATA_WIDTH = 8
) (
    input logic bit_clk,
    input logic resetn,
    input logic serial_in,
    input logic word_start,
    output logic [DATA_WIDTH - 1:0] fifo_data_out,
    output logic fifo_wr_inc
);

    logic [DATA_WIDTH - 1:0] shift_register;
    logic [$clog2(DATA_WIDTH):0] num_bits_shifted;

    always_ff @(posedge bit_clk) begin
        if (!resetn) begin
            shift_register <= '0;
            num_bits_shifted <= DATA_WIDTH; // idle position
            fifo_wr_inc <= 1'b0;
        end
        else if (word_start || num_bits_shifted < DATA_WIDTH - 1) begin
            // shift serial_in data into top bit
            // note that even in the case that shift_register holds past values
            // this is fine because they will get shifted out regardless
            shift_register <= {serial_in, shift_register[DATA_WIDTH - 1:1]};
            num_bits_shifted <= (num_bits_shifted == DATA_WIDTH) ? 1'b1 : num_bits_shifted + 1;
            fifo_wr_inc <= 1'b0;
        end
        else if (num_bits_shifted == DATA_WIDTH - 1) begin
            fifo_data_out <= {serial_in, shift_register[DATA_WIDTH - 1:1]};
            num_bits_shifted <= DATA_WIDTH; // set to DATA_WIDTH so no more new bits are shifted in
            // until the next word_start flag is seen
            fifo_wr_inc <= 1'b1;
        end
        else // num_bits_shifted >= DATA_WIDTH
            fifo_wr_inc <= 1'b0;
    end

endmodule
