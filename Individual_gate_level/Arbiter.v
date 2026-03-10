module Arbiter( // 1 arbiter per gate so it only handles the message for it
    input [3:0] valid_input, // 0 is for A and 3 is for D // valid input will swallow control_signal and be the only gate keeper
    input [31:0] rx_data, //[7:0] rx_data [3:0], this is not allowed in verilog only system verilog // all data paths
    input reset, clk,
    output reg [7:0] tx_data // outputs to the gate where the arbiter is places, (essentially making this complex MUX)
    // at 4 bits the compiler will know its not BRAM and use register so simply short-handing
);

// priority will be givn to port A to D initially, then ports will follow this order but only account for who passed the most recently

localparam IDLE = 0, A = 1, B = 2, C = 3, D = 4;
reg [2:0] state, next_state;

always @(*) begin //no multicast support yet
    case (state)
        IDLE: begin
                if (valid_input[0])begin
                    next_state = A;
                end
                else if (valid_input[1]) begin
                    next_state = B;
                end
                else if (valid_input[2]) begin
                    next_state = C;
                end
                else if (valid_input[3]) begin
                    next_state = D;
                end
                else begin
                    next_state = IDLE;
                end
        end 
        A: begin
                if (valid_input[0])begin
                    next_state = A;
                end
                else if (valid_input[1]) begin
                    next_state = B;
                end
                else if (valid_input[2]) begin
                    next_state = C;
                end
                else if (valid_input[3]) begin
                    next_state = D;
                end
                else begin
                    next_state = IDLE;
                end
            end
        end
        B: begin
                if (valid_input[1])begin
                    next_state = B;
                end
                else if (valid_input[2]) begin
                    next_state = C;
                end
                else if (valid_input[3]) begin
                    next_state = D;
                end
                else if (valid_input[0]) begin
                    next_state = A;
                end
                else begin
                    next_state = IDLE;
                end
        end
        C: begin
                if (valid_input[2])begin
                    next_state = C;
                end
                else if (valid_input[3]) begin
                    next_state = D;
                end
                else if (valid_input[0]) begin
                    next_state = A;
                end
                else if (valid_input[1]) begin
                    next_state = B;
                end
                else begin
                    next_state = IDLE;
                end
        end
        D: begin
                if (valid_input[3])begin
                    next_state = D;
                end
                else if (valid_input[0]) begin
                    next_state = A;
                end
                else if (valid_input[1]) begin
                    next_state = B;
                end
                else if (valid_input[2]) begin
                    next_state = C;
                end
                else begin
                    next_state = IDLE;
                end
        end
        default: next_state = IDLE;
    endcase

end

always @(*) begin
    case (state)
            A: tx_data = rx_data[7:0]; //having them like this allows potentially for future multi-cast since multiple output streams?
            B: tx_data = rx_data[15:8];
            C: tx_data = rx_data[23:16];
            D: tx_data = rx_data[31:24];
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
endmodule



