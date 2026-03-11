`timescale 1ns/1ps


module Arbiter_tb;

    reg [31:0] rx_data;
    reg [3:0] valid_input;
    reg clk, reset;
    wire [7:0] tx_data;

    Arbiter u1(
        .rx_data(rx_data),
        .valid_input(valid_input),
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data)
    );

    always #5 clk = ~clk;

    integer i, j;

    initial begin
        clk = 0;
        reset = 1;
        valid_input = 0;
        rx_data = 8'h0;

        #10;

        reset = 0;
        rx_data[7:0] = 8'hAA;
        rx_data[15:8] = 8'hBB;
        rx_data[23:16] = 8'hCC;
        rx_data[31:24] = 8'hDD;
        
        $display("rx_data = %h", rx_data);

        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk)begin
                valid_input = i;  // worst case: every port is sending data
            end
            @(posedge clk)begin
                // wait 1 clock cycle (lag)
             end

            @(posedge clk)begin
                $display("valid_input: %b, tx_data: %h", valid_input, tx_data);
            end
        end
        $stop;
    end
endmodule