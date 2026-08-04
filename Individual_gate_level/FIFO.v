`default_nettype none

module FIFO(
    input wire rx_valid_bytes, Write_clk, Read_clk,
    input wire reset, 
    input wire allow_output, 
    input wire [7:0] rx_data,
    output wire [8:0] tx_data,
    
    // NEW: Exposing the empty flag to the outside world is highly recommended.
    // In cut-through, the read clock might drift and catch up to the write clock.
    output wire empty 
);
    
    reg [8:0] tx_data_storage [2047:0]; 
    reg [11:0] writer_count; 
    reg [11:0] reader_count; 
    
    // CHANGED: Added a 1-clock-cycle delay buffer for the incoming data.
    // This is required to correctly tag the End-of-Frame (EOF) 9th bit.
    reg [7:0] rx_data_delayed;
    reg rx_valid_bytes_delayed;
    
    wire [11:0] grey_writer, grey_reader;
    wire full; 

    reg [11:0] grey_read_readside, grey_read_writeside_reg1, grey_read_writeside_reg2;
    reg [11:0] grey_write_writeside, grey_write_readside_reg1, grey_write_readside_reg2;

    // Gray code conversions for safe clock domain crossing
    assign grey_writer = writer_count ^ (writer_count >> 1);
    assign grey_reader = reader_count ^ (reader_count >> 1);

    assign full = (grey_writer[11:10] == ~grey_read_writeside_reg2[11:10]) && (grey_writer[9:0] == grey_read_writeside_reg2[9:0]); 
    assign empty = (grey_reader == grey_write_readside_reg2);

    // --- WRITE CLOCK DOMAIN ---
    always @(posedge Write_clk) begin
        if (reset) begin
            writer_count <= 12'h0;
            rx_valid_bytes_delayed <= 1'b0;
            rx_data_delayed <= 8'h0; // NEW: Reset the data buffer
            grey_write_writeside <= 12'b0;
            grey_read_writeside_reg1 <= 12'b0;
            grey_read_writeside_reg2 <= 12'b0;
        end
        else begin
            // Buffer the incoming control signal and data by exactly 1 clock cycle
            rx_valid_bytes_delayed <= rx_valid_bytes;
            rx_data_delayed <= rx_data;

            grey_write_writeside <= grey_writer;
            grey_read_writeside_reg1 <= grey_read_readside;
            grey_read_writeside_reg2 <= grey_read_writeside_reg1; 
            
            // CHANGED: EOF Tagging Logic
            // Instead of writing a completely new blank byte to hold the EOF flag, 
            // we look ahead. If the delayed byte is valid, but the CURRENT incoming 
            // byte is invalid (!rx_valid_bytes), we know the delayed byte was the final one.
            if (rx_valid_bytes_delayed && !full) begin 
                writer_count <= writer_count + 1;
                
                if (!rx_valid_bytes) begin
                    // This is the last valid byte of the packet. Tag the 9th bit HIGH.
                    tx_data_storage[writer_count[10:0]] <= {1'b1, rx_data_delayed}; 
                end
                else begin
                    // This is a standard payload byte. Tag the 9th bit LOW.
                    tx_data_storage[writer_count[10:0]] <= {1'b0, rx_data_delayed}; 
                end
            end
        end
    end

    // --- READ CLOCK DOMAIN ---
    always @(posedge Read_clk) begin
        if (reset) begin
            reader_count <= 12'h0;
            grey_read_readside <= 12'b0;
            grey_write_readside_reg1 <= 12'b0;
            grey_write_readside_reg2 <= 12'b0;
        end
        else begin
            grey_read_readside <= grey_reader;
            grey_write_readside_reg1 <= grey_write_writeside;
            grey_write_readside_reg2 <= grey_write_readside_reg1;

            // CHANGED: The allow_output signal directly drives the continuous stream.
            if (allow_output && !empty) begin
                reader_count <= reader_count + 1; 
            end
        end
    end

    // Asynchronous read assignment (First-Word Fall-Through)
    // The Arbiter will immediately see the data at the reader_count address.
    assign tx_data = tx_data_storage[reader_count[10:0]]; 

endmodule