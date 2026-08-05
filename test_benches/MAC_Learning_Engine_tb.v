`timescale 1ns/1ps

module MAC_Learning_Engine_tb;
    reg clk, reset;
    reg [47:0] MAC_source_address;
    reg MAC_sc_complete;
    reg [3:0] source_port;
    
    wire cam_we;
    wire [47:0] cam_write_mac;
    wire [3:0] cam_write_port;

    MAC_Learning_Engine u1(
        .clk(clk), .reset(reset),
        .MAC_source_address(MAC_source_address),
        .MAC_sc_complete(MAC_sc_complete),
        .source_port(source_port),
        .cam_we(cam_we),
        .cam_write_mac(cam_write_mac),
        .cam_write_port(cam_write_port)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("MAC_Learning_Engine_tb.vcd");
        $dumpvars(0, MAC_Learning_Engine_tb);

        clk = 0;
        reset = 1;
        MAC_source_address = 48'h0;
        MAC_sc_complete = 0;
        source_port = 4'b0001; // Port 1
        
        #10;
        reset = 0;
        #10;

        // Parser hits byte 11
        @(negedge clk) begin
            MAC_source_address = 48'h12_34_56_78_9A_BC;
            MAC_sc_complete = 1; 
        end
        
        @(negedge clk) $display("cam_we (Cycle 1): %b", cam_we);
        @(negedge clk) $display("cam_we (Cycle 2 - Should be 0): %b", cam_we);
        
        $finish;
    end
endmodule