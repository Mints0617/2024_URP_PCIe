module URP_PCIE_RX_TRANSACTION_LAYER (
    input   logic                   clk,
    input   logic                   rst_n,
    // Data link layer interface
    input   logic   [223:0]         tlp_data_i,
    input   logic                   tlp_data_valid_i,
    output  logic                   tlp_data_ready_o,
    // Output to higher layer
    output  logic   [127:0]         payload_o,
    output  logic   [31:0]          addr_o,
    output  logic   [2:0]           header_fmt_o,
    output  logic   [4:0]           header_type_o,
    output  logic   [2:0]           header_tc_o,
    output  logic   [9:0]           header_length_o,
    output  logic   [15:0]          header_requestID_o,
    output  logic   [15:0]          header_completID_o
);
    // FIFO Outputs
    logic [223:0] fifo0_rdata, fifo1_rdata;
    logic         fifo0_empty, fifo1_empty;
    logic         fifo0_rden, fifo1_rden;
    // Arbiter Signals
    logic [1:0]   fifo_valid;        // Valid signals for Arbiter
    logic         arbiter_valid;
    logic [223:0] arbiter_data;
    logic [1:0]   src_ready_o;
    // FIFO for Virtual Channel 0
    URP_PCIE_FIFO #(
        .DEPTH_LG2(4),               // FIFO depth (16 slots)
        .DATA_WIDTH(224)             // Each slot stores one TLP
    ) fifo0 (
        .clk(clk),
        .rst_n(rst_n),
        .wren_i((tlp_data_i[215:213] == 3'b000 || 
                 tlp_data_i[215:213] == 3'b001 || 
                 tlp_data_i[215:213] == 3'b010 || 
                 tlp_data_i[215:213] == 3'b011) && tlp_data_valid_i),
        .wdata_i(tlp_data_i),
        .full_o(),
        .afull_o(),
        .empty_o(fifo0_empty),
        .aempty_o(),
        .rden_i(fifo0_rden),
        .rdata_o(fifo0_rdata)
    );
    // FIFO for Virtual Channel 1
    URP_PCIE_FIFO #(
        .DEPTH_LG2(4),               // FIFO depth (16 slots)
        .DATA_WIDTH(224)             // Each slot stores one TLP
    ) fifo1 (
        .clk(clk),
        .rst_n(rst_n),
        .wren_i((tlp_data_i[215:213] == 3'b100 || 
                 tlp_data_i[215:213] == 3'b101 || 
                 tlp_data_i[215:213] == 3'b110 || 
                 tlp_data_i[215:213] == 3'b111) && tlp_data_valid_i),
        .wdata_i(tlp_data_i),
        .full_o(),
        .afull_o(),
        .empty_o(fifo1_empty),
        .aempty_o(),
        .rden_i(fifo1_rden),
        .rdata_o(fifo1_rdata)
    );
    // Arbiter for Virtual Channels
    assign fifo_valid = {~fifo1_empty, ~fifo0_empty};
    assign {fifo1_rden, fifo0_rden} = src_ready_o & {~fifo1_empty, ~fifo0_empty};
    URP_PCIE_ARBITER #(
        .N_MASTER(2),
        .DATA_SIZE(224)
    ) arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .src_valid_i(fifo_valid),
        .src_ready_o(src_ready_o),
        .src_data_i_0(fifo0_rdata),
        .src_data_i_1(fifo1_rdata),
        .dst_valid_o(arbiter_valid),
        .dst_ready_i(tlp_data_ready_o),
        .dst_data_o(arbiter_data)
    );
    // Internal signal registers (for state)
    logic [2:0] header_fmt_r, header_tc_r;
    logic [4:0] header_type_r;
    logic [9:0] header_length_r;
    logic [15:0] header_requestID_r, header_completID_r;
    logic [31:0] addr_r;
    logic [127:0] payload_r;
    // State update logic (always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            header_fmt_r        <= 3'b0;
            header_type_r       <= 5'b0;
            header_tc_r         <= 3'b0;
            header_length_r     <= 10'b0;
            header_requestID_r  <= 16'b0;
            header_completID_r  <= 16'b0;
            addr_r              <= 32'b0;
            payload_r           <= 128'b0;
        end else if (arbiter_valid && tlp_data_ready_o) begin
            // Extract common fields
            header_fmt_r       <= arbiter_data[223:221];
            header_type_r      <= arbiter_data[220:216];
            header_tc_r        <= arbiter_data[215:213];
            header_length_r    <= arbiter_data[212:203];
            payload_r          <= arbiter_data[127:0];
            // Handle specific packet types based on header_type
            if (arbiter_data[220:216] == 5'b00000 || arbiter_data[220:216] == 5'b00001) begin
                // Memory Request Type (Message Request)
                header_requestID_r  <= arbiter_data[191:176];
                addr_r              <= {arbiter_data[175:160], arbiter_data[159:146], 2'b0};
                header_completID_r  <= 16'b0; // Message Request에는 completID 없음
            end else if (arbiter_data[220:216] == 5'b01010) begin
                // Completion Request Type
                header_requestID_r  <= arbiter_data[191:176];
                header_completID_r  <= arbiter_data[175:160];
                addr_r              <= {arbiter_data[159:130], 2'b0}; // 30비트 Address
            end else begin
                // Unknown Type
                header_requestID_r  <= 16'b0;
                header_completID_r  <= 16'b0;
                addr_r              <= 32'b0;
            end
        end
    end
    // Output logic (always_comb)
    always_comb begin
        header_fmt_o       = header_fmt_r;
        header_type_o      = header_type_r;
        header_tc_o        = header_tc_r;
        header_length_o    = header_length_r;
        payload_o          = payload_r;
        addr_o             = addr_r;
        header_requestID_o = header_requestID_r;
        header_completID_o = header_completID_r;
    end
    // TLP Data Ready Signal
    assign tlp_data_ready_o = 1'b1; // FIFO가 비지 않으면 데이터 처리 가능
endmodule