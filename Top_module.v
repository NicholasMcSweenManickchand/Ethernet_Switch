`default_nettype none

module Switch_Top (
    // --- Global Signals ---
    input wire clk,
    input wire reset,

    // --- Physical GMII Interfaces (External Pins) ---
    // Port 0
    input  wire [7:0] gmii_rx_data_0,
    input  wire       gmii_rx_dv_0,
    output wire [7:0] gmii_tx_data_0,
    output wire       gmii_tx_en_0,

    // Port 1
    input  wire [7:0] gmii_rx_data_1,
    input  wire       gmii_rx_dv_1,
    output wire [7:0] gmii_tx_data_1,
    output wire       gmii_tx_en_1,

    // Port 2
    input  wire [7:0] gmii_rx_data_2,
    input  wire       gmii_rx_dv_2,
    output wire [7:0] gmii_tx_data_2,
    output wire       gmii_tx_en_2,

    // Port 3
    input  wire [7:0] gmii_rx_data_3,
    input  wire       gmii_rx_dv_3,
    output wire [7:0] gmii_tx_data_3,
    output wire       gmii_tx_en_3
);

    // =========================================================================
    // INTERNAL NETLIST WIRING
    // =========================================================================

    // --- Valid Byte Detector to Parser Wires ---
    wire [7:0] vbd_data_0, vbd_data_1, vbd_data_2, vbd_data_3;
    wire vbd_valid_0, vbd_valid_1, vbd_valid_2, vbd_valid_3;

    // --- Parser to Crossbar & Memory Wires ---
    wire [47:0] mac_dest_0, mac_dest_1, mac_dest_2, mac_dest_3;
    wire [47:0] mac_src_0, mac_src_1, mac_src_2, mac_src_3;
    wire mac_dest_comp_0, mac_dest_comp_1, mac_dest_comp_2, mac_dest_comp_3;
    wire mac_src_comp_0, mac_src_comp_1, mac_src_comp_2, mac_src_comp_3;
    wire [7:0] parser_data_0, parser_data_1, parser_data_2, parser_data_3;
    wire parser_valid_0, parser_valid_1, parser_valid_2, parser_valid_3;

    // --- Learning Engine to Write Arbiter Wires ---
    wire le_we_0, le_we_1, le_we_2, le_we_3;
    wire [47:0] le_mac_0, le_mac_1, le_mac_2, le_mac_3;
    wire [3:0] le_port_0, le_port_1, le_port_2, le_port_3;

    // --- Write Arbiter to CAM Wires ---
    wire cam_we;
    wire [47:0] cam_write_mac;
    wire [3:0] cam_write_port;

    // --- CAM to Port Allocator (PA) Wires ---
    wire [3:0] route_dest_0, route_dest_1, route_dest_2, route_dest_3;

    // --- FIFO Outputs (UPDATED TO 9 BITS) ---
    wire [8:0] fifo_out_0, fifo_out_1, fifo_out_2, fifo_out_3;
    wire fifo_empty_0, fifo_empty_1, fifo_empty_2, fifo_empty_3;

    // --- Egress Arbiter to TX_MAC Wires ---
    wire [7:0] egress_data_0, egress_data_1, egress_data_2, egress_data_3;

    // =========================================================================
    // MODULE INSTANTIATIONS
    // =========================================================================

    // -------------------------------------------------------------------------
    // PORT 0 INGRESS PATH
    // -------------------------------------------------------------------------
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
        .source_port(4'b0001), // Hardcoded physical identity for Port 0
        .cam_we(le_we_0), .cam_write_mac(le_mac_0), .cam_write_port(le_port_0)
    );

    FIFO fifo_0 (
        .Write_clk(clk), .Read_clk(clk), .reset(reset),
        .rx_data(parser_data_0), 
        .rx_valid_bytes(parser_valid_0), // Replaced obsolete control_signal
        .allow_output(1'b1), // Simplified for top-level binding
        .tx_data(fifo_out_0), // Pushing 9 bits out
        .empty(fifo_empty_0) // Hooking up new empty flag
    );

    // -------------------------------------------------------------------------
    // CENTRAL MEMORY & ARBITRATION
    // -------------------------------------------------------------------------
    CAM_Write_Arbiter cam_arbiter (
        .clk(clk), .reset(reset),
        .we_0(le_we_0), .mac_0(le_mac_0), .port_0(le_port_0),
        .we_1(1'b0), .mac_1(48'h0), .port_1(4'h0), // Tie off P1-P3 for brevity in this template
        .we_2(1'b0), .mac_2(48'h0), .port_2(4'h0),
        .we_3(1'b0), .mac_3(48'h0), .port_3(4'h0),
        .cam_we(cam_we), .cam_write_mac(cam_write_mac), .cam_write_port(cam_write_port)
    );

    CAM central_cam (
        .clk(clk), .reset(reset),
        .we(cam_we), .write_mac(cam_write_mac), .write_port(cam_write_port),
        .read_mac_0(mac_dest_0), .valid_dest_0(mac_dest_comp_0), .dest_port_0(route_dest_0),
        .read_mac_1(48'h0), .valid_dest_1(1'b0), .dest_port_1(route_dest_1),
        .read_mac_2(48'h0), .valid_dest_2(1'b0), .dest_port_2(route_dest_2),
        .read_mac_3(48'h0), .valid_dest_3(1'b0), .dest_port_3(route_dest_3)
    );

    // -------------------------------------------------------------------------
    // PORT 0 EGRESS PATH
    // -------------------------------------------------------------------------
    Arbiter egress_arbiter_0 (
        .clk(clk), .reset(reset),
        // Concatenating 27 bits of 0s with the 9-bit fifo_out_0 to equal 36 bits for the Arbiter
        .rx_data({27'h0, fifo_out_0}), 
        .valid_input({3'b000, mac_dest_comp_0}),
        .tx_data(egress_data_0)
    );

    TX_MAC tx_mac_0 (
        .clk(clk), .reset(reset),
        .tx_active(mac_dest_comp_0), 
        .FCS_data(32'hDEADBEEF), // Dummy FCS data pending actual FCS module output
        .rx_data(egress_data_0),
        .tx_data(gmii_tx_data_0),
        .tx_en(gmii_tx_en_0)
    );

endmodule