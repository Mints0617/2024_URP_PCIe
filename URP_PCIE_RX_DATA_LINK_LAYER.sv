module URP_PCIE_RX_DATA_LINK_LAYER (
    input   logic                   clk,
    input   logic                   rst_n,

    // TX interface     
    input   logic   [267:0]         tlp_data_i,
    input   logic                   tlp_data_valid_i,
    output  logic                   tlp_data_ready_o,

    output  logic   [31:0]          dllp_o,
    output  logic                   dllp_valid_o,
    input   logic                   dllp_ready_i,

    // Transaction layer interface
    output  logic   [223:0]         tlp_data_o,
    output  logic                   tlp_data_valid_o,
    input   logic                   tlp_data_ready_i
);

    // LCRC ��ȣ
    logic RX_crc_valid_o;       
    logic [223:0] RX_crc_data_o;
    logic [31:0] RX_crc_checksum;
    
    
    // ���� ��ȣ
    logic [11:0] Nrs;                  // RX_dll ������ sequence ��
    logic [2:0]  Latency_Timer;        // Ack Timer �� ����
    logic        RX_Ack, RX_Nak;
    logic        Buff_valid;           //CRC Genderator�� valid�� buffer
    logic [267:256]  buff_seq;         //Tlp�� ���� Data�� Seq ����     
    logic [31:0]     buff_crc;         //Tlp�� ���� Data�� lcrc ����  
    logic [255:32]   buff_tlp_o;       //Tlp�� ���� Data�� Header & Data ���� 
   
    // LCRC Check & Sequence Number Check
    URP_PCIE_CRC32_ENC #(
        .DATA_WIDTH(224),
        .CRC_WIDTH(32)
    ) u_lcrc_gen (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(tlp_data_valid_i),     // �� �����ϸ� �Ǵ���
        .data_i(tlp_data_i[255:32]),    // TLP DATA�� [255:32]�� Header + Data�� CRC ���
        .valid_o(RX_crc_valid_o),       // ���� ������ valid �� ����
        .data_o(RX_crc_data_o),         // �׳� ���ļ� ���� ��
        .checksum_o(RX_crc_checksum)    // RX ��⿡�� üũ������ ���� ��
    );

    // Always block for logic and FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // �ʱ�ȭ
            tlp_data_ready_o <= 1'b1;   //�̷��� �ؾ� ������ �� ���� �� ����
            dllp_o           <= 32'b0;
            dllp_valid_o     <= 1'b0;
            tlp_data_o       <= 224'b0;
            tlp_data_valid_o <= 1'b0;
            Nrs              <= 12'b1;
            Latency_Timer    <= 3'b001;   
            RX_Ack           <= 1'b0;
            RX_Nak           <= 1'b0;
            Buff_valid       <= 1'b0;
            buff_seq         <= 12'b0;
            buff_crc         <= 32'b0;
            buff_tlp_o       <= 224'b0;
        end 
        else begin            
            RX_Ack           <= 1'b0;  // �ʱ�ȭ
            dllp_valid_o     <= 1'b0;
            dllp_o           <= 32'b0;
            tlp_data_valid_o <= 1'b0;
            Buff_valid <= RX_crc_valid_o;          //CRC Genderator�� valid�� buffer
            buff_seq <= tlp_data_i[267:256];       //Tlp�� ���� Data�� Seq ���� 
            buff_crc <= tlp_data_i[31:0];          //Tlp�� ���� Data�� lcrc ���� 
            if(tlp_data_valid_i) begin
                buff_tlp_o <=  tlp_data_i[255:32]; //Tlp�� ���� Data�� Header & Data ����                
            end

            if (RX_crc_valid_o) begin
                // LCRC �� �� Sequence Number ��
                if (buff_crc == RX_crc_checksum) begin
                    // LCRC�� ��ġ�ϴ� ���, NRS�� Sequence Number ��
                    if (buff_seq > Nrs) begin
                        RX_Nak   <= 1'b1;  // NACK ����
                        RX_Ack   <= 1'b0;
                    end else begin
                        Nrs <= Nrs + 1;   // ������ ��ȣ ������Ʈ
                        RX_Ack <= 1'b1;  // ACK ���� �غ�
                        RX_Nak <= 1'b0;
                    end
                end else begin
                    RX_Nak <= 1'b1;      // LCRC ����ġ
                    RX_Ack <= 1'b0;
                end
            end
            
            if (RX_Nak) begin
                // NACK ����
                dllp_o <= {20'b00010000111111111111, Nrs - 12'b1};  
                dllp_valid_o     <= 1'b1;
                tlp_data_o       <= 223'b0;  // NACK �� ������ ���� �� ��
                tlp_data_valid_o <= 1'b0;    // NACK �� ������ ���� �� ��
                tlp_data_ready_o <= 1'b1;    // ������ ���� ����
                Latency_Timer    <= 3'b001;    // Timer �ʱ�ȭ
            end
            
            if (RX_Ack) begin
                // ACK ó��
                if(tlp_data_ready_i) begin
                    tlp_data_o       <= buff_tlp_o;      // header�� data �и�
                    tlp_data_valid_o <= Buff_valid;   
                end        

                if (Latency_Timer < 3'b110) begin
                    // �������� �ʴ� ACK
                    tlp_data_ready_o <= 1'b1;
                    dllp_o           <= 32'b0;
                    dllp_valid_o     <= 1'b0;
                    Latency_Timer <= Latency_Timer + 1;

                end
                else if(Latency_Timer >= 3'b110) begin
                    // �����ϴ� ACK
                    tlp_data_ready_o <= 1'b1;
                    dllp_o           <= {8'b0, 12'b111111111111, Nrs - 1};
                    dllp_valid_o     <= 1'b1;
                    Latency_Timer    <= 3'b001;   // Timer �ʱ�ȭ
                end      
            end
        end
    end
endmodule
