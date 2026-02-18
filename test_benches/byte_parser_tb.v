`timescale 1ns/1ps

module byte_parser_tb;

wire [47:0] MAC_desitnation, MAC_source;
wire [15:0] MAC_type;
wire [7:0] data_out;
wire MAC_des_complete, MAC_sc_complete, MAC_tp_complete, true_data;
reg clk, reset, control, in_valid;
reg [7:0] data_in;

byte_parser u1(
    .rx_valid(in_valid), 
    .rx_control_signal(control), 
    .reset(reset), 
    .clk(clk),
    .rx_data(data_in),   
    .MAC_destination_address(MAC_desitnation), 
    .MAC_source_address(MAC_source),
    .MAC_type(MAC_type),
    .tx_true_data(data_out),
    .MAC_des_complete(MAC_des_complete),
    .MAC_sc_complete(MAC_sc_complete), 
    .MAC_tp_complete(MAC_tp_complete), 
    .true_data_valid(true_data)
);

always #5 clk = ~clk;

integer i;

initial begin

    $dumpfile("byte_parser.vcd");
    $dumpvars(0, byte_parser_tb);

    clk = 0;
    reset = 1;
    control = 0;
    in_valid = 0;

    #100;

    reset = 0;
    #10;

    $display("Starting packet injection:");
    $display("control & in_valid are off so should yield nothing");
    #10;
    for(i = 0; i < 10; i = i + 1) begin // just enough to prove that it gives nothing with nothing on;
        data_in = i;
        $display("in: %d, MAC_des_out: %h, MAC_sc_out: %h, MAC_tp_out: %h, true_data_out: %h\n", data_in, MAC_desitnation, MAC_source, MAC_type, data_out);
        $display("MAC_des_complete: %h, MAC_sc_complete: %h, MAC_tp_complete: %h, true_data: %h\n", MAC_des_complete, MAC_sc_complete, MAC_tp_complete, true_data);
        #10;
    end
    reset = 1;
    #100;
    reset = 0;
    #30

    control = 1;
    in_valid = 1;
    #10;
    for(i = 0; i < 256; i = i + 1) begin
        data_in = i;
        $display("in: %d, MAC_des_out: %h, MAC_sc_out: %h, MAC_tp_out: %h, true_data_out: %h\n", data_in, MAC_desitnation, MAC_source, MAC_type, data_out);
        $display("MAC_des_complete: %h, MAC_sc_complete: %h, MAC_tp_complete: %h, true_data: %h\n", MAC_des_complete, MAC_sc_complete, MAC_tp_complete, true_data);
        #10;
    end
    $stop;
end
endmodule



    




