module URP_PCIE_RX_DATA_LINK_LAYER (
    input   logic                   clk,
    input   logic                   rst_n,

    // TX interface     
    input   logic   [267:0]         tlp_data_i,
    input   logic                   tlp_data_valid_i,
    output  logic                   tlp_data_ready_o,

    output  logic   [31:0]          dllp_o,
    output  logic                   dllp_valid_o,
    input   logic                   dllp_read_i,

    // Transaction layer interface
    output  logic   [223:0]         tlp_data_o,
    output  logic                   tlp_data_valid_o,
    input   logic                   tlp_data_ready_i
);

    /*
    FILL YOUR CODES HERE
        LCRC Check / Sequence number check / DLLP generation
    */



endmodule