module URP_PCIE_TX_DATA_LINK_LAYER
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
    input   logic                   tlp_data_ready_i,

    // DLLP Interface
    input   logic [31:0]            dllp_i,
    output  logic                   dllp_ready_o,
    input   logic                   dllp_valid_i
);

    // Internal Signals
    // Retry buffer Signals
    logic         wren_i;           // Retry buffer�� ���� ��ȣ 
    logic [267:0] wdata_i;          // Retry buffer�� ���� ������
    logic [267:0] rdata_o;          // Retry buffer���� �о���� data
    logic [267:0] prev_rdata;       // �� rdata_o (NAK ���� �� �� �����Ϳ� �ѹ��� valid ��ȣ�� �ֱ� ����)
    logic         first_nak;        // ù NAK�� �����ϴ� ��ȣ, 0�̸� ó��
    // LCRC Signals
    logic         TX_crc_valid_o;   // TX_crc�� valid ��ȣ
    logic [223:0] TX_crc_data_o;    // tlp_data_i �״�� 
    logic [31:0]  TX_crc_checksum;  // TX_crc_enc�� Data(CRC)    
    
    // DLLP Signals
    logic [11:0]  seq_num;          // TX_DLL���� �����ϴ� Sequence Number
    logic         Ack, Nak;         // TX_DLL���� �Ǵ��ϴ� Ack, Nak
    logic         timing;           // NAK rdata_o ��� Timing ���߱� ��    

    // Reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin      //�ʱ�ȭ
            tlp_data_ready_o   <= 1'b0;  
            tlp_data_o         <= 268'b0;
            tlp_data_valid_o   <= 1'b0;
            dllp_ready_o       <= 1'b0;

            wren_i             <= 1'b0;
            wdata_i            <= 268'b0;
            seq_num            <= 12'd1;
            prev_rdata         <= 268'b0;
            first_nak          <= 1'b0;  

            Ack                <= 1'b0;
            Nak                <= 1'b0;
            timing             <=  1'b0;
        end 
        else begin
            if (dllp_valid_i) begin
                // DLLP [31:24] = 0000 0000 ACK
                Ack <= (dllp_i[31:24] == 8'b0);
                // DLLP [31:24] = 0001 0000 NAK             
                Nak <= (dllp_i[31:24] == 8'b00010000); 
            end
            else begin            //�ʱ�ȭ
                Ack                <= 1'b0;      
                Nak                <= 1'b0;      
            end   
            
            // Case 1: NAK ����
            if (Nak) begin
            //ó�� NAK�� �񱳾��ϰ� rdata_o�� 1�̸� ����, �ȳ����� valid ��ȣ Error  
               if(!first_nak) begin    // valid ������ ��ȣ
                    wren_i             <= 1'b0;          
                    tlp_data_ready_o   <= 1'b0;     // TLP ���� ���� ����     
                    tlp_data_o         <= rdata_o;
                    if(rdata_o) begin       
                    tlp_data_valid_o   <= 1'b1;      
                    end   
                    dllp_ready_o       <= 1'b1;
                    prev_rdata         <= tlp_data_o;
                    first_nak          <= 1'b1;
                    timing             <= 0;
               end
               else if(first_nak) begin // valid �Ⱥ����� ��ȣ
                    tlp_data_valid_o   <= 1'b0;
                    if (prev_rdata == rdata_o) begin
                        wren_i             <= 1'b0;          
                        tlp_data_ready_o   <= 1'b0;  // TLP ���� ���� ����        
                        tlp_data_o         <= rdata_o;       
                        tlp_data_valid_o   <= 1'b0;         
                        dllp_ready_o       <= 1'b1;
                        timing             <= 0;
                    end
                    else begin           // valid ������ ��ȣ
                        wren_i             <= 1'b0;          
                        tlp_data_ready_o   <= 1'b0;   // TLP ���� ���� ����        
                        tlp_data_o         <= rdata_o;
                        if(timing == 1'b1) begin       
                        tlp_data_valid_o   <= 1'b1;      
                        end      
                        timing             <= timing + 1;    
                        dllp_ready_o       <= 1'b1;
                        prev_rdata         <= tlp_data_o;
                        end
                    end
            end
            if (TX_crc_valid_o) begin
                timing             <= 0;  //Timing �ʱ�ȭ, Timing����, NAK�� rdata_o �ӵ� ����
             // Case 2: ACK + �Ϲ� Tlp ���� (Latency Timer�� ���� ACK ������ ���� �ֱ⿡)
                if (!Nak && (Ack || tlp_data_ready_i)  &&  tlp_data_i != 1) begin
                     // Retry buffer
                    wren_i             <= 1'b1;          
                    wdata_i            <= {seq_num, TX_crc_data_o, TX_crc_checksum};
                    seq_num <= seq_num + 1'b1;
                    tlp_data_ready_o   <= 1'b1;          // TX
                    tlp_data_o         <= {seq_num, TX_crc_data_o, TX_crc_checksum};   
                    tlp_data_valid_o   <= 1'b1;          // valid 
                    dllp_ready_o       <= 1'b1;          // DLLP 
                    first_nak          <= 1'b0;
                 end
            end
            else begin
                if (!Nak) begin    //MAK��ȣ ������ �� �ʱ�ȭ
                tlp_data_o         <= 268'b0;        // Garbage 
                tlp_data_valid_o   <= 1'b0;          // valid 
                dllp_ready_o       <= 1'b1;          // DLLP 
                wren_i             <= 1'b0;          // Retry buffer
                first_nak          <= 1'b0;
                tlp_data_ready_o   <= 1'b1;          // ���� �ٽ� ����
                end
            end
        end
    end
    
    URP_PCIE_CRC32_ENC #(     // CRC Generator
        .DATA_WIDTH(224),
        .CRC_WIDTH(32)
    ) u_lcrc_gen (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(tlp_data_valid_i),
        .data_i(tlp_data_i),
        .valid_o(TX_crc_valid_o),
        .data_o(TX_crc_data_o),
        .checksum_o(TX_crc_checksum)
    );

    RETRY_BUFFER #(           // Retry_Buffer
         .DEPTH_LG2(4),   
        .DATA_WIDTH(268)
    
    )u_retry_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .wren_i(wren_i),
        .wdata_i(wdata_i),
        .delete_enable(dllp_valid_i),  // dllp_valid_i 
        .seq_to_delete(dllp_i[11:0]),    // AckNak_Seq 
        .rdata_o(rdata_o)            
    );
endmodule