module URP_PCIE_RX_TRANSACTION_LAYER (
    input   logic                   clk,
    input   logic                   rst_n,

    // Data link layer interface
    input   logic   [223:0]         tlp_data_i,
    input   logic                   tlp_data_valid_i,
    output  logic                   tlp_data_ready_o,

    output  logic   [127:0]         payload_o,
    output  logic   [31:0]          addr_o,
    output  logic   [2:0]           header_fmt_o,
    output  logic   [4:0]           header_type_o,
    output  logic   [2:0]           header_tc_o,
    input   logic   [9:0]		    header_length_o,
    output  logic   [15:0]          header_requestID_o,
    output  logic   [15:0]          header_completID_o
);

    /*
    FILL YOUR CODES HERE
        FIFO*2 / Arbiter / De_Packetizer
    */


endmodule