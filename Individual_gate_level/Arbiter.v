`default_nettype none

module Arbiter( 
    input wire [3:0] valid_input, 
    // CHANGED: Expanded from 32-bit to 36-bit to accept four 9-bit streams (8 payload + 1 EOF)
    input wire [35:0] rx_data, 
    input wire reset, clk,
    
    output reg [7:0] tx_data, 
    // NEW: 4-bit grant vector sent back to the PA to trigger the winning FIFO's allow_output
    output reg [3:0] grant,   
    // NEW: Control signal sent to the TX_MAC to act as its rx_control_signal
    output wire tx_active     
);

    localparam IDLE = 0, A = 1, B = 2, C = 3, D = 4;
    reg [2:0] state, next_state;

    // NEW: Drive the TX_MAC. If we are not IDLE, we have a lock, so tell the MAC to transmit.
    assign tx_active = (state != IDLE);

    // --- State Transition Logic (The Lock & Break Mechanism) ---
    always @(*) begin 
        // Default to holding the current state to prevent latches
        next_state = state; 

        case (state)
            IDLE: begin
                // Standard round-robin priority for grabbing a new packet
                if (valid_input[0])      next_state = A;
                else if (valid_input[1]) next_state = B;
                else if (valid_input[2]) next_state = C;
                else if (valid_input[3]) next_state = D;
                else                     next_state = IDLE;
            end 

            // CHANGED: Instead of checking valid_input to maintain the state, 
            // we now strictly look for the 9th bit (EOF marker) coming from the FIFO.
            A: begin
                if (rx_data[8] == 1'b1)  next_state = IDLE; // EOF detected, break the lock
                else                     next_state = A;    // Hold lock while streaming
            end
            
            B: begin
                if (rx_data[17] == 1'b1) next_state = IDLE; 
                else                     next_state = B;    
            end
            
            C: begin
                if (rx_data[26] == 1'b1) next_state = IDLE; 
                else                     next_state = C;    
            end
            
            D: begin
                if (rx_data[35] == 1'b1) next_state = IDLE; 
                else                     next_state = D;    
            end
            
            default: next_state = IDLE;
        endcase
    end

    // --- Data Multiplexing & Grant Output Logic ---
    always @(*) begin
        // Default assignments
        tx_data = 8'h0;
        grant = 4'b0000;

        case (state)
            A: begin
                tx_data = rx_data[7:0];   // Slices the 8 payload bits for the TX_MAC
                grant[0] = 1'b1;          // Tells PA that RX0 won the arbitration
            end
            B: begin
                tx_data = rx_data[16:9];  // Slices the next 8 payload bits
                grant[1] = 1'b1;          // Tells PA that RX1 won the arbitration
            end
            C: begin
                tx_data = rx_data[25:18]; 
                grant[2] = 1'b1;          
            end
            D: begin
                tx_data = rx_data[34:27]; 
                grant[3] = 1'b1;          
            end
            default: begin
                tx_data = 8'h0;
                grant = 4'b0000;
            end
        endcase
    end

    // --- Sequential Logic ---
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
endmodule