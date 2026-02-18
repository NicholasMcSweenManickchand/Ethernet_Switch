module FIFO(
    input wire rx_valid_bytes, clk, reset, //control signal is useless since rx_valid_bytes relies on it to be on;
    input wire allow_output, // special input allowing us to only streamline/pipeline the data when asked
    input wire [7:0] rx_data,
    output wire [7:0] tx_data
);
reg [7:0] tx_data_storage [2047:0]; //RAM (max IEEE standard packet is 1500 bytes so we should be safe with the closest 2x multiple)
reg [11:0] writer_count; // exta lap counter bit [11]
reg [11:0] reader_count; 
wire full, empty; // potentially add an "almost_full" if needed to warn other modules due to latency

assign full = (writer_count[11] != reader_count[11]) && (writer_count[10:0] == reader_count[10:0]); // see if full
assign empty = writer_count == reader_count; // see if empty

always @(posedge clk) begin
    if (reset) begin
        writer_count <= 12'h0;
        reader_count <= 12'h0;
    end
    else begin
        if (rx_valid_bytes && !full) begin
            writer_count <= writer_count + 1;
            tx_data_storage[writer_count[10:0]] <= rx_data; // stores data in approriate slot/"box"
        end
        if (allow_output && !empty) begin
            reader_count <= reader_count + 1; 
        end
    end
end

assign tx_data = tx_data_storage[reader_count[10:0]]; // don't have to wait or be as careful when reading so can instantly output
endmodule
