`default_nettype none

module MAC_Learning_Engine(
    input wire clk,
    input wire reset,
    
    // --- Inputs from the local RX Port ---
    // The parsed 48-bit source MAC from your byte_parser
    input wire [47:0] MAC_source_address,
    // The flag that tells us the parser has finished reading the source MAC
    input wire MAC_sc_complete, 
    // Hardcoded at the top-level to identify which physical port this engine is attached to
    input wire [3:0] source_port, 
    
    // --- Outputs to the Central CAM ---
    output reg cam_we,                 // Write Enable flag
    output reg [47:0] cam_write_mac,   // The MAC address to store
    output reg [3:0] cam_write_port    // The physical port it maps to
);

    // Register for edge detection
    reg mac_sc_complete_delayed;

    always @(posedge clk) begin
        if (reset) begin
            cam_we <= 1'b0;
            cam_write_mac <= 48'h0;
            cam_write_port <= 4'h0;
            mac_sc_complete_delayed <= 1'b0;
        end else begin
            // 1. Edge Detection
            // We only want to fire a write request ONCE per packet. 
            // Since the byte_parser holds MAC_sc_complete HIGH until the packet ends, 
            // we use a 1-clock-cycle delay to detect the exact rising edge.
            mac_sc_complete_delayed <= MAC_sc_complete;

            // 2. The Write Trigger
            if (MAC_sc_complete && !mac_sc_complete_delayed) begin
                // The parser just finished reading the 12th byte (Source MAC complete).
                // Instantly fire a 1-clock-cycle write request to the CAM.
                cam_we <= 1'b1;
                cam_write_mac <= MAC_source_address;
                cam_write_port <= source_port;
            end else begin
                // Drop the write enable so we don't accidentally overwrite memory
                cam_we <= 1'b0;
            end
        end
    end

endmodule