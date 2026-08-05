`timescale 1ns/1ps

module CAM_tb; 
    reg clk, reset;
    
    // Write Interface
    reg we;
    reg [47:0] write_mac;
    reg [3:0] write_port;

    // Read Interfaces (Just testing 2 of the 4 for brevity)
    reg [47:0] read_mac_0, read_mac_1;
    reg valid_dest_0, valid_dest_1;
    
    wire [3:0] dest_port_0, dest_port_1;

    CAM u1(
        .clk(clk),
        .reset(reset),
        .we(we),
        .write_mac(write_mac),
        .write_port(write_port),
        .read_mac_0(read_mac_0), .read_mac_1(read_mac_1),
        .read_mac_2(48'h0), .read_mac_3(48'h0), // Tie off unused
        .valid_dest_0(valid_dest_0), .valid_dest_1(valid_dest_1),
        .valid_dest_2(1'b0), .valid_dest_3(1'b0),
        .dest_port_0(dest_port_0), .dest_port_1(dest_port_1)
        // dest_port_2 and dest_port_3 left disconnected
    );

    always #5 clk = ~clk;
    
    initial begin
        $dumpfile("CAM_tb.vcd");
        $dumpvars(0, CAM_tb);

        reset = 1;
        clk = 0;
        we = 0;
        write_mac = 0;
        write_port = 0;
        valid_dest_0 = 0;
        valid_dest_1 = 0;
        read_mac_0 = 0;
        read_mac_1 = 0;

        #10;
        reset = 0;
        #10;

        // 1. Write a MAC address to the CAM synchronously
        @(negedge clk) begin
            we = 1;
            write_mac = 48'hAA_BB_CC_DD_EE_FF;
            write_port = 4'b0010; // Port 2
        end
        @(negedge clk) begin
            we = 0; 
        end
        
        #10;
        
        // 2. Read it asynchronously
        valid_dest_0 = 1;
        read_mac_0 = 48'hAA_BB_CC_DD_EE_FF;
        
        valid_dest_1 = 1;
        read_mac_1 = 48'h11_22_33_44_55_66; // Unknown MAC
        
        #5; // Wait a half-tick for combinational logic
        $display("Lookup MAC 0 (Known): Expected Port 2, Got %b", dest_port_0);
        $display("Lookup MAC 1 (Unknown): Expected Port 15 (Broadcast), Got %b", dest_port_1);

        #20;
        $finish;
    end
endmodule