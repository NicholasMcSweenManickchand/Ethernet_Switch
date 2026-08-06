`default_nettype none

module Arbiter (
    input wire clk,
    input wire reset,
    
    // 4-port incoming FIFO data streams
    input wire [35:0] rx_data,     
    
    // Port request/valid flags indicating which FIFOs want to transmit
    input wire [3:0] valid_input,  
    
    // Backpressure signal coming downstream from the TX_MAC
    input wire tx_payload_active,  

    // Output to the TX_MAC
    output reg [7:0] tx_data,      
    
    // Output to the TX_MAC to tell it when the frame is officially over
    output wire active_transmit,
    
    // Output to the Port Allocator
    output reg [3:0] rx_grant  
);

    wire [8:0] port_0 = rx_data[8:0];
    wire [8:0] port_1 = rx_data[17:9];
    wire [8:0] port_2 = rx_data[26:18];
    wire [8:0] port_3 = rx_data[35:27];

    reg [1:0] selected_port;
    reg transmitting;
    reg current_eof;

    // --- Combinational EOF Detection ---
    always @(*) begin
        case (selected_port)
            2'b00: current_eof = port_0[8];
            2'b01: current_eof = port_1[8];
            2'b10: current_eof = port_2[8];
            2'b11: current_eof = port_3[8];
            default: current_eof = 1'b0;
        endcase
    end

    // THE HARD-BRAKE: Drop the transmit lock the exact combinational instant EOF appears.
    // This stops the TX_MAC from lingering and freezes the FCS math on the correct hash.
    assign active_transmit = transmitting & ~current_eof;

    // --- SEQUENTIAL LOGIC (State Memory) ---
    always @(posedge clk) begin
        if (reset) begin
            selected_port <= 2'b00;
            transmitting <= 1'b0;
        end 
        else begin
            if (!transmitting) begin
                if (valid_input[0]) begin
                    selected_port <= 2'b00; transmitting <= 1'b1;
                end else if (valid_input[1]) begin
                    selected_port <= 2'b01; transmitting <= 1'b1;
                end else if (valid_input[2]) begin
                    selected_port <= 2'b10; transmitting <= 1'b1;
                end else if (valid_input[3]) begin
                    selected_port <= 2'b11; transmitting <= 1'b1;
                end
            end 
            else begin
                // Drop the internal register on the clock edge following the EOF
                if (current_eof && tx_payload_active) transmitting <= 1'b0;
            end
        end
    end

    // --- COMBINATIONAL LOGIC (Data Routing) ---
    always @(*) begin
        tx_data = 8'h00;
        rx_grant = 4'b0000;
        
        // THE HARD-BRAKE: Sever the read grant instantly to prevent pointer overshoot.
        case (selected_port)
            2'b00: begin 
                tx_data = port_0[7:0]; 
                rx_grant = {3'b000, (transmitting & tx_payload_active & ~current_eof)}; 
            end
            2'b01: begin 
                tx_data = port_1[7:0]; 
                rx_grant = {2'b00, (transmitting & tx_payload_active & ~current_eof), 1'b0}; 
            end
            2'b10: begin 
                tx_data = port_2[7:0]; 
                rx_grant = {1'b0, (transmitting & tx_payload_active & ~current_eof), 2'b00}; 
            end
            2'b11: begin 
                tx_data = port_3[7:0]; 
                rx_grant = {(transmitting & tx_payload_active & ~current_eof), 3'b000}; 
            end
        endcase
    end

endmodule