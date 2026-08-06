`timescale 1ns/1ps

module Arbiter_tb;
    reg clk;
    reg reset;
    reg [35:0] rx_data;
    reg [3:0] valid_input;
    reg tx_payload_active;

    wire [7:0] tx_data;
    wire active_transmit;
    wire [3:0] rx_grant;

    Arbiter uut (
        .clk(clk), .reset(reset),
        .rx_data(rx_data), .valid_input(valid_input), .tx_payload_active(tx_payload_active),
        .tx_data(tx_data), .active_transmit(active_transmit), .rx_grant(rx_grant)
    );

    // 125 MHz Clock
    always #4 clk = ~clk;

    initial begin
        $dumpfile("Arbiter_tb.vcd");
        $dumpvars(0, Arbiter_tb);

        // Initialize signals
        clk = 0; reset = 1;
        rx_data = 36'h0; valid_input = 4'b0000; tx_payload_active = 0;

        #20 reset = 0; #10;

        $display("=== STARTING ARBITER HARD-BRAKE TEST ===");

        // Port 0 Requests Access
        @(negedge clk); 
        valid_input = 4'b0001; 
        rx_data = {27'h0, 1'b0, 8'hAB}; // Standard payload byte (9th bit LOW)
        tx_payload_active = 1; 

        @(negedge clk) rx_data = {27'h0, 1'b0, 8'hCD}; // Standard payload byte
        
        // THE TEST: Trigger EOF (9th bit HIGH)
        // We want to see RX Grant and Active Transmit drop combinationally on this exact cycle.
        @(negedge clk) rx_data = {27'h0, 1'b1, 8'hEF}; // EOF byte

        // The exact next clock cycle, simulate the upstream modules dropping the route
        @(negedge clk) begin
            rx_data = 36'h0;
            valid_input = 4'b0000; 
        end

        // Wait a few cycles to ensure it stays asleep
        #30;

        $display("=== ARBITER TEST COMPLETE ===");
        $finish;
    end

    // Egress Monitor (Now also monitoring the 9th bit directly)
    always @(posedge clk) begin
        $display("[Time %0t] TX Data: %h | RX Grant: %b | Active Transmit Flag: %b | 9th Bit: %b", 
                 $time, tx_data, rx_grant, active_transmit, rx_data[8]);
    end
endmodule