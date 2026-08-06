`timescale 1ns/1ps

module Top_module_tb;

    reg clk;
    reg reset;

    // Port 0 physical pins
    reg  [7:0] gmii_rx_data_0;
    reg        gmii_rx_dv_0;
    wire [7:0] gmii_tx_data_0;
    wire       gmii_tx_en_0;

    // Tie off Ports 1-3 for testbench brevity
    wire [7:0] gmii_tx_data_1, gmii_tx_data_2, gmii_tx_data_3;
    wire       gmii_tx_en_1, gmii_tx_en_2, gmii_tx_en_3;

    Top_module dut (
        .clk(clk), .reset(reset),
        .gmii_rx_data_0(gmii_rx_data_0), .gmii_rx_dv_0(gmii_rx_dv_0),
        .gmii_tx_data_0(gmii_tx_data_0), .gmii_tx_en_0(gmii_tx_en_0),
        
        .gmii_rx_data_1(8'h0), .gmii_rx_dv_1(1'b0), .gmii_tx_data_1(gmii_tx_data_1), .gmii_tx_en_1(gmii_tx_en_1),
        .gmii_rx_data_2(8'h0), .gmii_rx_dv_2(1'b0), .gmii_tx_data_2(gmii_tx_data_2), .gmii_tx_en_2(gmii_tx_en_2),
        .gmii_rx_data_3(8'h0), .gmii_rx_dv_3(1'b0), .gmii_tx_data_3(gmii_tx_data_3), .gmii_tx_en_3(gmii_tx_en_3)
    );

    always #4 clk = ~clk; 

    integer i;

    initial begin
        $dumpfile("Top_module_tb.vcd");
        $dumpvars(0, Top_module_tb);

        clk = 0; reset = 1;
        gmii_rx_data_0 = 8'h00; gmii_rx_dv_0 = 0;

        #20 reset = 0; #20;

        $display("=== STARTING FULL SYSTEM INTEGRATION TEST ===");
        
        @(negedge clk) gmii_rx_dv_0 = 1;
        
        for (i = 0; i < 7; i = i + 1) begin
            gmii_rx_data_0 = 8'h55; @(negedge clk);
        end

        gmii_rx_data_0 = 8'hD5; @(negedge clk);

        // Dest MAC (Matches Port 0's broadcast default for test routing)
        gmii_rx_data_0 = 8'hFF; @(negedge clk);
        gmii_rx_data_0 = 8'hFF; @(negedge clk);
        gmii_rx_data_0 = 8'hFF; @(negedge clk);
        gmii_rx_data_0 = 8'hFF; @(negedge clk);
        gmii_rx_data_0 = 8'hFF; @(negedge clk);
        gmii_rx_data_0 = 8'hFF; @(negedge clk);

        // Source MAC 
        gmii_rx_data_0 = 8'hAA; @(negedge clk);
        gmii_rx_data_0 = 8'hBB; @(negedge clk);
        gmii_rx_data_0 = 8'hCC; @(negedge clk);
        gmii_rx_data_0 = 8'hDD; @(negedge clk);
        gmii_rx_data_0 = 8'hEE; @(negedge clk);
        gmii_rx_data_0 = 8'hFF; @(negedge clk);

        // EtherType
        gmii_rx_data_0 = 8'h08; @(negedge clk);
        gmii_rx_data_0 = 8'h00; @(negedge clk);

        // Payload
        for (i = 0; i < 15; i = i + 1) begin
            gmii_rx_data_0 = i + 8'h10; 
            @(negedge clk);
        end

        gmii_rx_dv_0 = 0;
        gmii_rx_data_0 = 8'h00;

        $display("Frame injection complete. Flushing core pipeline & calculating FCS...");
        
        #500;

        $display("=== SYSTEM INTEGRATION TEST COMPLETE ===");
        $finish;
    end

    // Egress Monitor
    always @(posedge clk) begin
        if (gmii_tx_en_0) begin
            $display("[Time %0t] Egress Active - Transmitting Data: %h", $time, gmii_tx_data_0);
        end
    end

endmodule