`timescale 1ns/1ps

module FIFO_tb;
    reg rx_valid_bytes, control_signal, clk, reset;
    reg allow_output;
    reg [7:0] rx_data;
    wire [7:0] tx_data;

    FIFO u1(
        .rx_valid_bytes(rx_valid_bytes), 
        .control_signal(control_signal), 
        .clk(clk), 
        .reset(reset),
        .allow_output(allow_output),
        .rx_data(rx_data),
        .tx_data(tx_data)
    );

    always #5 clk = ~clk;
    integer i;

    initial begin

        reset = 1;
        clk = 0;
        control_signal = 0;
        rx_valid_bytes = 0;
        allow_output = 0;
        rx_data = 'h06;

        #10;

        reset = 0;

        #30;

        control_signal = 1;
        rx_valid_bytes = 1;

        #10;

        for (i = 0; i < 150; i = i + 3) begin
            rx_data = i;
            #10;
            $display("IN: %d, OUT: %d, out_valid: %d\n", rx_data, tx_data, allow_output);
        end
        #10;
        allow_output = 1;
        $display("allow ouput now on!\n");

        for (i = 0; i < 450; i = i + 3) begin
            rx_data = i;
            #10;
            $display("IN: %d, OUT: %d, out_valid: %d", rx_data, tx_data, allow_output);
        end
        #10;
        $stop;
    end
endmodule

