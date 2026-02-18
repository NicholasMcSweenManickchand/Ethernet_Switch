`timescale 1ns/1ps

module valid_byte_detector_tb;

reg [7:0] in_data; 
wire [7:0] out_data;
reg control_signal, clk, reset;
wire out_valid;



valid_byte_detector u1(
    .rx_data(in_data),
    .rx_control_signal(control_signal),
    .reset(reset),
    .clk(clk),
    .tx_data(out_data),
    .tx_valid(out_valid)
);

integer i;

always #5 clk = ~clk;

initial begin

    
    $dumpfile("valid_byte_detector_tb.vcd");
    $dumpvars(0, valid_byte_detector_tb);

    clk = 0;
    reset = 0;
    in_data = 0;
    control_signal = 0;
    
    #10;

    reset = 1;

    #100;
    reset = 0;
    #30;

    $display("Starting packet injection:");

    #10;
    control_signal = 1;
    #10;

    in_data = 'hAA; //10101010
    $display("in: 0xAA. Out: %d, out_valid: %d", out_data, out_valid);
    #10;
    in_data = 'hAA; //10101010
    $display("in: 0xAA. Out: %d, out_valid: %d", out_data, out_valid);
    #10;
    in_data = 'hAA; //10101010
    $display("in: 0xAA. Out: %d, out_valid: %d", out_data, out_valid);
    #10;
    in_data = 'hDD;
    $display("in: 0xDD. Out: %d, out_valid: %d", out_data, out_valid);
    #10;
    in_data = 'h90;
    $display("in: 0x90. Out: %d, out_valid: %d", out_data, out_valid);
    #10;
    in_data = 'hD5; //11010101 so start
    $display("in: 0xD5. Out: %d, out_valid: %d", out_data, out_valid);
    $display("Should start displaying now!");
    #10;
    in_data = 0;
    $display("in: 0x0. Out: %d, out_valid: %d", out_data, out_valid);
    #10;
    $display("Now for-looping all possible values (inlcuding 256 to see truncation effect)");
    #50;
    for(i=1; i<=256; i = i+1) begin
        in_data = i;
        #10;
        $display("in: %h (decimal: %d), Out: %d, out_valid: %d", i, i, out_data, out_valid);
        #10;
    end
    $stop;
end

endmodule