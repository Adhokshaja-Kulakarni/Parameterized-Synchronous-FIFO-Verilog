`timescale 1ns/1ps

module sync_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 8;

    //loop variable for testing
    integer i;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire full;
    wire empty;

    // Instantiate the Design Under Test (DUT)
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

     // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Generate waveform file for GTKWave
    initial begin
        $dumpfile("waveform/fifo_wave.vcd");
        $dumpvars(0, sync_fifo_tb);
    end

    // Reset and initial input signals
    initial begin
        reset   = 1;
        wr_en   = 0;
        rd_en   = 0;
        data_in = 0;
        #12;
        reset = 0;
        
        // Write 10 into FIFO
        @(negedge clk);
        wr_en = 1;
        data_in = 8'd10;

        // Write 20 into FIFO
        @(negedge clk);
        data_in = 8'd20;

        // Write 30 into FIFO
        @(negedge clk);
        data_in = 8'd30;

        // Stop writing
        @(negedge clk);
        wr_en = 0;

        // Start reading from FIFO
        rd_en = 1;

        // Read first value
        @(posedge clk);
        #1;
        $display("Read 1 = %d", data_out);

        // Read second value
        @(posedge clk);
        #1;
        $display("Read 2 = %d", data_out);

        // Read third value
        @(posedge clk);
        #1;
        $display("Read 3 = %d", data_out);

        // Stop reading
        @(negedge clk);
        rd_en = 0;

        // Wait before starting FULL test
        #10;

        // Fill FIFO with 8 values
        $display("Starting FULL condition test");

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            wr_en = 1;
            data_in = (i + 1) * 10;
        end

        // Stop writing
        @(negedge clk);
        wr_en = 0;

        // Allow signals to settle
        #1;

        // Check FULL flag and occupancy
        if (full == 1'b1 && empty == 1'b0 && dut.count == DEPTH)
            $display("PASS: FIFO FULL condition detected");
        else
            $display("FAIL: FIFO FULL condition incorrect");

        // Test overflow protection
        $display("Starting OVERFLOW protection test");

        // Attempt to write 90 when FIFO is already full
        @(negedge clk);
        wr_en = 1;
        data_in = 8'd90;

        // Wait for the next rising edge
        @(posedge clk);
        #1;

        // Check that FIFO remains full
        if (full == 1'b1 && dut.count == DEPTH)
            $display("PASS: Overflow write blocked");
        else
            $display("FAIL: Overflow protection failed");

        // Stop writing
        @(negedge clk);
        wr_en = 0;
        
    
        // Test EMPTY condition
        $display("Starting EMPTY condition test");

        // Read all 8 stored values
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            rd_en = 1;

             @(posedge clk);
            #1;

            if (data_out === (i + 1) * 10)
                $display("PASS: Read value %0d", data_out);
            else
                $display("FAIL: Expected %0d, got %0d",
                    (i + 1) * 10, data_out);
        end

        // Stop reading
        @(negedge clk);
        rd_en = 0;
        #1;

        // Check EMPTY condition
        if (empty == 1'b1 && full == 1'b0 && dut.count == 0)
            $display("PASS: FIFO EMPTY condition detected");
        else
            $display("FAIL: FIFO EMPTY condition incorrect");

        // Test UNDERFLOW protection
        $display("Starting UNDERFLOW protection test");

        // Attempt one more read while empty
        @(negedge clk);
        rd_en = 1;
 
        @(posedge clk);
        #1;

        // Read pointer and count should remain unchanged
        if (empty == 1'b1 && dut.count == 0 && dut.rd_ptr == 3)
             $display("PASS: Underflow read blocked");
        else
            $display("FAIL: Underflow protection failed");

        // Stop reading
        @(negedge clk);
        rd_en = 0;

        // =======================================
        // SIMULTANEOUS READ AND WRITE TEST
        // =======================================
        
        $display("Starting SIMULTANEOUS READ/WRITE test");
        // First write 10 into the empty FIFO
        @(negedge clk);
        wr_en = 1;
        rd_en = 0;
        data_in = 8'd10;

        // Allow the write at the next rising edge
        @(posedge clk);
        #1;

        // Enable both read and write
        @(negedge clk);
        wr_en = 1;
        rd_en = 1;
        data_in = 8'd20;

        // Perform both operations on the next rising edge
        @(posedge clk);
        #1;

        // Debug simultaneous READ/WRITE
        $display("DEBUG: data_out = %0d", data_out);
        $display("DEBUG: count = %0d", dut.count);
        $display("DEBUG: wr_ptr = %0d", dut.wr_ptr);
        $display("DEBUG: rd_ptr = %0d", dut.rd_ptr);

        // Check simultaneous READ/WRITE
        if (data_out === 8'd10 &&
            dut.count == 1 &&
            dut.wr_ptr == 5 &&
            dut.rd_ptr == 4)
            $display("PASS: Simultaneous READ/WRITE");
        else
            $display("FAIL: Simultaneous READ/WRITE");

        // Stop both operations
        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        // Verify remaining value after simultaneous operation
        $display("Checking remaining FIFO data");

        @(negedge clk);
        rd_en = 1;

        @(posedge clk);
        #1;

        if (data_out === 8'd20 && empty == 1'b1 && dut.count == 0)
            $display("PASS: Remaining value 20 read correctly");
        else
            $display("FAIL: Remaining value verification");

        // Stop reading
        @(negedge clk);
        rd_en = 0;

        // End simulation
        #10;
        $finish;
   
    end
    
endmodule