`default_nettype none

module CAM(
    input wire clk, 
    input wire reset,

    // --- Write Interface (From the future Write Arbiter) ---
    input wire we, // write_enable
    input wire [47:0] write_mac,
    input wire [3:0] write_port,

    // --- Read Interfaces (From the 4 RX byte_parser modules) ---
    input wire [47:0] read_mac_0, read_mac_1, read_mac_2, read_mac_3,
    input wire valid_dest_0, valid_dest_1, valid_dest_2, valid_dest_3,
    
    // --- Outputs (To the 4 PA crossbar inputs) ---
    output reg [3:0] dest_port_0, dest_port_1, dest_port_2, dest_port_3
);

    // --- The Memory Array ---
    // A 16-entry MAC table. Real switches have thousands, but 16 is perfect for testing.
    reg [47:0] mac_memory [0:15];
    reg [3:0] port_memory [0:15];
    reg [15:0] entry_valid; // 1 bit per entry to mark if it contains real data
    
    // Pointer to the next empty or oldest slot (basic round-robin replacement)
    reg [3:0] write_ptr; 
    
    integer i;

    // --- Synchronous Write Logic (Learning) ---
    always @(posedge clk) begin
        if (reset) begin
            entry_valid <= 16'h0;
            write_ptr <= 4'h0;
            for (i = 0; i < 16; i = i + 1) begin
                mac_memory[i] <= 48'h0;
                port_memory[i] <= 4'h0;
            end
        end else if (we) begin
            mac_memory[write_ptr] <= write_mac;
            port_memory[write_ptr] <= write_port;
            entry_valid[write_ptr] <= 1'b1;
            write_ptr <= write_ptr + 1; // Overwrites the oldest entry when it hits 15
        end
    end

    // --- Asynchronous Read Logic (Routing) ---
    // Lookups must be combinational to maintain cut-through speed.
    
    // Read Port 0
    always @(*) begin
        dest_port_0 = 4'b1111; // Default to broadcast
        if (valid_dest_0) begin
            for (i = 0; i < 16; i = i + 1) begin
                if (entry_valid[i] && (mac_memory[i] == read_mac_0)) begin
                    dest_port_0 = port_memory[i];
                end
            end
        end else begin
            dest_port_0 = 4'b0000;
        end
    end

    // Read Port 1
    always @(*) begin
        dest_port_1 = 4'b1111; 
        if (valid_dest_1) begin
            for (i = 0; i < 16; i = i + 1) begin
                if (entry_valid[i] && (mac_memory[i] == read_mac_1)) begin
                    dest_port_1 = port_memory[i];
                end
            end
        end else begin
            dest_port_1 = 4'b0000;
        end
    end

    // Read Port 2
    always @(*) begin
        dest_port_2 = 4'b1111; 
        if (valid_dest_2) begin
            for (i = 0; i < 16; i = i + 1) begin
                if (entry_valid[i] && (mac_memory[i] == read_mac_2)) begin
                    dest_port_2 = port_memory[i];
                end
            end
        end else begin
            dest_port_2 = 4'b0000;
        end
    end

    // Read Port 3
    always @(*) begin
        dest_port_3 = 4'b1111; 
        if (valid_dest_3) begin
            for (i = 0; i < 16; i = i + 1) begin
                if (entry_valid[i] && (mac_memory[i] == read_mac_3)) begin
                    dest_port_3 = port_memory[i];
                end
            end
        end else begin
            dest_port_3 = 4'b0000;
        end
    end

endmodule