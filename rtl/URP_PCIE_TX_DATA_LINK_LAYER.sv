module URP_TX_DATA_LINK_LAYER
(
    input   logic                   clk,
    input   logic                   rst_n,

    // Transaction layer interface
    input   logic [223:0]           tlp_data_i,
    input   logic                   tlp_data_valid_i,
    output  logic                   tlp_data_ready_o,

    // RX interface
    output  logic [267:0]           tlp_data_o,
    output  logic                   tlp_data_valid_o,
    input   logic                   tlp_data_ready_i
);

    /*
        FILL YOUR CODES HERE
        LCRC generation / Add sequence number / Add retry buffer & retransmission
    */


endmodule
