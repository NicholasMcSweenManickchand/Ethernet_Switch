`timescale 1ns/1ps


module Arbiter_tb;

    reg [31:0] rx_data;
    reg [3:0] valid_input, control_signal;
    reg clk, reset;
    wire [7:0] tx_data;

    Arbiter u1(
        .rx_data(rx_data),
        .valid_input(valid_input),
        .control_signal(control_signal),
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data)
    );

    always #5 clk = ~clk;

    integer i, j;

    initial begin
        reset = 1;
        valid_input = 0;
        control_signal = 0;
        rx_data = 8'h0;

        #10;

        reset = 0;
        rx_data[7:0] = 8'h0;
        rx_data[15:8] = 8'h1;
        rx_data[23:16] = 8'h2;
        rx_data[31:24] = 8'h3;
        
        $display("rx_data = %h", rx_data);

        for (i = 0; i < 16; i = i + 1) begin
            valid_input = i;  // worst case: every port is sending data

            for (j = 0; j < 16; j = j + 1) begin
                control_signal = j;
                #10;
                $display("valid_input: %b, control_signal: %b, tx_data: %b, rx_data: %h", valid_input, control_signal, tx_data, rx_data);
            end
            #10;
            $display("END OF j LOOP!!!");
        end
        $stop;
    end
endmodule