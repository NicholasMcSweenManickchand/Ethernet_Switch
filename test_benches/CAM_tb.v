`timescale 1ns/1ps

module CAM_tb; 
    reg [47:0] MAC_destination, MAC_source;
    reg valid_destination, valid_source, clk, reset;
    wire [3:0] destination_port;

    CAM u1(
        .MAC_destination(MAC_destination),
        .MAC_source(MAC_source),
        .reset(reset),
        .clk(clk),
        .valid_source(valid_source),
        .valid_destination(valid_destination),
        .destination_port(destination_port)
    );

    always #5 clk = ~clk;
    integer i;
    
    initial begin
        reset = 1;
        clk = 0;
        valid_source = 0;
        valid_destination = 0;
        MAC_source = 0;
        MAC_destination = 0;

        #10;
        reset = 0;
        #30;

        valid_destination = 1;
        $display("Valid_destination ON!\n");

        for( i = 0; i < 150; i = i + 1) begin
            @(posedge clk) begin
                MAC_destination = (2*i);
                #10;
                $display("MAC_destination: %h, destination_port: %b\n", MAC_destination, destination_port);
            end
        end
        #20;
        $stop;
    end
endmodule
    

