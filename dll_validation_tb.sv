`timescale 1ns/1ps

module dll_validation_tb;

    // Testbench 신호 선언
    logic clk, rst_n;
    logic [223:0] tx_tlp_data_i;
    logic tx_tlp_data_valid_i;
    logic tx_tlp_data_ready_o;
    logic [267:0] tx_tlp_data_o;
    logic tx_tlp_data_valid_o;
    logic tx_dllp_ready_o;

    logic [267:0] rx_tlp_data_i;
    logic rx_tlp_data_valid_i;
    logic [31:0] rx_dllp_o;
    logic rx_dllp_valid_o;
    logic [223:0] rx_tlp_data_o;
    logic rx_tlp_data_valid_o;
    

    // TX 데이터 링크 레이어 인스턴스화
    URP_PCIE_TX_DATA_LINK_LAYER u_dll_layer (
        .clk(clk),
        .rst_n(rst_n),
        .tlp_data_i(tx_tlp_data_i),
        .tlp_data_valid_i(tx_tlp_data_valid_i),
        .tlp_data_ready_o(tx_tlp_data_ready_o),
        .tlp_data_o(tx_tlp_data_o),
        .tlp_data_valid_o(tx_tlp_data_valid_o),
        .tlp_data_ready_i(rx_tlp_data_ready_o),
        .dllp_i(rx_dllp_o),
        .dllp_ready_o(tx_dllp_ready_o),
        .dllp_valid_i(rx_dllp_valid_o)
    ); 

    // RX 데이터 링크 레이어 인스턴스화
    URP_PCIE_RX_DATA_LINK_LAYER rx_dll (
        .clk(clk),
        .rst_n(rst_n),
        .tlp_data_i(rx_tlp_data_i),
        .tlp_data_valid_i(rx_tlp_data_valid_i),
        .tlp_data_ready_o(rx_tlp_data_ready_o),
        .dllp_o(rx_dllp_o),
        .dllp_valid_o(rx_dllp_valid_o),
        .dllp_ready_i(tx_dllp_ready_o),
        .tlp_data_o(rx_tlp_data_o),
        .tlp_data_valid_o(rx_tlp_data_valid_o),
        .tlp_data_ready_i(1'b1)
    );

    // Clock 생성
    always #5 clk = ~clk;

    // 초기화
    initial begin
        clk = 0;
        rst_n = 0;
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 1'b0;
        rx_tlp_data_i = 268'b0;
        #10 rst_n = 1; // Reset 해제
    end
    // TX에서 RX로 데이터 전달
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_tlp_data_i <= 268'b0;       // 초기화
            rx_tlp_data_valid_i <= 1'b0;   // 초기화

        end 
        else begin
            // TX valid가 활성화된 경우 RX로 전달
            if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
                rx_tlp_data_valid_i <= tx_tlp_data_valid_o;
            end else begin
                // TX valid가 비활성화된 경우 RX valid도 비활성화
                rx_tlp_data_valid_i <= 1'b0;
            end
        end
    end



    // Test Sequence
    initial begin
        tx_tlp_data_valid_i = 1;
        #10;
        tx_tlp_data_i = 224'hAAAA_BBBB_CCCC_DDDD_EEEE_FFFF_1234_5678;
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
        

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hEEEE_1234_5678_9999_AAAA_BBBB_CCCC_DDDD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;


        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'h1234_5678_ABCD_EF12_DEAD_BEEF_FACE_B00C;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hFEED_FACE_DEAF_CAFE_BABE_BEEF_ABCD_5678;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        
        #10
        tx_tlp_data_valid_i = 0;


        // Case 5: NAK & Retransmission
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hDEAD_CAFE_BABE_FACE_BEEF_FADE_ABCD_1234;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = {12'd10, tx_tlp_data_o[256:0]};
        end
        #10
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCAFE_DEAD_BEEF_FADE_1234_ABCD_EF12_B00C;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hC0DE_FA11_DEAD_BEEF_1234_5678_ABCD_EFAB;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCAFE_DEAD_BEEF_FADE_1234_ABCD_EF12_B00C;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
 
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCAFE_DEAD_BEEF_FADE_1234_ABCD_EF12_B00C;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCAFE_DEAD_BEEF_FADE_1234_ABCD_EF12_B00C;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hC0DE_FA11_DEAD_BEEF_1234_5678_ABCD_EFAB;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hE0DE_FA11_DEAD_BEEF_1234_5678_ABCD_EFAB;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
   
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCAD_C0DE_FACE_B00C_CAFE_5678_DEAD_ABCD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10 
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hBAD_C0DE_FACE_B00C_CAFE_5678_DEAD_ABCD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10 
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hAAD_C0DE_FACE_B00C_CAFE_5678_DEAD_ABCD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10 
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCAD_C0DE_FACE_B00C_CAFE_5678_DEAD_ABCD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10 
        tx_tlp_data_valid_i = 0;
 
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hBADE_C0DE_FACE_B00C_CAFE_5678_DEAD_ABCD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10 
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hBADE_C0DE_FACE_B00C_CAFE_5678_DEAD_ABCD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10 
        tx_tlp_data_valid_i = 0;

        //  LCRC 불일치 
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hC0DE_FA11_DEAD_BEEF_1234_5678_ABCD_EFAB;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = {tx_tlp_data_o[267:32], 32'd5};
        end
        #10
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'h1234_BEEF_5678_ABCD_DEAF_CAFE_FADE_FACE;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
       
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCAFE_BABE_C0FF_EE00_FA11_ABCD_DEAF_BEEF;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hDCFD_CAFE_BABE_FACE_BEEF_FADE_ABCD_1234;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hDCCD_CAFE_BABE_FACE_BEEF_FADE_ABCD_1234;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hDEAD_CAFE_BABE_FACE_BEEF_FADE_ABCD_1234;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hBEEF_1234_CAFE_FADE_FACE_BABE_5678_ABCD;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;

        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hFACE_BABE_FADE_DEAD_C0DE_BEEF_ABCD_5678;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;
              
              
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hCCCC_BABE_5678_DEAD_1234_BEEF_4321_5321;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;      

        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hFACE_BEBE_5678_DEAD_1234_BEEF_1234_CCCC;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;   
        
        #10;
        if(tx_tlp_data_ready_o) begin
        tx_tlp_data_i = 224'hEEEE_BA124_5678_DEAD_1234_FFFF_ABCD_5238;
        tx_tlp_data_valid_i = 1;
        end
        else begin
        tx_tlp_data_i = 224'b0;
        tx_tlp_data_valid_i = 0;
        end
        if (tx_tlp_data_valid_o  && rx_tlp_data_ready_o) begin
        rx_tlp_data_i = tx_tlp_data_o;
        end
        #10
        tx_tlp_data_valid_i = 0;   
        // 시뮬레이션 종료
        #50;
        $stop;
    end
endmodule
