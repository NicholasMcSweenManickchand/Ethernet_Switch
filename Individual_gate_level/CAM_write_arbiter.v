`default_nettype none

module CAM_Write_Arbiter(
    input wire clk, 
    input wire reset,
    
    // --- Inputs from RX Port 0 Learning Engine ---
    input wire we_0,
    input wire [47:0] mac_0,
    input wire [3:0] port_0,
    
    // --- Inputs from RX Port 1 Learning Engine ---
    input wire we_1,
    input wire [47:0] mac_1,
    input wire [3:0] port_1,
    
    // --- Inputs from RX Port 2 Learning Engine ---
    input wire we_2,
    input wire [47:0] mac_2,
    input wire [3:0] port_2,
    
    // --- Inputs from RX Port 3 Learning Engine ---
    input wire we_3,
    input wire [47:0] mac_3,
    input wire [3:0] port_3,
    
    // --- Unified Outputs to the Central CAM ---
    output reg cam_we,
    output reg [47:0] cam_write_mac,
    output reg [3:0] cam_write_port
);

    // Buffers to latch incoming 1-cycle pulses so they aren't lost
    reg req_pending [0:3];
    reg [47:0] latched_mac [0:3];
    reg [3:0] latched_port [0:3];

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            cam_we <= 1'b0;
            cam_write_mac <= 48'h0;
            cam_write_port <= 4'h0;
            
            for (i = 0; i < 4; i = i + 1) begin
                req_pending[i] <= 1'b0;
                latched_mac[i] <= 48'h0;
                latched_port[i] <= 4'h0;
            end
        end else begin
            
            // ---------------------------------------------------------
            // 1. THE LATCH STAGE
            // If any learning engine pulses 'we' for a clock cycle, 
            // instantly save its data and raise its pending flag.
            // ---------------------------------------------------------
            if (we_0) begin 
                req_pending[0] <= 1'b1; latched_mac[0] <= mac_0; latched_port[0] <= port_0; 
            end
            if (we_1) begin 
                req_pending[1] <= 1'b1; latched_mac[1] <= mac_1; latched_port[1] <= port_1; 
            end
            if (we_2) begin 
                req_pending[2] <= 1'b1; latched_mac[2] <= mac_2; latched_port[2] <= port_2; 
            end
            if (we_3) begin 
                req_pending[3] <= 1'b1; latched_mac[3] <= mac_3; latched_port[3] <= port_3; 
            end

            // ---------------------------------------------------------
            // 2. THE SERVICE STAGE (Fixed Priority Encoder)
            // Look at the pending flags. Service the lowest port number
            // first. Once serviced, clear its flag so the next port 
            // can be serviced on the next clock cycle.
            // ---------------------------------------------------------
            if (req_pending[0]) begin
                cam_we <= 1'b1;
                cam_write_mac <= latched_mac[0];
                cam_write_port <= latched_port[0];
                req_pending[0] <= 1'b0; // Clear the flag so it doesn't write twice
            end
            else if (req_pending[1]) begin
                cam_we <= 1'b1;
                cam_write_mac <= latched_mac[1];
                cam_write_port <= latched_port[1];
                req_pending[1] <= 1'b0; 
            end
            else if (req_pending[2]) begin
                cam_we <= 1'b1;
                cam_write_mac <= latched_mac[2];
                cam_write_port <= latched_port[2];
                req_pending[2] <= 1'b0; 
            end
            else if (req_pending[3]) begin
                cam_we <= 1'b1;
                cam_write_mac <= latched_mac[3];
                cam_write_port <= latched_port[3];
                req_pending[3] <= 1'b0; 
            end
            else begin
                // If nobody is pending, drop the write enable to protect the memory
                cam_we <= 1'b0;
            end

        end
    end

endmodule