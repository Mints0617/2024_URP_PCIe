`timescale 1ns/1ps

module URP_PCIE_TOP_TB;

    // Signal declarations
    logic clk;
    logic rst_n;

    // DUT input signals (TX)
    logic [127:0]   payload_i;
    logic [31:0] addr_i;
    logic [2:0] header_fmt_i;
    logic [4:0] header_type_i;
    logic [2:0] header_tc_i;
    logic [9:0] header_length_i;
    logic [15:0] header_requestID_i;
    logic [15:0] header_completID_i;

    // DUT output signals (RX)
    logic [127:0] payload_o;
    logic [31:0] addr_o;
    logic [2:0] header_fmt_o;
    logic [4:0] header_type_o;
    logic [2:0] header_tc_o;
    logic [9:0] header_length_o;
    logic [15:0] header_requestID_o;
    logic [15:0] header_completID_o;

    // Instantiate DUT
    URP_PCIE_TOP dut (
        .clk(clk),
        .rst_n(rst_n),

        .payload_i(payload_i),
        .addr_i(addr_i),
        .header_fmt_i(header_fmt_i),
        .header_type_i(header_type_i),
        .header_tc_i(header_tc_i),
        .header_length_i(header_length_i),
        .header_requestID_i(header_requestID_i),
        .header_completID_i(header_completID_i),

        .payload_o(payload_o),
        .addr_o(addr_o),
        .header_fmt_o(header_fmt_o),
        .header_type_o(header_type_o),
        .header_tc_o(header_tc_o),
        .header_length_o(header_length_o),
        .header_requestID_o(header_requestID_o),
        .header_completID_o(header_completID_o)
    );

    /*
    FILL YOUR CODES HERE
        TODO: implement your testbench here
    */

    
endmodule
