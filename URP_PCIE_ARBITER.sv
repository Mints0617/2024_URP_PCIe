module URP_PCIE_ARBITER
#(
    parameter N_MASTER = 2,
    parameter DATA_SIZE = 224
)
(
    input  logic clk,
    input  logic rst_n,  // _n means active low
    // configuration registers
    input  logic [N_MASTER-1:0] src_valid_i,
    output logic [N_MASTER-1:0] src_ready_o,
    input  logic [DATA_SIZE-1:0] src_data_i_0,
    input  logic [DATA_SIZE-1:0] src_data_i_1,
    output logic dst_valid_o,
    input  logic dst_ready_i,
    output logic [DATA_SIZE-1:0] dst_data_o
);
    logic [N_MASTER-1:0] current_master, next_master;
    logic dst_valid_next;
    logic [DATA_SIZE-1:0] next_dst_data_o;
    logic [DATA_SIZE-1:0] prev_dst_data; // 이전 출력 값을 저장

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_master <= '0;
            dst_valid_o <= 0;
            dst_data_o <= '0;
            prev_dst_data <= '0;
        end else begin
            current_master <= next_master;
            dst_data_o <= next_dst_data_o;

            // 데이터가 변경된 경우에만 dst_valid_o를 활성화
            if (next_dst_data_o != prev_dst_data) begin
                dst_valid_o <= 1;
                prev_dst_data <= next_dst_data_o;
            end else begin
                dst_valid_o <= 0;
            end
        end
    end

    always_comb begin
        dst_valid_next = 0;
        next_dst_data_o = dst_data_o;
        next_master = current_master;
        src_ready_o = 2'b0;

        for (int i = 0; i < N_MASTER; i++) begin
            logic [N_MASTER-1:0] check_master = (current_master + i) % N_MASTER;
            if (src_valid_i[check_master]) begin
                if (dst_ready_i) begin
                    src_ready_o[check_master] = 1;
                    dst_valid_next = 1;
                    case (check_master)
                        0: next_dst_data_o = src_data_i_0;
                        1: next_dst_data_o = src_data_i_1;
                        default: next_dst_data_o = '0;
                    endcase
                    next_master = (check_master + 1) % N_MASTER;
                end else begin
                    next_master = current_master;
                end
                break;
            end
        end
    end
endmodule
