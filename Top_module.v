`default_nettype none

module Top_module (
    // --- Global Signals ---
    input wire clk,
    input wire reset,

    // --- Physical GMII Interfaces (External Pins) ---
    // Port 0 Interface
    input  wire [7:0] gmii_rx_data_0,
    input  wire       gmii_rx_dv_0,
    output wire [7:0] gmii_tx_data_0,
    output wire       gmii_tx_en_0,
    
    // Port 1 Interface
    input  wire [7:0] gmii_rx_data_1,
    input  wire       gmii_rx_dv_1,
    output wire [7:0] gmii_tx_data_1,
    output wire       gmii_tx_en_1,

    // Port 2 Interface
    input  wire [7:0] gmii_rx_data_2,
    input  wire       gmii_rx_dv_2,
    output wire [7:0] gmii_tx_data_2,
    output wire       gmii_tx_en_2,

    // Port 3 Interface
    input  wire [7:0] gmii_rx_data_3,
    input  wire       gmii_rx_dv_3,
    output wire [7:0] gmii_tx_data_3,
    output wire       gmii_tx_en_3
);

    // =========================================================================
    // INTERNAL NETLIST WIRING
    // =========================================================================

    // --- Ingress Wires ---
    wire [7:0] vbd_data_0;
    wire vbd_valid_0;
    wire [47:0] mac_dest_0, mac_src_0;
    wire mac_dest_comp_0, mac_src_comp_0;
    wire [7:0] parser_data_0;
    wire parser_valid_0;
    
    // --- Central Memory & PA Wires ---
    wire le_we_0, cam_we;
    wire [47:0] le_mac_0, cam_write_mac;
    wire [3:0] le_port_0, cam_write_port, route_dest_0;
    
    // --- Crossbar Wires ---
    wire [8:0] fifo_out_0;
    wire fifo_empty_0;
    wire [35:0] pa_tx_data_bus;
    wire [3:0] pa_valid_input_A;
    wire pa_allow_output_0;
    
    // --- Egress Wires ---
    wire [3:0] arbiter_grant_0;
    wire arbiter_active_0;
    wire [7:0] egress_data_0;
    wire tx_payload_active_0;
    wire [31:0] computed_fcs_0;

    // =========================================================================
    // INGRESS PATH
    // =========================================================================
    valid_byte_detector vbd_0 (
        .clk(clk), .reset(reset),
        .rx_data(gmii_rx_data_0), .rx_control_signal(gmii_rx_dv_0),
        .tx_data(vbd_data_0), .tx_valid(vbd_valid_0)
    );

    byte_parser parser_0 (
        .clk(clk), .reset(reset),
        .rx_data(vbd_data_0), .rx_valid(vbd_valid_0), .rx_control_signal(gmii_rx_dv_0),
        .MAC_destination_address(mac_dest_0), .MAC_source_address(mac_src_0),
        .MAC_des_complete(mac_dest_comp_0), .MAC_sc_complete(mac_src_comp_0),
        .tx_true_data(parser_data_0), .true_data_valid(parser_valid_0)
    );

    MAC_Learning_Engine le_0 (
        .clk(clk), .reset(reset),
        .MAC_source_address(mac_src_0), .MAC_sc_complete(mac_src_comp_0),
        .source_port(4'b0001), 
        .cam_we(le_we_0), .cam_write_mac(le_mac_0), .cam_write_port(le_port_0)
    );

    FIFO fifo_0 (
        .Write_clk(clk), .Read_clk(clk), .reset(reset),
        .rx_data(parser_data_0), .rx_valid_bytes(parser_valid_0), 
        .allow_output(pa_allow_output_0), // Tied directly to the Port Allocator
        .tx_data(fifo_out_0), .empty(fifo_empty_0) 
    );

    // =========================================================================
    // CENTRAL ROUTING & PORT ALLOCATION
    // =========================================================================
    CAM_Write_Arbiter cam_arbiter (
        .clk(clk), .reset(reset),
        .we_0(le_we_0), .mac_0(le_mac_0), .port_0(le_port_0),
        .we_1(1'b0), .mac_1(48'h0), .port_1(4'h0), 
        .we_2(1'b0), .mac_2(48'h0), .port_2(4'h0),
        .we_3(1'b0), .mac_3(48'h0), .port_3(4'h0),
        .cam_we(cam_we), .cam_write_mac(cam_write_mac), .cam_write_port(cam_write_port)
    );

    CAM central_cam (
        .clk(clk), .reset(reset),
        .we(cam_we), .write_mac(cam_write_mac), .write_port(cam_write_port),
        .read_mac_0(mac_dest_0), .valid_dest_0(mac_dest_comp_0), .dest_port_0(route_dest_0),
        .read_mac_1(48'h0), .valid_dest_1(1'b0), .dest_port_1(),
        .read_mac_2(48'h0), .valid_dest_2(1'b0), .dest_port_2(),
        .read_mac_3(48'h0), .valid_dest_3(1'b0), .dest_port_3()
    );

    // The PA dynamically maps the FIFOs to the Arbiters
    PA port_allocator (
        .rx_data_0(fifo_out_0), .rx_data_1(9'h0), .rx_data_2(9'h0), .rx_data_3(9'h0),
        .cam_dest_0(route_dest_0), .cam_dest_1(4'h0), .cam_dest_2(4'h0), .cam_dest_3(4'h0),
        
        // Receiving grants from the egress arbiters
        .arbiter_grant_A(arbiter_grant_0), .arbiter_grant_B(4'h0), .arbiter_grant_C(4'h0), .arbiter_grant_D(4'h0),
        
        // Broadcasting the 36-bit highway and valid signals out to egress
        .tx_data_bus(pa_tx_data_bus),
        .valid_input_A(pa_valid_input_A), .valid_input_B(), .valid_input_C(), .valid_input_D(),
        
        // Routing the final allow_output back to the FIFOs
        .allow_output_0(pa_allow_output_0), .allow_output_1(), .allow_output_2(), .allow_output_3()
    );

    // =========================================================================
    // EGRESS PATH (PORT A / PORT 0)
    // =========================================================================
    Arbiter egress_arbiter_0 (
        .clk(clk), .reset(reset),
        .rx_data(pa_tx_data_bus),         // Bound to the PA's highway
        .valid_input(pa_valid_input_A),   // Bound to the PA's valid vector
        .tx_payload_active(tx_payload_active_0), 
        
        .tx_data(egress_data_0),
        .rx_grant(arbiter_grant_0),       // Feeds back into PA
        .active_transmit(arbiter_active_0) // Controls the TX_MAC
    );

    FCS egress_fcs_0 (
        .clk(clk), .reset(reset),
        .data(egress_data_0),
        .valid_data(tx_payload_active_0),
        .done(!arbiter_active_0 && tx_payload_active_0), // Triggers when Arbiter sees EOF and drops its lock
        .poison(1'b0),
        .rx_crc(computed_fcs_0)
    );

    TX_MAC tx_mac_0 (
        .clk(clk), .reset(reset),
        .tx_active(arbiter_active_0),     // Master switch controlled exclusively by the Arbiter's state
        .FCS_data(computed_fcs_0),        // Now passing real CRC math
        .rx_data(egress_data_0),
        .tx_data(gmii_tx_data_0),
        .tx_en(gmii_tx_en_0),
        .payload_active(tx_payload_active_0) 
    );

endmodule