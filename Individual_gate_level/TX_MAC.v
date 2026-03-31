module TX_MAC(
    input rx_control_signal,
    input clk, reset,
    input [31:0] FCS_data,
    input [7:0] rx_data,
    output reg [7:0] tx_data
);

    wire [7:0] preamble;
    wire [7:0] SFD;

    assign preamble = 8'h55;
    assign SFD = 8'hD5;

    localparam IDLE = 0, Preamble_push = 1, SFD_push = 2, data_push = 3, FCS_push = 4;
    reg [2:0] state, next_state;
    reg [3:0] counter_IPG; // 96ns gap at 125MHz clk spped is 12 clk cycles since 1 clk cycle is 8ns  (this is the minimum gap between packets)
    reg [2:0] counter_preamble; // count the seven bytes
    reg [1:0] counter_FCS; // count the FCS bytes (4) 

    always @(*) begin
        
        // case for switching states
        case (state)
            IDLE:          next_state = (counter_IPG == 4'd11 && rx_control_signal)? Preamble_push: IDLE;
            Preamble_push: next_state = (counter_preamble == 3'd6)? SFD_push: Preamble_push;
            SFD_push:      next_state = data_push;
            data_push:     next_state = rx_control_signal? data_push: FCS_push;
            FCS_push:      next_state = (counter_FCS == 3)? IDLE: FCS_push;
            default:       next_state = IDLE;
        endcase

        // case for output based on states
        case (state) 
            Preamble_push: tx_data = preamble;
            SFD_push:      tx_data = SFD;
            data_push:     tx_data = rx_data;
            FCS_push:      tx_data = FCS_data[(31 - 8*counter_FCS) -: 8];
            default:       tx_data = 8'h0; // if not in these states then in IDLE so push nothing/no voltage;
        endcase
    end

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
                IDLE:  begin        
                if (counter_IPG != 11) // allows to hold until rx_control_signal goes high
                    counter_IPG <= counter_IPG + 1;
                end
                Preamble_push: counter_preamble <= counter_preamble + 1;
                FCS_push:      counter_FCS <= counter_FCS + 1;
                default: begin // when not in any of these 2 states (or IDLE) we need to reset the counters to 0 for the next packet;
                    counter_IPG <= 4'h0;
                    counter_preamble <= 3'h0;
                    counter_FCS <= 2'h0;
                end
                // all others are irrelevant here and since in clk'ed block, no latch is infered
            endcase
        end
    end
endmodule