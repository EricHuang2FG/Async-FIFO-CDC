module serializer #(
    parameter int DATA_WIDTH = 8
) (
    input logic bit_clk,
    input logic resetn,
    input logic [DATA_WIDTH - 1:0] fifo_data_in,
    input logic fifo_empty,
    output logic fifo_rd_inc,
    output logic serial_out,
    output logic word_start
);

    logic [DATA_WIDTH - 1:0] shift_register;
    logic [$clog2(DATA_WIDTH):0] num_bits_shifted;

    always_ff @(posedge bit_clk) begin
        if (!resetn) begin
            shift_register <= '0;
            serial_out <= 1'b0;
            num_bits_shifted <= '0;
            word_start <= 1'b0;
        end
        else if (!fifo_empty) begin
            if (!num_bits_shifted) begin // put new FIFO data into the shift register while reading the first bit
                shift_register <= {1'b0, fifo_data_in[DATA_WIDTH - 1:1]}; // store remaining input from FIFO into the shift register
                serial_out <= fifo_data_in[0]; // send out first bit
                num_bits_shifted <= num_bits_shifted + 1;
                word_start <= 1'b1; // set the flag that new word is starting
            end
            else if (num_bits_shifted < DATA_WIDTH) begin
                serial_out <= shift_register[0]; // send out the lowest bit
                shift_register <= shift_register >> 1; // right shift away the lowest bit
                num_bits_shifted <= (num_bits_shifted == DATA_WIDTH - 1) ? '0 : num_bits_shifted + 1;
                word_start <= 1'b0;
            end
        end
    end

    // ask for more data when the last bit of data is being sent
    // so that as soon as the next cycle arrives, new data from FIFO is ready to be processed
    assign fifo_rd_inc = num_bits_shifted == (DATA_WIDTH - 1);

endmodule
