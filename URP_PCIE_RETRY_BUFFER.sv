module RETRY_BUFFER #(
    parameter DEPTH_LG2     = 4,   // FIFO�� ���̸� log2�� ǥ��
    parameter DATA_WIDTH    = 268  // ������ �� (TLP�� ũ��)
)
(
    input   logic                    clk,              // Ŭ�� ��ȣ
    input   logic                    rst_n,            // �񵿱� ���� (active low)

    // �Է� ��ȣ
    input   logic                    wren_i,           // ���� Ȱ�� ��ȣ
    input   logic [DATA_WIDTH-1:0]   wdata_i,          // �Է� TLP ������
    input   logic                    delete_enable,    // Ư�� Sequence ���� ���� ��ȣ
    input   logic [11:0]             seq_to_delete,    // ������ Sequence ��ȣ

    // ��� ��ȣ
    output  logic [DATA_WIDTH-1:0]   rdata_o           // ��� TLP ������
);

    localparam FIFO_DEPTH = (1 << DEPTH_LG2);         // FIFO ���� ���

    // FIFO �����
    logic [DATA_WIDTH-1:0] data[FIFO_DEPTH];          // TLP �����͸� �����ϴ� �޸�

    // �б� �� ���� ������
    logic [DEPTH_LG2-1:0] wrptr, rdptr;              // ����, �б� ������

    // ��ȿ �÷���
    logic [FIFO_DEPTH-1:0] valid;                    // �� ��Ʈ���� ��ȿ ���θ� ��Ÿ���� �÷���
    logic  modulous;                                 // rdptr �ø��� �ӵ� ������
    logic first;
    
    // Sequential Logic (Ŭ�� ��� ����)
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // �ʱ�ȭ
            wrptr <= 0;
            rdptr <= 0;
            valid <= 0;
            modulous <= 0;  
            first <= 0;             //ó�� Rdptr ������ rdptr <= 0���� �ǰ�
    end else begin
        // ����
        if (delete_enable) begin
            int i, j;
            j = 0;

            // valid ��ȣ�� ������ �̵�
            for (i = 0; i < FIFO_DEPTH; i++) begin
                // Seq_to_delete ���� ����
                if (valid[i] && data[i][267:256] > seq_to_delete) begin 
                    if (i != j) begin
                        data[j] <= data[i];  // ������ �̵�
                        valid[j] <= valid[i];
                    end
                    j = j + 1;
                end
            end

            // �� ���� �ʱ�ȭ
            for (i = j; i < FIFO_DEPTH; i++) begin
                valid[i] <= 1'b0;
                data[i] <= {DATA_WIDTH{1'b0}};
            end

            // ������ ����
            wrptr <= j;  // �� wrptr�� ��ȿ �������� ��
            if(!first) begin
            rdptr <= 0;  // �б� ������ �ʱ�ȭ
            first <= first + 1;
            end
        end
        if (!delete_enable) begin
            first <= 0;
        end
        // ����
        if (wren_i) begin
            data[wrptr] <= wdata_i;
            valid[wrptr] <= 1'b1;
            wrptr <= wrptr + 1;
        end

        // �б�
        if (valid[rdptr]) begin
            if (!delete_enable) begin
            rdptr <= rdptr + 1;
            modulous <= 0;
            end
            // �ι����� �� ���� rdptr �ø���
            else if (delete_enable && !(modulous % 2)) begin
            rdptr <= rdptr + 1;
            modulous <= modulous +1;
            end
            else if (delete_enable && (modulous % 2)) begin
            modulous <= modulous +1;
            end
        end
    end
end

    // ��� �� (�ڵ����� �����͸� �о��)
    assign rdata_o = (valid[rdptr]) ? data[rdptr] : {DATA_WIDTH{1'b0}};  // ��ȿ�� �����͸� ���
    assign rdata_valid = valid[rdptr];  // ���� �б� �����Ͱ� ��ȿ�� �����͸� ����ų �� 1
endmodule