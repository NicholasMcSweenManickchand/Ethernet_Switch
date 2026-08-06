`timescale 1ns/1ps

module byte_parser_tb;
    reg clk;
    reg reset;
    reg [7:0] rx_data;
    reg rx_valid;
    reg rx_control_signal;

    wire [47:0] MAC_destination_address;
    wire [47:0] MAC_source_address;
    wire MAC_des_complete;
    wire MAC_sc_complete;
    wire [7:0] tx_true_data;
    wire true_data_valid;

    byte_parser uut (
        .clk(clk), .reset(reset),
        .rx_data(rx_data), .rx_valid(rx_valid), .rx_control_signal(rx_control_signal),
        .MAC_destination_address(MAC_destination_address),
        .MAC_source_address(MAC_source_address),
        .MAC_des_complete(MAC_des_complete),
        .MAC_sc_complete(MAC_sc_complete),
        .tx_true_data(tx_true_data),
        .true_data_valid(true_data_valid)
    );

    always #4 clk = ~clk;

    integer i;

    initial begin
        $dumpfile("byte_parser_tb.vcd");
        $dumpvars(0, byte_parser_tb);

        clk = 0; reset = 1;
        rx_data = 8'h00; rx_valid = 0; rx_control_signal = 0;

        #20 reset = 0; #10;

        $display("=== STARTING PARSER VBD-TRUST TEST ===");
        
        // Link goes active, but VBD hasn't validated data yet
        @(negedge clk) rx_control_signal = 1; 

        // Simulating the time the VBD spends eating the Preamble and SFD
        for (i=0; i<8; i=i+1) begin
            rx_data = 8'h00; rx_valid = 0; @(negedge clk);
        end

        // The VBD sees the first byte of the Dest MAC and asserts rx_valid!
        rx_valid = 1;

        // Dest MAC (00:11:22:33:44:55)
        rx_data = 8'h00; @(negedge clk);
        rx_data = 8'h11; @(negedge clk);
        rx_data = 8'h22; @(negedge clk);
        rx_data = 8'h33; @(negedge clk);
        rx_data = 8'h44; @(negedge clk);
        rx_data = 8'h55; @(negedge clk);

        // Source MAC (AA:BB:CC:DD:EE:FF)
        rx_data = 8'hAA; @(negedge clk);
        rx_data = 8'hBB; @(negedge clk);
        rx_data = 8'hCC; @(negedge clk);
        rx_data = 8'hDD; @(negedge clk);
        rx_data = 8'hEE; @(negedge clk);
        rx_data = 8'hFF; @(negedge clk);
        
        // A few payload bytes
        rx_data = 8'h08; @(negedge clk);
        rx_data = 8'h00; @(negedge clk);
        rx_data = 8'h10; @(negedge clk);
        rx_data = 8'h11; @(negedge clk);

        // End of packet
        rx_control_signal = 0; rx_valid = 0; rx_data = 8'h00;
        
        #20 $display("=== PARSER TEST COMPLETE ===");
        $finish;
    end

    always @(posedge clk) begin
        if (rx_control_signal)
            $display("[Time %0t] VBD Output: %h (Valid: %b) | Parser Passing: %h (Valid: %b) | Dest Complete: %b", 
                     $time, rx_data, rx_valid, tx_true_data, true_data_valid, MAC_des_complete);
    end
endmodule