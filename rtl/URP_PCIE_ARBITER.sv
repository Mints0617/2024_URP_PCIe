module URP_PCIE_ARBITER
#(
    N_MASTER                    = 2,
    DATA_SIZE                   = 224
)
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    // configuration registers
    input   wire                        src_valid_i[N_MASTER],
    output  reg                         src_ready_o[N_MASTER],
    input   wire    [DATA_SIZE-1:0]     src_data_i[N_MASTER],

    output  reg                         dst_valid_o,
    input   wire                        dst_ready_i,
    output  reg     [DATA_SIZE-1:0]     dst_data_o
);
    /*
    FILL YOUR CODES HERE
        TODO: implement your arbiter here
    */
   


endmodule
