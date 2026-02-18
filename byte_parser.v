module byte_parser(
    input wire rx_valid, rx_control_signal, reset, clk, //Linked to tx_valid and control signal from byte detector module
    input wire [7:0] rx_data,
    output reg [47:0] MAC_destination_address, MAC_source_address,
    output reg [15:0] MAC_type,
    output reg [7:0] tx_true_data,
    output reg MAC_des_complete, MAC_sc_complete, MAC_tp_complete, true_data_valid
);
// This module received the data from valid byte detector and ouputs the MAC source and destination, the type and the data. 

localparam Idle = 3'h0, MAC_des = 3'h1, MAC_sc = 3'h2, MAC_tp = 3'h3, Gather_data = 3'h4;
localparam ON = 1'h1, OFF = 1'h0;
reg [2:0] state, next_state;
reg [3:0] counter;

// state combinational logic
always @(*) begin
    case (state)
        Idle: next_state = rx_valid? MAC_des : Idle;

        MAC_des: begin
            if (rx_control_signal) begin
                if (counter == 5) begin
                    next_state = MAC_sc;
                end 
                else begin
                    next_state = MAC_des;
                end    
            end
            else begin
                next_state = Idle;
            end
        end

        MAC_sc: begin
            if (rx_control_signal) begin
                if (counter == 11) begin
                    next_state = MAC_tp;
                end 
                else begin
                    next_state = MAC_sc;
                end   
            end
            else begin
                next_state = Idle;
            end
        end

        MAC_tp: begin
            if (rx_control_signal) begin
                if (counter == 13) begin
                    next_state = Gather_data;
                end 
                else begin
                    next_state = MAC_tp;
                end   
            end
            else begin
                next_state = Idle;
            end
        end

        Gather_data: next_state = rx_control_signal? Gather_data : Idle;

        default: next_state <= Idle;
    endcase
end

always @(posedge clk) begin
    if (reset || !rx_control_signal) begin
        // reset counter
        counter<= 4'h0; // I don't like trusting automatic truncation

        // Make parsed rx_data have full 0's for extra safety (this is not necessary which is why the Idle case doesn't do this)
        MAC_destination_address <= 48'h0;
        MAC_source_address <= 48'h0;
        MAC_type <= 16'h0;
        tx_true_data <= 8'h0;

        // Make all flags be off
        MAC_des_complete <= OFF;
        MAC_sc_complete <= OFF;
        MAC_tp_complete <= OFF;
        true_data_valid <= OFF;

        // reset state
        state <= Idle;
    end
    else begin
        state <= next_state;
        case (state) 
            MAC_des: begin
                MAC_destination_address <= {MAC_destination_address[39:0], rx_data};
                counter <= counter + 1;
                if (counter == 5) begin
                    MAC_des_complete <= ON;
                end   
            end

            MAC_sc: begin
                MAC_source_address <= {MAC_source_address[39:0], rx_data};
                counter <= counter + 1; 
                if (counter == 11) begin
                    MAC_sc_complete <= ON;
                end
            end

            MAC_tp: begin
                MAC_type <= {MAC_type[7:0], rx_data};
                counter <= counter + 1;  
                if (counter == 13) begin
                    MAC_tp_complete <= ON;
                    true_data_valid <= ON; // easier to understand as an extra port but is the same functionally as MAC_tp_complete.
                end
            end

            Gather_data: begin
                tx_true_data <= rx_data;
            end
            default: begin 
                //ensure everything starts from a known initial state (here, we are in Idle or something has gone horribly wrong)
                counter <= 4'h0;
                MAC_des_complete <= OFF;
                MAC_sc_complete <= OFF;
                MAC_tp_complete <= OFF;
                true_data_valid <= OFF;
            end
        endcase
    end
end
endmodule
        