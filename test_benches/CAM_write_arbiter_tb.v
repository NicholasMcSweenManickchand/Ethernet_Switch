`timescale 1ns/1ps

module CAM_Write_Arbiter_tb;
    reg clk, reset;
    
    reg we_0, we_1, we_2, we_3;
    reg [47:0] mac_0, mac_1, mac_2, mac_3;
    reg [3:0] port_0, port_1, port_2, port_3;
    
    wire cam_we;
    wire [47:0] cam_write_mac;
    wire [3:0] cam_write_port;

    CAM_Write_Arbiter u1(
        .clk(clk), .reset(reset),
        .we_0(we_0), .mac_0(mac_0), .port_0(port_0),
        .we_1(we_1), .mac_1(mac_1), .port_1(port_1),
        .we_2(we_2), .mac_2(mac_2), .port_2(port_2),
        .we_3(we_3), .mac_3(mac_3), .port_3(port_3),
        .cam_we(cam_we), .cam_write_mac(cam_write_mac), .cam_write_port(cam_write_port)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("CAM_Write_Arbiter_tb.vcd");
        $dumpvars(0, CAM_Write_Arbiter_tb);

        clk = 0; reset = 1;
        we_0 = 0; we_1 = 0; we_2 = 0; we_3 = 0;
        mac_0 = 48'hA; mac_1 = 48'hB; mac_2 = 48'hC; mac_3 = 48'hD;
        port_0 = 4'd0; port_1 = 4'd1; port_2 = 4'd2; port_3 = 4'd3;

        #10;
        reset = 0;
        #10;

        // Port 1 and Port 2 fire in the exact same cycle
        @(negedge clk) begin
            we_1 = 1;
            we_2 = 1;
        end
        
        // Cycle 1: The Arbiter latches the requests internally. Output is still 0.
        @(negedge clk) begin
            we_1 = 0;
            we_2 = 0;
            $display("Arbitration Cycle 1 (Latch Stage)   : Writing MAC %h to port %d (we: %b)", cam_write_mac, cam_write_port, cam_we);
        end
        
        // Cycle 2: The Arbiter services Port 1.
        @(negedge clk) begin
            $display("Arbitration Cycle 2 (Service Port 1): Writing MAC %h to port %d (we: %b)", cam_write_mac, cam_write_port, cam_we);
        end
        
        // Cycle 3: The Arbiter services Port 2 from its internal buffer.
        @(negedge clk) begin
            $display("Arbitration Cycle 3 (Service Port 2): Writing MAC %h to port %d (we: %b)", cam_write_mac, cam_write_port, cam_we);
        end
        
        // Cycle 4: Both flags are cleared. The Arbiter drops 'we' to protect memory.
        @(negedge clk) begin
            $display("Arbitration Cycle 4 (Idle/Clear)    : we: %b (Expected 0)", cam_we);
        end

        $finish;
    end
endmodule