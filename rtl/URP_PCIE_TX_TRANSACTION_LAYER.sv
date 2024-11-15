module URP_PCIE_TX_TRANSACTION_LAYER (
    input   logic                   clk,
    input   logic                   rst_n,

    input   logic   [127:0]         payload_i,
    input   logic   [31:0]          addr_i,
    input   logic   [2:0]           header_fmt_i,
    input   logic   [4:0]           header_type_i,
    input   logic   [2:0]           header_tc_i,
    input   logic   [9:0]		    header_length_i,
    input   logic   [15:0]          header_requestID_i,
    input   logic   [15:0]          header_completID_i,

    output  logic   [223:0]         tlp_o,
    output  logic                   tlp_valid_o,
    input   logic                   tlp_ready_i
);

    /*
    FILL YOUR CODES HERE
        Packetizer / FIFO*2 / Arbiter
    */
   
endmodule