// EXU_test.v
// 顶层测试模块，包含 ysyx_25080209_EXU，输入和输出均插入触发器
module EXU_test #(DATA_WID = 32)(
    input  wire        clock,
    input  wire        rst,            // 复位信号
    // 所有输入信号（加 _in 后缀以区分）
    input  wire        IDU_valid_in,
    input  wire [DATA_WID-1:0] IDU_alu_in1_in,
    input  wire [DATA_WID-1:0] IDU_alu_in2_in,
    input  wire [13:0] IDU_ALU_opcode_in,
    input  wire        IDU_reg_wen_in,
    input  wire        IDU_csr_wen_in,
    input  wire        IDU_csr_ren_in,
    input  wire        LSU_ready_in,
    // 采样后的输出
    output wire [DATA_WID-1:0] EXU_out_sampled,
    output wire        EXU_reg_wen_sampled,
    output wire        EXU_csr_wen_sampled,
    output wire        EXU_csr_ren_sampled,
    output wire        EXU_ready_sampled,
    output wire        EXU_valid_sampled
);

    // ---- 输入采样寄存器 ----
    reg        IDU_valid;
    reg [DATA_WID-1:0] IDU_alu_in1, IDU_alu_in2;
    reg [13:0] IDU_ALU_opcode;
    reg        IDU_reg_wen, IDU_csr_wen, IDU_csr_ren;
    reg        LSU_ready;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            IDU_valid      <= 0;
            IDU_alu_in1    <= 0;
            IDU_alu_in2    <= 0;
            IDU_ALU_opcode <= 0;
            IDU_reg_wen    <= 0;
            IDU_csr_wen    <= 0;
            IDU_csr_ren    <= 0;
            LSU_ready      <= 0;
        end else begin
            IDU_valid      <= IDU_valid_in;
            IDU_alu_in1    <= IDU_alu_in1_in;
            IDU_alu_in2    <= IDU_alu_in2_in;
            IDU_ALU_opcode <= IDU_ALU_opcode_in;
            IDU_reg_wen    <= IDU_reg_wen_in;
            IDU_csr_wen    <= IDU_csr_wen_in;
            IDU_csr_ren    <= IDU_csr_ren_in;
            LSU_ready      <= LSU_ready_in;
        end
    end

    // ---- 子模块实例化 ----
    wire [DATA_WID-1:0] EXU_out;
    wire EXU_reg_wen, EXU_csr_wen, EXU_csr_ren, EXU_ready, EXU_valid;

    ysyx_25080209_EXU #(.DATA_WID(DATA_WID)) u_EXU (
        .clk        (clock),
        .rst        (rst),            // 子模块内部也有复位，但通常只复位状态，此处保持一致
        .IDU_valid  (IDU_valid),
        .IDU_alu_in1(IDU_alu_in1),
        .IDU_alu_in2(IDU_alu_in2),
        .IDU_ALU_opcode(IDU_ALU_opcode),
        .IDU_reg_wen(IDU_reg_wen),
        .IDU_csr_wen(IDU_csr_wen),
        .IDU_csr_ren(IDU_csr_ren),
        .LSU_ready  (LSU_ready),
        .EXU_out    (EXU_out),
        .EXU_reg_wen(EXU_reg_wen),
        .EXU_csr_wen(EXU_csr_wen),
        .EXU_csr_ren(EXU_csr_ren),
        .EXU_ready  (EXU_ready),
        .EXU_valid  (EXU_valid)
    );

    // ---- 输出采样寄存器 ----
    reg [DATA_WID-1:0] EXU_out_reg;
    reg EXU_reg_wen_reg, EXU_csr_wen_reg, EXU_csr_ren_reg, EXU_ready_reg, EXU_valid_reg;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            EXU_out_reg     <= 0;
            EXU_reg_wen_reg <= 0;
            EXU_csr_wen_reg <= 0;
            EXU_csr_ren_reg <= 0;
            EXU_ready_reg   <= 0;
            EXU_valid_reg   <= 0;
        end else begin
            EXU_out_reg     <= EXU_out;
            EXU_reg_wen_reg <= EXU_reg_wen;
            EXU_csr_wen_reg <= EXU_csr_wen;
            EXU_csr_ren_reg <= EXU_csr_ren;
            EXU_ready_reg   <= EXU_ready;
            EXU_valid_reg   <= EXU_valid;
        end
    end

    assign EXU_out_sampled       = EXU_out_reg;
    assign EXU_reg_wen_sampled   = EXU_reg_wen_reg;
    assign EXU_csr_wen_sampled   = EXU_csr_wen_reg;
    assign EXU_csr_ren_sampled   = EXU_csr_ren_reg;
    assign EXU_ready_sampled     = EXU_ready_reg;
    assign EXU_valid_sampled     = EXU_valid_reg;

endmodule