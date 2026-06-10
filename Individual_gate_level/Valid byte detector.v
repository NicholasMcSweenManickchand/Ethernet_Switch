`default_nettype none
module valid_byte_detector(
    input wire [7:0] rx_data,
    input  wire rx_control_signal, clk, reset,
    output reg [7:0] tx_data,
    output reg  tx_valid
);

localparam ON = 1'b1, OFF = 1'b0;
reg start_valid;

always @(posedge clk)begin
    if (reset)begin
        tx_data <= 8'd0;
        start_valid <= OFF;
        tx_valid <= OFF;
    end
    else begin
        if (!rx_control_signal) begin
            start_valid <= OFF;
        end
        else if (rx_data == 8'hD5) begin
            start_valid <= ON;
        end
        if (start_valid && rx_control_signal)begin 
        /* this means that once we get the green light byte (0xD5),
         the next clock cycle we tell the module to turn the input into an output, since this is now a valid data-filled input
         and it also tells the next modules that the input is indeed valid and data-filled instead of garbage because of the tx_valid.
        */
            tx_valid <= ON;
            tx_data <= rx_data;
        end
        else begin
            tx_valid <= OFF;
        end
    end
end

endmodule
