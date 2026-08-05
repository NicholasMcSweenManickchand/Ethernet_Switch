`default_nettype none

module TX_MAC(
    input wire clk, 
    input wire reset,
    
    // CHANGED: Replaces rx_control_signal. This tells the MAC that the Arbiter has locked a route.
    input wire tx_active,       
    
    input wire [31:0] FCS_data, // Inherited from your original design
    input wire [7:0] rx_data,   // Sliced 8-bit payload coming directly from the Arbiter
    
    output reg [7:0] tx_data,   
    
    // NEW: Standard GMII/RGMII enable signal. The PHY needs this to know when data on the wire is valid.
    output reg tx_en,           
    
    // NEW: Tells the parallel FCS module exactly when to hash the data, ignoring the preamble/SFD.
    output wire payload_active  
);

    wire [7:0] preamble = 8'h55; 
    wire [7:0] SFD = 8'hD5;      

    // CHANGED: Added IPG_WAIT as a distinct state at the end of the transmission cycle.
    // This provides a safer enforcement of the 12-cycle gap than holding it in IDLE.
    localparam IDLE = 0, PREAMBLE_PUSH = 1, SFD_PUSH = 2, DATA_PUSH = 3, FCS_PUSH = 4, IPG_WAIT = 5;
    
    reg [2:0] state, next_state;
    reg [3:0] counter_IPG; 
    reg [2:0] counter_preamble; 
    reg [1:0] counter_FCS; 

    // The FCS module should only calculate CRC when actual payload bytes are flowing.
    assign payload_active = (state == DATA_PUSH);

    // --- State Transition Logic ---
    always @(*) begin
        case (state)
            // Wake up instantly when the Arbiter asserts the lock.
            IDLE:          next_state = tx_active ? PREAMBLE_PUSH : IDLE;
            
            PREAMBLE_PUSH: next_state = (counter_preamble == 3'd6) ? SFD_PUSH : PREAMBLE_PUSH;
            
            SFD_PUSH:      next_state = DATA_PUSH;
            
            // CHANGED: The MAC no longer looks for an EOF bit. It stays here and streams
            // until the Arbiter drops the tx_active signal.
            DATA_PUSH:     next_state = tx_active ? DATA_PUSH : FCS_PUSH;
            
            // Push the 4 bytes of CRC.
            FCS_PUSH:      next_state = (counter_FCS == 3) ? IPG_WAIT : FCS_PUSH;
            
            // CHANGED: Enforce the mandatory 96ns (12 clock cycles at 125MHz) gap before accepting a new frame.
            IPG_WAIT:      next_state = (counter_IPG == 11) ? IDLE : IPG_WAIT; // this reduces latency by switching the 96ns gap from IDLE to this state
            
            default:       next_state = IDLE;
        endcase
    end

    // --- Output Logic ---
    always @(*) begin
        // Default to safe, zeroed outputs
        tx_data = 8'h0;
        tx_en = 1'b0;

        case (state) 
            PREAMBLE_PUSH: begin tx_data = preamble; tx_en = 1'b1; end
            SFD_PUSH:      begin tx_data = SFD;      tx_en = 1'b1; end
            
            // Stream the Arbiter's data
            DATA_PUSH:     begin tx_data = rx_data;  tx_en = 1'b1; end
            
            // Splice the 32-bit CRC into four 8-bit bytes.
            FCS_PUSH:      begin 
                tx_data = FCS_data[(31 - 8*counter_FCS) -: 8]; 
                tx_en = 1'b1; 
            end
            
            // During IDLE and IPG_WAIT, tx_en drops to 0 so the PHY ignores the zeroes.
            default:       begin tx_data = 8'h0;     tx_en = 1'b0; end 
        endcase
    end

    // --- Sequential Logic & Counters ---
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            counter_IPG <= 4'h0;
            counter_preamble <= 3'h0;
            counter_FCS <= 2'h0;
        end
        else begin
            state <= next_state;
            
            case (state)
                PREAMBLE_PUSH: counter_preamble <= counter_preamble + 1;
                FCS_PUSH:      counter_FCS <= counter_FCS + 1;
                
                // CHANGED: IPG counter increments here instead of IDLE to ensure a strict gap.
                IPG_WAIT:      counter_IPG <= counter_IPG + 1;
                
                default: begin 
                    // Clear all counters when not in their specific states.
                    counter_IPG <= 4'h0;
                    counter_preamble <= 3'h0;
                    counter_FCS <= 2'h0;
                end
            endcase
        end
    end
endmodule