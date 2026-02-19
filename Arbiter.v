//clearly doesn't work for all inputs to all outputs, need to revisit and fix too tired to solve rn

module Arbiter(
    input [3:0] valid_port,
    input [3:0] valid_input, // 0 is for A and 3 is for D 
    input [3:0] control_signal,
    input [7:0] rx_data [3:0], // all data paths
    input reset, clk,
    output [7:0] tx_data [3:0] // all output paths
    // at 4 bits the compiler will know its not BRAM and use register so simply short-handing
);

// priority will be givn to port A to D initially, then ports will follow this order but only account for who passed the most recently

localparam IDLE = 0, A = 1; B = 2, C = 3, D = 4;
reg [2:0] state, next_state;
reg [2:0] target_port;

always @(*) begin //no multicast support yet
    case (state)
        IDLE: begin
            case (valid_port)
                4'b0000: next_state = IDLE;
                4'b0001: next_state = A
                4'b0010: next_state = B
                4'b0100: next_state = C
                4'b1000: next_state = D
                default: next_state = A // priority to A
            endcase
        end 
        A: begin
            if (control_signal[0]) begin
                next_state = A;
            end
            else begin
                case (valid_port) // currently can't handle if we stay on it for more than 1 data push
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
                case (valid_port)
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
                case (valid_port)
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
                case (valid_port)
                    4'b0000: next_state = IDLE;
                    4'b0001: next_state = A;
                    4'b0010: next_state = B;
                    4'b0100: next_state = C;
                    default: next_state = A; // loops back around priority list
                endcase
            end
    endcase

    case(valid_port)
        4'b0000: target_port = 3'h0;
        4'b0001: target_port = 3'h1;
        4'b0010: target_port = 3'h2;
        4'b0100: target_port = 3'h3;
        default: target_port = 3'h4; // broadcast;
end

always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        tx_data[0] <= 8'h0;
        tx_data[1] <= 8'h0;
        tx_data[2] <= 8'h0;
        tx_data[3] <= 8'h0;
    end
    else begin
        state <= next_state;
        case (state)
            A: tx_data[0] <= rx_data[0]; //having them like this allows potentially for future multi-cast since multiple output streams?
            B: tx_data[1] <= rx_data[1];
            C: tx_data[2] <= rx_data[2];
            D: tx_data[3] <= rx_data[3];
            default: begin // basically IDLE
                tx_data[0] <= 8'h0;
                tx_data[1] <= 8'h0;
                tx_data[2] <= 8'h0;
                tx_data[3] <= 8'h0;
            end
        endcase
    end
end



