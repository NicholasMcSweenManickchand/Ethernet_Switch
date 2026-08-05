`timescale 1ns/1ps

module Ingress_FCS_Checker_tb;
    reg clk, reset, valid_data, eof;
    reg [7:0] data;
    wire poison;

    Ingress_FCS_Checker u1(
        .clk(clk),
        .reset(reset),
        .data(data),
        .valid_data(valid_data),
        .eof(eof),
        .poison(poison)
    );

    always #4 clk = ~clk;

    initial begin
        $dumpfile("Ingress_FCS_Checker_tb.vcd");
        $dumpvars(0, Ingress_FCS_Checker_tb);

        clk = 0;
        reset = 1;
        valid_data = 0;
        eof = 0;
        data = 0;
        #8;
        reset = 0;

        // Stream some data
        @(negedge clk) begin valid_data = 1; data = 8'h31; end
        @(negedge clk) data = 8'h32; 
        @(negedge clk) data = 8'h33;
        
        // Pulse EOF
        @(negedge clk) eof = 1; 
        @(negedge clk) begin
            eof = 0; 
            valid_data = 0; 
        end
        
        #10;
        $display("Poison flag after bad data: %b (Expected 1)", poison);
        
        $finish;
    end
endmodule