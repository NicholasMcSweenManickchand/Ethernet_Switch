module Top(
    input [7:0] rx_data,
    input rx_control, clk, reset,

);

    reg [7:0] valid_byte_to_byte_parser;
    reg valid_byte_detected;
    wire [47:0] MAC_destination_address;
    wire [47:0] MAC_source_address;
    
    valid_byte_detector VBD(
        .rx_data(rx_data),
        .rx_control_signal(rx_control),
        .clk(clk), 
        .reset(reset),
        .tx_data, // i don't even think the modules need this bc all that is needded is the tx_valid
        .tx_valid(valid_byte_detected)
    );

    byte_parser BP(
        rx_valid(valid_byte_detected),
        rx_control_signal(rx_control),
        reset(reset), 
        clk(clk),
        rx_data(rx_data),
        MAC_destination_address9(MAC_destination_address), 
        MAC_source_address(MAC_source_address),
        MAC_type,
        tx_true_data,
        reg MAC_des_complete, 
        MAC_sc_complete, 
        MAC_tp_complete, 
        true_data_valid
    )
