`timescale 1ns/1ps

module FCS_tb;

    reg [7:0] data;
    reg clk, reset, valid_data; 
    reg done; 
    reg poison; 
    wire [31:0] rx_crc;

    reg display;

    FCS u1(
        .data(data),
        .clk(clk),
        .reset(reset),
        .valid_data(valid_data),
        .done(done),
        .poison(poison), 
        .rx_crc(rx_crc)
    );

    always #4 clk = ~clk;

    integer i;
    reg [31:0] expected_out; 
    reg [31:0] magic_res_FCS;
    wire match;

    assign match = expected_out == rx_crc;
    
    initial begin
        $dumpfile("FCS_tb.vcd");
        $dumpvars(0, FCS_tb);

        clk = 0;
        reset = 0;
        valid_data = 1;
        done = 0;
        display = 0;
        poison = 0; // Default to clean packet

        // empty data (data = h'00):
        data = 8'h00;
        repeat (2) begin
            @(negedge clk) begin
                reset = ~reset; 
                #1;
            end
        end
        $display("data is h'00 and will run for 4 clock cycles:");
        expected_out = 32'h2144DF1C;
        repeat (2) begin 
            @(negedge clk) begin
            end
        end

        @(negedge clk);
        repeat (2) begin
            display = ~display; 
            #1;
        end
        $display("The expected output is: %h", expected_out);
        $display("The actual output is: %h", rx_crc);
        $display("Are they the same? (1 is yes 0 is no): %b", match);

        // standard ASCII test (123456789)
        $display("data is for the ASCII test (123456789) and will run for 9 clock cycles:");
        data = 32'h31;
        reset = 1;
        @(negedge clk) begin
            reset = 0;
        end

        expected_out = 32'hCBF43926;
        repeat (8) begin 
            @(negedge clk) begin
                data = data + 1;
            end
        end
        
        // FREEZE THE ENGINE HERE:
        // Pull valid_data low instantly before the delays let the clock tick forward
        valid_data = 0; 
        
        #1;
        repeat (2) begin
            display = ~display; 
            #1;
        end
        $display("The expected output is: %h", expected_out);
        $display("The actual output is: %h", rx_crc);
        $display("Are they the same? (1 is yes 0 is no): %b", match);
        
        // POISON TEST
        $display("Testing poison flag injection:");
        @(negedge clk) begin
            poison = 1;
            expected_out = ~32'hCBF43926; // Expect the raw (un-inverted) crcOut
        end
        #1;
        $display("The expected output is: %h", expected_out);
        $display("The actual output is: %h", rx_crc);
        $display("Are they the same? (1 is yes 0 is no): %b", match);

        $finish;
    end
endmodule