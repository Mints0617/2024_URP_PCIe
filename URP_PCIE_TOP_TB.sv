`timescale 1ns / 1ps

module URP_PCIE_TOP_TB;

    reg                             clk;
    reg                             rst_n;

    // Software interface - TX
    reg [127:0]                     payload_i;
    reg [31:0]                      addr_i;
    reg [2:0]                       header_fmt_i;
    reg [4:0]                       header_type_i;
    reg [2:0]                       header_tc_i;
    reg [9:0]                       header_length_i;
    reg [15:0]                      header_requestID_i;
    reg [15:0]                      header_completID_i;

    // Software interface - RX
    wire [127:0]                    payload_o;
    wire [31:0]                     addr_o;
    wire [2:0]                      header_fmt_o;
    wire [4:0]                      header_type_o;
    wire [2:0]                      header_tc_o;
    wire [9:0]                      header_length_o;
    wire [15:0]                     header_requestID_o;
    wire [15:0]                     header_completID_o;

    // Instantiate the DUT
    URP_PCIE_TOP dut (
        .clk                        (clk),
        .rst_n                      (rst_n),
        .payload_i                  (payload_i),
        .addr_i                     (addr_i),
        .header_fmt_i               (header_fmt_i),
        .header_type_i              (header_type_i),
        .header_tc_i                (header_tc_i),
        .header_length_i            (header_length_i),
        .header_requestID_i         (header_requestID_i),
        .header_completID_i         (header_completID_i),
        .payload_o                  (payload_o),
        .addr_o                     (addr_o),
        .header_fmt_o               (header_fmt_o),
        .header_type_o              (header_type_o),
        .header_tc_o                (header_tc_o),
        .header_length_o            (header_length_o),
        .header_requestID_o         (header_requestID_o),
        .header_completID_o         (header_completID_o)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20 rst_n = 1; // Deassert reset after 20ns
    end

    // Testbench logic
    initial begin
        // Wait for reset deassertion
        @(posedge rst_n);

        // Test Case 1: Memory Request (TC = 000)
        #10;
        payload_i = 128'hDEADBEEFCAFEBABE0000000000000000;
        addr_i = 32'h12345678;
        header_fmt_i = 3'b010;
        header_type_i = 5'b00000;  // Memory Request
        header_tc_i = 3'b000;     // Virtual Channel 0
        header_length_i = 10'd4;
        header_requestID_i = 16'hABCD;
        header_completID_i = 16'h0000;
        #20
        

        // Test Case 2: Completion Request (TC = 101)
        payload_i = 128'hBAD0C0FFEE1234560000000000000000;
        addr_i = 32'h87654321;
        header_fmt_i = 3'b001;
        header_type_i = 5'b01010;  // Completion Request
        header_tc_i = 3'b101;     // Virtual Channel 1
        header_length_i = 10'd8;
        header_requestID_i = 16'h1234;
        header_completID_i = 16'h5678; // Completion ID


        // Test Case 3: Memory Request (TC = 011)
        #20;
        payload_i = 128'h3456C0FFEE1234560000000000000000;
        addr_i = 32'h0000FFFF;    
        header_fmt_i = 3'b011;
        header_type_i = 5'b00001;  // Memory Request
        header_tc_i = 3'b011;     // Virtual Channel 1
        header_length_i = 10'd16; 
        header_requestID_i = 16'hFFFF;
        header_completID_i = 16'h0000;
        #20
        
        // Test Case 4: Invalid Header Type
        payload_i = 128'h1234C0FFEE1234560000000000000000;
        addr_i = 32'h1000FFFF;   
        header_fmt_i = 3'b001;
        header_type_i = 5'b11001; // Invalid Header Type
        header_tc_i = 3'b001;     
        header_length_i = 10'd8; 
        header_requestID_i = 16'h1234;
        header_completID_i = 16'h5678; 
        #40; // Allow transaction to process
    end

endmodule