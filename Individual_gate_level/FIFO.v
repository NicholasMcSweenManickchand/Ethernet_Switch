module FIFO(
    input wire rx_valid_bytes, Write_clk, Read_clk,//the write clock is the sending port clokc and read clk is the internal clk
    input wire reset, //control signal is useless since rx_valid_bytes relies on it to be on;
    input wire allow_output, // special input allowing us to only streamline/pipeline the data when asked
    input wire [7:0] rx_data,
    output wire [8:0] tx_data
);
reg [8:0] tx_data_storage [2047:0]; //RAM (max IEEE standard packet is 1500 bytes so we should be safe with the closest 2's exponent)
reg [11:0] writer_count; // extra lap counter bit [11]
reg [11:0] reader_count; 
reg rx_valid_bytes_delayed;
wire [11:0] grey_writer, grey_reader;
reg full, empty; // potentially add an "almost_full" if needed to warn other modules due to latency
reg [11:0] grey_read_readside, grey_read_writeside_reg1, grey_read_writeside_reg2;
reg [11:0] grey_write_writeside, grey_write_readside_reg1, grey_write_readside_reg2;

//make counters into grey code for domain crossing
assign grey_writer = writer_count ^ (writer_count >> 1);
assign grey_reader = reader_count ^ (reader_count >> 1);


always @(posedge Write_clk) begin
    if (reset) begin
        writer_count <= 12'h0;
        rx_valid_bytes_delayed <= 1'b0;
    end
    else begin
        rx_valid_bytes_delayed <= rx_valid_bytes;

        grey_write_writeside <= grey_writer;

        // create the delay necessary to cross domains
        grey_read_writeside_reg1 <= grey_read_readside;
        grey_read_writeside_reg2 <= grey_read_writeside_reg1; 
        
        if (!rx_valid_bytes && rx_valid_bytes_delayed) begin
            writer_count <= writer_count + 1;
            tx_data_storage[writer_count[10:0]] <= {1'b1, rx_data};
        end
        if (rx_valid_bytes && !full) begin
            writer_count <= writer_count + 1;
            tx_data_storage[writer_count[10:0]] <= {1'b0, rx_data}; // stores data in approriate slot/"box"
        end
    end
end

always @(posedge Read_clk) begin
    if (reset) begin
        reader_count <= 12'h0;
    end
    else begin
        grey_read_readside <= grey_reader;

        // create the delay necessary to cross domains
        grey_write_readside_reg1 <= grey_write_writeside;
        grey_write_readside_reg2 <= grey_write_readside_reg1;

        if (allow_output && !empty) begin
            reader_count <= reader_count + 1; 
        end
    end
end

// TO DO: Convert to BRAM (Synchronous Read) when scaling to 64-bit width/ 10G.
assign tx_data = tx_data_storage[reader_count[10:0]]; // don't have to wait or be as careful when reading so can instantly output
endmodule


//TO DO:
// -Make Full and Empty signals