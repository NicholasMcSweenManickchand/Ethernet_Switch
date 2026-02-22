module Arbiter( // 1 arbiter per gate so it only handles the message for it
    input [3:0] valid_input, // 0 is for A and 3 is for D 
    input [3:0] control_signal,
    input [7:0] rx_data [3:0], // all data paths
    input reset, clk,
    output [7:0] tx_data // outputs to the gate where the arbiter is places, (essentially making this complex MUX)
    // at 4 bits the compiler will know its not BRAM and use register so simply short-handing
);

// priority will be givn to port A to D initially, then ports will follow this order but only account for who passed the most recently

localparam IDLE = 0, A = 1, B = 2, C = 3, D = 4;
reg [2:0] state, next_state;

always @(*) begin //no multicast support yet
    case (state)
        IDLE: begin
            case (valid_input)
                4'b0000: next_state = IDLE;
                4'b0001: next_state = A;
                4'b0010: next_state = B;
                4'b0100: next_state = C;
                4'b1000: next_state = D;
                default: next_state = A; // priority to A
            endcase
        end 
        A: begin
            if (control_signal[0]) begin
                next_state = A;
            end
            else begin
                case (valid_input) // currently can't handle if we stay on it for more than 1 data push
                    4'b0000: next_state = IDLE; // notice how the current state isn't an option if control turns off
                    4'b0010: next_state = B;
                    4'b0100: next_state = C;
                    4'b1000: next_state = D;
                    default: next_state = B; // priority to next most important if more than 1 asking
                endcase
            end
        end
        B: begin
            if (control_signal[1]) begin
                next_state = B;
            end
            else begin
                case (valid_input)
                    4'b0000: next_state = IDLE;
                    4'b0001: next_state = A;
                    4'b0100: next_state = C;
                    4'b1000: next_state = D;
                    default: next_state = C; 
                endcase
            end
        end
        C: begin
            if (control_signal[2]) begin
                next_state = C;
            end
            else begin
                case (valid_input)
                    4'b0000: next_state = IDLE;
                    4'b0001: next_state = A;
                    4'b0100: next_state = C;
                    4'b1000: next_state = D;
                    default: next_state = D; 
                endcase
            end
        end
        D: begin
            if (control_signal[3]) begin
                next_state = D;
            end
            else begin
                case (valid_input)
                    4'b0000: next_state = IDLE;
                    4'b0001: next_state = A;
                    4'b0010: next_state = B;
                    4'b0100: next_state = C;
                    default: next_state = A; // loops back around priority list
                endcase
            end
        default: next_state = IDLE;
    endcase

end

always @(*) begin
    case (state)
            A: tx_data = rx_data[0]; //having them like this allows potentially for future multi-cast since multiple output streams?
            B: tx_data = rx_data[1];
            C: tx_data = rx_data[2];
            D: tx_data = rx_data[3];
            default: begin // basically IDLE
                tx_data = 8'h0;
            end
        endcase
end
always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
                          //tx_data <= 8'h0; not necessary here bc when state is idle does this automatically + multiple drivers not allowed
    end
    else begin
        state <= next_state;
    end
end




