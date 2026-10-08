module sync_fifo #(
    parameter DATA_WIDTH=8,
    parameter DEPTH=8
)(
    input wire clk,
    input wire reset,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] data_in,
    
    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    // FIFO memory
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    // Number of bits required to address FIFO locations
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Read and write pointers
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    // Number of valid entries currently stored
    reg [ADDR_WIDTH:0] count;

    // FIFO status flags
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
            data_out <= 0;
        end
        
        else begin
            
            // Write operation
            if (wr_en && !full) begin
                memory[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1'b1;
            end
        

            // Read operation
             if (rd_en && !empty) begin
                data_out <= memory[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Update FIFO count
             case ({wr_en && !full, rd_en && !empty})
             2'b10: count <= count + 1'b1;  // Write only
             2'b01: count <= count - 1'b1;  // Read only
             2'b11: count <= count;         // Write and read
             2'b00: count <= count;         // No operation
             endcase
             
        end
    end
endmodule