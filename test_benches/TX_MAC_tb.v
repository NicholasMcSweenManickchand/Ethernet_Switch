`timescale 1ns/1ps

module TX_MAC_tb;
    reg clk, reset;
    reg tx_active; // Replaces rx_control_signal
    reg [31:0] FCS_data;
    reg [7:0] rx_data;
    
    wire [7:0] tx_data;
    wire tx_en;          // NEW output
    wire payload_active; // NEW output

    TX_MAC u1(
        .clk(clk),
        .reset(reset),
        .tx_active(tx_active),
        .FCS_data(FCS_data),
        .rx_data(rx_data),
        .tx_data(tx_data),
        .tx_en(tx_en),
        .payload_active(payload_active)
    );

    always #4 clk = ~clk; // 125MHz clock

    integer i;

    initial begin
        $dumpfile("TX_MAC_tb.vcd");
        $dumpvars(0, TX_MAC_tb);

        tx_active = 0;
        reset = 1;
        clk = 0;
        FCS_data = 32'hABCDEF12;
        rx_data = 8'h1A;
        
        #8;
        reset = 0;
        
        @(negedge clk);
        // Arbiter grants access
        tx_active = 1;
        
        // Let it run through Preamble (7), SFD (1), and some Data
        for (i = 0; i < 15; i = i + 1) begin
            @(negedge clk) begin
                $display("state: %d, tx_data: %h, tx_en: %b, payload_active: %b", 
                         u1.state, tx_data, tx_en, payload_active);
            end
        end
        
        // Arbiter drops lock (EOF hit)
        @(negedge clk) begin
            tx_active = 0;
            $display("--- tx_active dropped, expecting FCS_PUSH ---");
        end
        
        // Run through FCS (4 cycles) and IPG_WAIT (12 cycles)
        for (i = 0; i < 20; i = i + 1) begin
            @(negedge clk) begin
                $display("state: %d, tx_data: %h, tx_en: %b, IPG_count: %d", 
                         u1.state, tx_data, tx_en, u1.counter_IPG);
            end
        end

        $finish;
    end
endmodule