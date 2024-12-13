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
    logic         wren_i;           // Retry buffer의 쓰기 신호 
    logic [267:0] wdata_i;          // Retry buffer의 쓰는 데이터
    logic [267:0] rdata_o;          // Retry buffer에서 읽어오는 data
    logic [267:0] prev_rdata;       // 전 rdata_o (NAK 과정 중 한 데이터에 한번의 valid 신호를 주기 위함)
    logic         first_nak;        // 첫 NAK을 감지하는 신호, 0이면 처음
    // LCRC Signals
    logic         TX_crc_valid_o;   // TX_crc의 valid 신호
    logic [223:0] TX_crc_data_o;    // tlp_data_i 그대로 
    logic [31:0]  TX_crc_checksum;  // TX_crc_enc의 Data(CRC)    
    
    // DLLP Signals
    logic [11:0]  seq_num;          // TX_DLL에서 생성하는 Sequence Number
    logic         Ack, Nak;         // TX_DLL에서 판단하는 Ack, Nak
    logic         timing;           // NAK rdata_o 사용 Timing 맞추기 용    

    // Reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin      //초기화
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
            else begin            //초기화
                Ack                <= 1'b0;      
                Nak                <= 1'b0;      
            end   
            
            // Case 1: NAK 수신
            if (Nak) begin
            //처음 NAK은 비교안하고 rdata_o가 1이면 켜짐, 안넣을시 valid 신호 Error  
               if(!first_nak) begin    // valid 보내는 신호
                    wren_i             <= 1'b0;          
                    tlp_data_ready_o   <= 1'b0;     // TLP 값을 받지 않음     
                    tlp_data_o         <= rdata_o;
                    if(rdata_o) begin       
                    tlp_data_valid_o   <= 1'b1;      
                    end   
                    dllp_ready_o       <= 1'b1;
                    prev_rdata         <= tlp_data_o;
                    first_nak          <= 1'b1;
                    timing             <= 0;
               end
               else if(first_nak) begin // valid 안보내는 신호
                    tlp_data_valid_o   <= 1'b0;
                    if (prev_rdata == rdata_o) begin
                        wren_i             <= 1'b0;          
                        tlp_data_ready_o   <= 1'b0;  // TLP 값을 받지 않음        
                        tlp_data_o         <= rdata_o;       
                        tlp_data_valid_o   <= 1'b0;         
                        dllp_ready_o       <= 1'b1;
                        timing             <= 0;
                    end
                    else begin           // valid 보내는 신호
                        wren_i             <= 1'b0;          
                        tlp_data_ready_o   <= 1'b0;   // TLP 값을 받지 않음        
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
                timing             <= 0;  //Timing 초기화, Timing으로, NAK시 rdata_o 속도 조절
             // Case 2: ACK + 일반 Tlp 전송 (Latency Timer로 인해 ACK 못받을 수도 있기에)
                if (!Nak && (Ack || tlp_data_ready_i)) begin // Nak일시 ready 신호 꺼주기에
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
                if (!Nak) begin    //MAK신호 끝나면 다 초기화
                tlp_data_o         <= 268'b0;        // Garbage 
                tlp_data_valid_o   <= 1'b0;          // valid 
                dllp_ready_o       <= 1'b1;          // DLLP 
                wren_i             <= 1'b0;          // Retry buffer
                first_nak          <= 1'b0;
                tlp_data_ready_o   <= 1'b1;          // 값을 다시 받음
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
