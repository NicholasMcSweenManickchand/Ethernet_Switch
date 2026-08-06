`default_nettype none

module byte_parser (
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_valid,          // Driven by valid_byte_detector
    input wire rx_control_signal, // The GMII rx_dv pin

    output reg [47:0] MAC_destination_address,
    output reg [47:0] MAC_source_address,
    output reg MAC_des_complete,
    output reg MAC_sc_complete,
    output wire [7:0] tx_true_data,
    output wire true_data_valid
);

    reg [3:0] byte_count;

    // Push EVERYTHING that the VBD validates directly into the FIFO
    assign tx_true_data = rx_data;
    assign true_data_valid = rx_valid;

    always @(posedge clk) begin
        // Reset everything when the physical line drops (Inter-Packet Gap)
        if (reset || !rx_control_signal) begin
            byte_count <= 0;
            MAC_des_complete <= 0;
            MAC_sc_complete <= 0;
            MAC_destination_address <= 48'h0;
            MAC_source_address <= 48'h0;
        end 
        else if (rx_valid) begin
            // Prevent integer overflow on long packets
            if (byte_count < 15) begin
                byte_count <= byte_count + 1;
            end

            // The VBD already stripped the Preamble/SFD. 
            // The very first rx_valid byte is the start of the Dest MAC.
            if (byte_count < 6) begin
                MAC_destination_address <= {MAC_destination_address[39:0], rx_data};
                if (byte_count == 5) MAC_des_complete <= 1; // Wake up the CAM
            end
            
            // Parse the Source MAC
            else if (byte_count < 12) begin
                MAC_source_address <= {MAC_source_address[39:0], rx_data};
                if (byte_count == 11) MAC_sc_complete <= 1; // Wake up the Learning Engine
            end
        end
    end
endmodule