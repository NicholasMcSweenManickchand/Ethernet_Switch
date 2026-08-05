`timescale 1ns/1ps

module Switch_Top_tb;

    // --- Global Signals ---
    reg clk;
    reg reset;

    // --- Physical GMII Interfaces (External Pins) ---
    // Port 0
    reg  [7:0] gmii_rx_data_0;
    reg        gmii_rx_dv_0;
    wire [7:0] gmii_tx_data_0;
    wire       gmii_tx_en_0;

    // Port 1
    reg  [7:0] gmii_rx_data_1;
    reg        gmii_rx_dv_1;
    wire [7:0] gmii_tx_data_1;
    wire       gmii_tx_en_1;

    // Port 2
    reg  [7:0] gmii_rx_data_2;
    reg        gmii_rx_dv_2;
    wire [7:0] gmii_tx_data_2;
    wire       gmii_tx_en_2;

    // Port 3
    reg  [7:0] gmii_rx_data_3;
    reg        gmii_rx_dv_3;
    wire [7:0] gmii_tx_data_3;
    wire       gmii_tx_en_3;

    // --- Instantiate the Top-Level Switch ---
    Switch_Top dut (
        .clk(clk), .reset(reset),
        
        .gmii_rx_data_0(gmii_rx_data_0), .gmii_rx_dv_0(gmii_rx_dv_0),
        .gmii_tx_data_0(gmii_tx_data_0), .gmii_tx_en_0(gmii_tx_en_0),
        
        .gmii_rx_data_1(gmii_rx_data_1), .gmii_rx_dv_1(gmii_rx_dv_1),
        .gmii_tx_data_1(gmii_tx_data_1), .gmii_tx_en_1(gmii_tx_en_1),
        
        .gmii_rx_data_2(gmii_rx_data_2), .gmii_rx_dv_2(gmii_rx_dv_2),
        .gmii_tx_data_2(gmii_tx_data_2), .gmii_tx_en_2(gmii_tx_en_2),
        
        .gmii_rx_data_3(gmii_rx_data_3), .gmii_rx_dv_3(gmii_rx_dv_3),
        .gmii_tx_data_3(gmii_tx_data_3), .gmii_tx_en_3(gmii_tx_en_3)
    );

    // 125 MHz clock for 1 Gbps GMII Ethernet timing
    always #4 clk = ~clk; 

    integer i;

    initial begin
        $dumpfile("Switch_Top_tb.vcd");
        $dumpvars(0, Switch_Top_tb);

        // Initialization
        clk = 0;
        reset = 1;

        gmii_rx_data_0 = 8'h00; gmii_rx_dv_0 = 0;
        gmii_rx_data_1 = 8'h00; gmii_rx_dv_1 = 0;
        gmii_rx_data_2 = 8'h00; gmii_rx_dv_2 = 0;
        gmii_rx_data_3 = 8'h00; gmii_rx_dv_3 = 0;

        #20;
        reset = 0;
        #20;

        $display("=== STARTING SYSTEM INTEGRATION TEST ===");
        $display("Injecting valid Ethernet frame into Port 0...");

        // Assert RX Data Valid
        @(negedge clk) gmii_rx_dv_0 = 1;
        
        // 1. Preamble (7 bytes of 0x55)
        for (i = 0; i < 7; i = i + 1) begin
            gmii_rx_data_0 = 8'h55;
            @(negedge clk);
        end

        // 2. Start Frame Delimiter (1 byte of 0xD5)
        gmii_rx_data_0 = 8'hD5;
        @(negedge clk);

        // 3. Destination MAC Address (e.g., 00:11:22:33:44:55)
        gmii_rx_data_0 = 8'h00; @(negedge clk);
        gmii_rx_data_0 = 8'h11; @(negedge clk);
        gmii_rx_data_0 = 8'h22; @(negedge clk);
        gmii_rx_data_0 = 8'h33; @(negedge clk);
        gmii_rx_data_0 = 8'h44; @(negedge clk);
        gmii_rx_data_0 = 8'h55; @(negedge clk);

        // 4. Source MAC Address (e.g., AA:BB:CC:DD:EE:FF)
        gmii_rx_data_0 = 8'hAA; @(negedge clk);
        gmii_rx_data_0 = 8'hBB; @(negedge clk);
        gmii_rx_data_0 = 8'hCC; @(negedge clk);
        gmii_rx_data_0 = 8'hDD; @(negedge clk);
        gmii_rx_data_0 = 8'hEE; @(negedge clk);
        gmii_rx_data_0 = 8'hFF; @(negedge clk);

        // 5. EtherType (e.g., 0x0800 for IPv4)
        gmii_rx_data_0 = 8'h08; @(negedge clk);
        gmii_rx_data_0 = 8'h00; @(negedge clk);

        // 6. Payload (Dummy sequence starting at 0x10)
        for (i = 0; i < 15; i = i + 1) begin
            gmii_rx_data_0 = i + 8'h10; 
            @(negedge clk);
        end

        // End of frame transmission
        gmii_rx_dv_0 = 0;
        gmii_rx_data_0 = 8'h00;

        $display("Frame injection complete. Flushing core pipeline...");
        
        // Wait long enough for the ingress path, crossbar, and egress path to finish their states
        #250;

        $display("=== SYSTEM INTEGRATION TEST COMPLETE ===");
        $finish;
    end

    // --- Active Output Monitor ---
    // Tracks any data successfully emerging from the cut-through egress path
    always @(posedge clk) begin
        if (gmii_tx_en_0) begin
            $display("[Time %0t] Port 0 TX Active - Broadcasting Data: %h", $time, gmii_tx_data_0);
        end
    end

endmodule