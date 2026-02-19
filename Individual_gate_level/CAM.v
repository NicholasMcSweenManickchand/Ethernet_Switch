module CAM(
    input wire [47:0] MAC_destination, MAC_source, // source data is useless rn but i acknowledge that it exists and will be useful later in more advanced CAM's
    input wire valid_destination, valid_source, clk, reset, //if control signal is off then valid_* is also off so no need to include it
    output reg [3:0] destination_port
);

localparam Port_A = 4'b0001, Port_B = 4'b0010, Port_C = 4'b0100, Port_D = 4'b1000;  // one hot to allow multicasting later on
localparam broadcast = 4'b1111;
reg [3:0] des_port;
reg [3:0] source_port;

always @(*) begin
    if (valid_destination) begin // potentially come back and lower the clock cycle added by valid_address only turning on when MAC is ready and not 1 clk before
        case(MAC_destination) 
            48'h00_00_00_00_00: des_port = Port_A; // place holder address since idk what they are yet
            48'h00_00_00_00_01: des_port = Port_B;
            48'h00_00_00_00_02: des_port = Port_C;
            48'h00_00_00_00_03: des_port = Port_D;
            default: des_port = broadcast; // everyone
        endcase
    end
    else begin
        des_port = 4'b0000;
    end
end

always @(*) begin // clk now useless here since we are just pumping out the answer, however, the next module must clk port or it will create issues
    if (reset) begin
        destination_port = 4'h0;
    end
    else begin
        destination_port = des_port;
    end
end
endmodule
            