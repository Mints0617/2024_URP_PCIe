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

    // LCRC 신호
    logic RX_crc_valid_o;       
    logic [223:0] RX_crc_data_o;
    logic [31:0] RX_crc_checksum;
    
    
    // 내부 신호
    logic [11:0] Nrs;                  // RX_dll 내부의 sequence 값
    logic [2:0]  Latency_Timer;        // Ack Timer 용 변수
    logic        RX_Ack, RX_Nak;
    logic        Buff_valid;           //CRC Genderator의 valid용 buffer
    logic [267:256]  buff_seq;         //Tlp로 들어온 Data의 Seq 저장     
    logic [31:0]     buff_crc;         //Tlp로 들어온 Data의 lcrc 저장  
    logic [255:32]   buff_tlp_o;       //Tlp로 들어온 Data의 Header & Data 저장 
   
    // LCRC Check & Sequence Number Check
    URP_PCIE_CRC32_ENC #(
        .DATA_WIDTH(224),
        .CRC_WIDTH(32)
    ) u_lcrc_gen (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(tlp_data_valid_i),     // 값 수신하면 되는지
        .data_i(tlp_data_i[255:32]),    // TLP DATA의 [255:32]인 Header + Data로 CRC 계산
        .valid_o(RX_crc_valid_o),       // 다음 로직에 valid 값 전달
        .data_o(RX_crc_data_o),         // 그냥 거쳐서 나온 값
        .checksum_o(RX_crc_checksum)    // RX 모듈에서 체크용으로 만든 값
    );

    // Always block for logic and FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 초기화
            tlp_data_ready_o <= 1'b1;   //이렇게 해야 시작할 때 받을 수 있음
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
            RX_Ack           <= 1'b0;  // 초기화
            dllp_valid_o     <= 1'b0;
            dllp_o           <= 32'b0;
            tlp_data_valid_o <= 1'b0;
            Buff_valid <= RX_crc_valid_o;          //CRC Genderator의 valid용 buffer
            buff_seq <= tlp_data_i[267:256];       //Tlp로 들어온 Data의 Seq 저장 
            buff_crc <= tlp_data_i[31:0];          //Tlp로 들어온 Data의 lcrc 저장 
            if(tlp_data_valid_i) begin
                buff_tlp_o <=  tlp_data_i[255:32]; //Tlp로 들어온 Data의 Header & Data 저장                
            end

            if (RX_crc_valid_o) begin
                // LCRC 비교 및 Sequence Number 비교
                if (buff_crc == RX_crc_checksum) begin
                    // LCRC가 일치하는 경우, NRS와 Sequence Number 비교
                    if (buff_seq > Nrs) begin
                        RX_Nak   <= 1'b1;  // NACK 전송
                        RX_Ack   <= 1'b0;
                    end else begin
                        Nrs <= Nrs + 1;   // 시퀀스 번호 업데이트
                        RX_Ack <= 1'b1;  // ACK 전송 준비
                        RX_Nak <= 1'b0;
                    end
                end else begin
                    RX_Nak <= 1'b1;      // LCRC 불일치
                    RX_Ack <= 1'b0;
                end
            end
            
            if (RX_Nak) begin
                // NACK 전송
                dllp_o <= {20'b00010000111111111111, Nrs - 12'b1};  
                dllp_valid_o     <= 1'b1;
                tlp_data_o       <= 223'b0;  // NACK 시 데이터 전송 안 함
                tlp_data_valid_o <= 1'b0;    // NACK 시 데이터 전송 안 함
                tlp_data_ready_o <= 1'b1;    // 재전송 가능 위해
                Latency_Timer    <= 3'b001;    // Timer 초기화
            end
            
            if (RX_Ack) begin
                // ACK 처리
                if(tlp_data_ready_i) begin
                    tlp_data_o       <= buff_tlp_o;      // header와 data 분리
                    tlp_data_valid_o <= Buff_valid;   
                end        

                if (Latency_Timer < 3'b110) begin
                    // 전송하지 않는 ACK
                    tlp_data_ready_o <= 1'b1;
                    dllp_o           <= 32'b0;
                    dllp_valid_o     <= 1'b0;
                    Latency_Timer <= Latency_Timer + 1;

                end
                else if(Latency_Timer >= 3'b110) begin
                    // 전송하는 ACK
                    tlp_data_ready_o <= 1'b1;
                    dllp_o           <= {8'b0, 12'b111111111111, Nrs - 1};
                    dllp_valid_o     <= 1'b1;
                    Latency_Timer    <= 3'b001;   // Timer 초기화
                end      
            end
        end
    end
endmodule
