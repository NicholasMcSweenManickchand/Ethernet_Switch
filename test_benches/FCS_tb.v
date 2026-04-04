module FCS_tb;

    reg [7:0] data;
    reg clk, reset, valid_data; // tells us if we are ok to keep going or FIFO paused
    reg done; // 9th bit of FIFO is 1
    wire [31:0] rx_crc;

    FCS u1(
        .data(data),
        .clk(clk),
        .reset(reset),
        .valid_data(valid_data),
        .done(done),
        .rx_crc(rx_crc)
    );

always #4 clk = ~clk;

integer i;
reg [31:0] expected_out; // for golden vector operations
reg [31:0] magic_res_FCS;
initial begin
    clk = 0;
    reset = 0;
    valid_data = 1;
    done = 0;

    // empty data (data = h'00):
    data = 8'h00;
    repeat (2) begin
        @(negedge clk)begin
            reset = ~reset; // reset pulse
        end
    end
    $display("data is h'00 and will run for 4 clock cycles:");
    expected_out = 32'h2144DF1C;
    repeat (2) begin // 4 - 2 since it would have to wait for the next one after the initial data = h'00 & display occurs at another negedge;
        @(negedge clk) begin
        end
    end

    @(negedge clk);
    $display("The expected output is: %h", expected_out);
    $display("The actual output is: %h", rx_crc);
    $display("Are they the same? (1 is yes 0 is no): %b", expected_out == rx_crc);

    // standard ASCII test (123456789)
    $display("data is for the ASCII test (123456789) and will run for 9 clock cycles:");
    data = 32'h31;
    reset = 1;
    @(negedge clk)begin
        reset = 0;
        data = data + 1;
    end

    expected_out = 32'hCBF43926;
    repeat (7) begin // 9 - 2 see previous negedge block and surrounding logic
        @(negedge clk) begin
            data = data + 1;
        end
    end

    @(negedge clk);
    $display("The expected output is: %h", expected_out);
    $display("The actual output is: %h", rx_crc);
    $display("Are they the same? (1 is yes 0 is no): %b", expected_out == rx_crc);

    //magic residue test (using the same ASCII inputs as previous test):
    magic_res_FCS = rx_crc;
    expected_out = 32'hC704DD7B;
    $display("Now appending crcOut to check for magic residue:");
    data = magic_res_FCS[7:0];
    for (i = 1; i < 4; i = i + 1)begin
        @(negedge clk)begin
            data = magic_res_FCS[8*i +: 8];
        end
    end

    @(negedge clk);
    $display("The expected output is: %h", expected_out);
    $display("The actual output is: %h", rx_crc);
    $display("Are they the same? (1 is yes 0 is no): %b", expected_out == rx_crc);

    $finish;
end
endmodule