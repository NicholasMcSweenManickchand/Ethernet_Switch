module TX_MAC_tv;
    reg rx_control_signal, clk, reset;
    reg [31:0] FCS_data;
    reg [7:0] rx_data;
    wire [7:0] tx_data;

    TX_MAC u1(
        .rx_control_signal(rx_control_signal),
        .clk(clk),
        .reset(reset),
        .FCS_data(FCS_data),
        .rx_data(rx_data),
        .tx_data(tx_data)
    );

    always #4 clk = ~clk; // 4 makes period = 8 which = 125MHz clock

    integer i;

    initial begin

        rx_control_signal = 0;
        reset = 1;
        clk = 0;
        FCS_data = 32'hABCDEF12;
        rx_data = 8'h1A;
        #8;
        rx_control_signal = 1;
        @(negedge clk) begin
            $display ("out with reset on and rx_control high: %h", tx_data);
        end
        reset = 0;
        @(negedge clk) begin
            $display ("counter_IPG with reset off: %b", u1.counter_IPG);
        end
        for (i = 0; i < 40; i = i + 1) begin
            @(negedge clk) begin
            $display("state: %d, next_state: %d", u1.state, u1.next_state);
            $display ("counter_IPG: %b, counter_preamble: %b, counter_FCS: %b", u1.counter_IPG, u1.counter_preamble, u1.counter_FCS);
            $display("out: %h", tx_data);
            if (i > 19)begin
                rx_control_signal = 0;
                $display("rx_control signal is now 0");
            end
        end
        end
    $stop;
    end
endmodule
        


