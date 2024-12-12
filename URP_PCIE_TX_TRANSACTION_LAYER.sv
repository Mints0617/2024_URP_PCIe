module URP_PCIE_TX_TRANSACTION_LAYER (
    input   logic                   clk,
    input   logic                   rst_n,
    input   logic   [127:0]         payload_i,
    input   logic   [31:0]          addr_i,
    input   logic   [2:0]           header_fmt_i,
    input   logic   [4:0]           header_type_i,
    input   logic   [2:0]           header_tc_i,
    input   logic   [9:0]           header_length_i,
    input   logic   [15:0]          header_requestID_i,
    input   logic   [15:0]          header_completID_i,
    output  logic   [223:0]         tlp_o,
    output  logic                   tlp_valid_o,
    input   logic                   tlp_ready_i
);
    logic [223:0] tlp_i_reg, tlp_i_next;
    logic         tlp_valid_reg, tlp_valid_next;
    // FIFO
    logic [223:0] fifo0_rdata, fifo1_rdata;
    logic         fifo0_empty, fifo1_empty;
    logic         fifo0_rden, fifo1_rden;
    // Arbiter
    logic [1:0]   src_valid_i;
    logic [1:0]   src_ready_o;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlp_i_reg <= 224'b0;
            tlp_valid_reg <= 1'b0;
            tlp_valid_reg <= 1'b0;
        end else begin
            tlp_i_reg <= tlp_i_next;
            tlp_valid_reg <= tlp_valid_next;
        end
    end
    always_comb begin
        tlp_i_next = tlp_i_reg;
        tlp_valid_next = 1'b0;
        if (tlp_ready_i) begin
            // Memory Request
            if (header_type_i == 5'b00000 || header_type_i == 5'b00001) begin
                tlp_i_next = {
                    header_fmt_i, header_type_i, header_tc_i, header_length_i,
                    7'b0, 4'b0,
                    header_requestID_i, addr_i[31:16],
                    addr_i[15:2], 18'b0, payload_i
                };
                tlp_valid_next = ~tlp_valid_reg;
            end
            // Completion Request
            else if (header_type_i == 5'b01010) begin
                tlp_i_next = {
                    header_fmt_i, header_type_i, header_tc_i, header_length_i,
                    7'b0, 4'b0,
                    header_requestID_i, header_completID_i,
                    addr_i[31:2], 2'b0, payload_i
                };
                tlp_valid_next = ~tlp_valid_reg;
            end
        end
    end
    // FIFO for Virtual Channel 0 ( TC 0 ~ TC 3 )
    URP_PCIE_FIFO #(
        .DEPTH_LG2(4),
        .DATA_WIDTH(224)
    ) fifo0 (
        .clk(clk),
        .rst_n(rst_n),
        .wren_i((tlp_i_reg[215:213] == 3'b000 || 
                 tlp_i_reg[215:213] == 3'b001 || 
                 tlp_i_reg[215:213] == 3'b010 || 
                 tlp_i_reg[215:213] == 3'b011) && tlp_valid_reg && tlp_ready_i),
        .wdata_i(tlp_i_reg),
        .full_o(),
        .afull_o(),
        .empty_o(fifo0_empty),
        .aempty_o(),
        .rden_i(fifo0_rden),
        .rdata_o(fifo0_rdata)
    );
    // FIFO for Virtual Channel 1 ( TC 4 ~ TC 7 )
    URP_PCIE_FIFO #(
        .DEPTH_LG2(4),
        .DATA_WIDTH(224)
    ) fifo1 (
        .clk(clk),
        .rst_n(rst_n),
        .wren_i((tlp_i_reg[215:213] == 3'b100 || 
                 tlp_i_reg[215:213] == 3'b101 || 
                 tlp_i_reg[215:213] == 3'b110 || 
                 tlp_i_reg[215:213] == 3'b111) && tlp_valid_reg && tlp_ready_i),
        .wdata_i(tlp_i_reg),
        .full_o(),
        .afull_o(),
        .empty_o(fifo1_empty),
        .aempty_o(),
        .rden_i(fifo1_rden),
        .rdata_o(fifo1_rdata)
    );
    // Arbiter
    logic dst_ready_i;
    assign dst_ready_i = tlp_ready_i;
    assign src_valid_i = {~fifo1_empty, ~fifo0_empty};
    assign {fifo1_rden, fifo0_rden} = src_ready_o & {~fifo1_empty, ~fifo0_empty};
    URP_PCIE_ARBITER #(
        .N_MASTER(2),
        .DATA_SIZE(224)
    ) arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .src_data_i_0(fifo0_rdata),
        .src_data_i_1(fifo1_rdata),
        .dst_valid_o(tlp_valid_o),
        .dst_ready_i(dst_ready_i),
        .dst_data_o(tlp_o)
    );
endmodule