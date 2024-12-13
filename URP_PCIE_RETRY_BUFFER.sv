module RETRY_BUFFER #(
    parameter DEPTH_LG2     = 4,   // FIFO의 깊이를 log2로 표현
    parameter DATA_WIDTH    = 268  // 데이터 폭 (TLP의 크기)
)
(
    input   logic                    clk,              // 클럭 신호
    input   logic                    rst_n,            // 비동기 리셋 (active low)

    // 입력 신호
    input   logic                    wren_i,           // 쓰기 활성 신호
    input   logic [DATA_WIDTH-1:0]   wdata_i,          // 입력 TLP 데이터
    input   logic                    delete_enable,    // 특정 Sequence 이하 삭제 신호
    input   logic [11:0]             seq_to_delete,    // 삭제할 Sequence 번호

    // 출력 신호
    output  logic [DATA_WIDTH-1:0]   rdata_o           // 출력 TLP 데이터
);

    localparam FIFO_DEPTH = (1 << DEPTH_LG2);         // FIFO 깊이 계산

    // FIFO 저장소
    logic [DATA_WIDTH-1:0] data[FIFO_DEPTH];          // TLP 데이터를 저장하는 메모리

    // 읽기 및 쓰기 포인터
    logic [DEPTH_LG2-1:0] wrptr, rdptr;              // 쓰기, 읽기 포인터

    // 유효 플래그
    logic [FIFO_DEPTH-1:0] valid;                    // 각 엔트리의 유효 여부를 나타내는 플래그
    logic  modulous;                                 // rdptr 올리는 속도 조절용
    logic first;
    
    // Sequential Logic (클럭 기반 동작)
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // 초기화
            wrptr <= 0;
            rdptr <= 0;
            valid <= 0;
            modulous <= 0;  
            first <= 0;             //처음 Rdptr 에서만 rdptr <= 0으로 되게
    end else begin
        // 삭제
        if (delete_enable) begin
            int i, j;
            j = 0;

            // valid 신호를 앞으로 이동
            for (i = 0; i < FIFO_DEPTH; i++) begin
                // Seq_to_delete 이하 삭제
                if (valid[i] && data[i][267:256] > seq_to_delete) begin 
                    if (i != j) begin
                        data[j] <= data[i];  // 데이터 이동
                        valid[j] <= valid[i];
                    end
                    j = j + 1;
                end
            end

            // 뒷 공간 초기화
            for (i = j; i < FIFO_DEPTH; i++) begin
                valid[i] <= 1'b0;
                data[i] <= {DATA_WIDTH{1'b0}};
            end

            // 포인터 조정
            wrptr <= j;  // 새 wrptr는 유효 데이터의 끝
            if(!first) begin
            rdptr <= 0;  // 읽기 포인터 초기화
            first <= first + 1;
            end
        end
        if (!delete_enable) begin
            first <= 0;
        end
        // 쓰기
        if (wren_i) begin
            data[wrptr] <= wdata_i;
            valid[wrptr] <= 1'b1;
            wrptr <= wrptr + 1;
        end

        // 읽기
        if (valid[rdptr]) begin
            if (!delete_enable) begin
            rdptr <= rdptr + 1;
            modulous <= 0;
            end
            // 두번마다 한 번씩 rdptr 올리게
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

    // 출력 논리 (자동으로 데이터를 읽어옴)
    assign rdata_o = (valid[rdptr]) ? data[rdptr] : {DATA_WIDTH{1'b0}};  // 유효한 데이터만 출력
    assign rdata_valid = valid[rdptr];  // 현재 읽기 포인터가 유효한 데이터를 가리킬 때 1
endmodule