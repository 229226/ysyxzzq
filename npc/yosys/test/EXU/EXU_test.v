// EXU_test.v
// 顶层测试模块，包含 ysyx_25080209_EXU，输入和输出均插入触发器
module EXU_test #(DATA_WID = 32)(
    input  wire        clock,
    input  wire        rst,            // 复位信号
    // 所有输入信号（加 _in 后缀以区分）
    input  wire        IDU_valid_in,
    input  wire [DATA_WID-1:0] IDU_rs1_in,
    input  wire [DATA_WID-1:0] IDU_rs2_in,
    input  wire [DATA_WID-1:0] IDU_imm_in,
    input  wire        IDU_ALU_op1_in,
    input  wire        IDU_ALU_op2_in,
    input  wire [3:0]  IDU_ALU_opcode_in,
    input  wire [1:0]  IDU_pc_sw_in,
    input  wire        IDU_ecall_in,
    input  wire        IDU_mret_in,
    input  wire        IDU_reg_wen_in,
    input  wire        IDU_csr_wen_in,
    input  wire        IDU_csr_ren_in,
    input  wire [DATA_WID-1:0] IFU_pc_in,
    input  wire [DATA_WID-1:0] IFU_snpc_in,
    input  wire [DATA_WID-1:0] CSR_mtvec_in,
    input  wire [DATA_WID-1:0] CSR_mepc_in,
    input  wire        LSU_ready_in,
    // 采样后的输出
    output wire [DATA_WID-1:0] EXU_out_sampled,
    output wire [DATA_WID-1:0] EXU_pc_next_sampled,
    output wire        EXU_reg_wen_sampled,
    output wire        EXU_csr_wen_sampled,
    output wire        EXU_csr_ren_sampled,
    output wire        EXU_ready_sampled,
    output wire        EXU_valid_sampled
);

    // ---- 输入采样寄存器 ----
    reg        IDU_valid;
    reg [DATA_WID-1:0] IDU_rs1, IDU_rs2, IDU_imm;
    reg        IDU_ALU_op1, IDU_ALU_op2;
    reg [3:0]  IDU_ALU_opcode;
    reg [1:0]  IDU_pc_sw;
    reg        IDU_ecall, IDU_mret;
    reg        IDU_reg_wen, IDU_csr_wen, IDU_csr_ren;
    reg [DATA_WID-1:0] IFU_pc, IFU_snpc;
    reg [DATA_WID-1:0] CSR_mtvec, CSR_mepc;
    reg        LSU_ready;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            IDU_valid      <= 0;
            IDU_rs1        <= 0;
            IDU_rs2        <= 0;
            IDU_imm        <= 0;
            IDU_ALU_op1    <= 0;
            IDU_ALU_op2    <= 0;
            IDU_ALU_opcode <= 0;
            IDU_pc_sw      <= 0;
            IDU_ecall      <= 0;
            IDU_mret       <= 0;
            IDU_reg_wen    <= 0;
            IDU_csr_wen    <= 0;
            IDU_csr_ren    <= 0;
            IFU_pc         <= 0;
            IFU_snpc       <= 0;
            CSR_mtvec      <= 0;
            CSR_mepc       <= 0;
            LSU_ready      <= 0;
        end else begin
            IDU_valid      <= IDU_valid_in;
            IDU_rs1        <= IDU_rs1_in;
            IDU_rs2        <= IDU_rs2_in;
            IDU_imm        <= IDU_imm_in;
            IDU_ALU_op1    <= IDU_ALU_op1_in;
            IDU_ALU_op2    <= IDU_ALU_op2_in;
            IDU_ALU_opcode <= IDU_ALU_opcode_in;
            IDU_pc_sw      <= IDU_pc_sw_in;
            IDU_ecall      <= IDU_ecall_in;
            IDU_mret       <= IDU_mret_in;
            IDU_reg_wen    <= IDU_reg_wen_in;
            IDU_csr_wen    <= IDU_csr_wen_in;
            IDU_csr_ren    <= IDU_csr_ren_in;
            IFU_pc         <= IFU_pc_in;
            IFU_snpc       <= IFU_snpc_in;
            CSR_mtvec      <= CSR_mtvec_in;
            CSR_mepc       <= CSR_mepc_in;
            LSU_ready      <= LSU_ready_in;
        end
    end

    // ---- 子模块实例化 ----
    wire [DATA_WID-1:0] EXU_out, EXU_pc_next;
    wire EXU_reg_wen, EXU_csr_wen, EXU_csr_ren, EXU_ready, EXU_valid;

    ysyx_25080209_EXU #(.DATA_WID(DATA_WID)) u_EXU (
        .clk        (clock),
        .rst        (rst),            // 子模块内部也有复位，但通常只复位状态，此处保持一致
        .IDU_valid  (IDU_valid),
        .IDU_rs1    (IDU_rs1),
        .IDU_rs2    (IDU_rs2),
        .IDU_imm    (IDU_imm),
        .IDU_ALU_op1(IDU_ALU_op1),
        .IDU_ALU_op2(IDU_ALU_op2),
        .IDU_ALU_opcode(IDU_ALU_opcode),
        .IDU_pc_sw  (IDU_pc_sw),
        .IDU_ecall  (IDU_ecall),
        .IDU_mret   (IDU_mret),
        .IDU_reg_wen(IDU_reg_wen),
        .IDU_csr_wen(IDU_csr_wen),
        .IDU_csr_ren(IDU_csr_ren),
        .IFU_pc     (IFU_pc),
        .IFU_snpc   (IFU_snpc),
        .CSR_mtvec  (CSR_mtvec),
        .CSR_mepc   (CSR_mepc),
        .LSU_ready  (LSU_ready),
        .EXU_out    (EXU_out),
        .EXU_pc_next(EXU_pc_next),
        .EXU_reg_wen(EXU_reg_wen),
        .EXU_csr_wen(EXU_csr_wen),
        .EXU_csr_ren(EXU_csr_ren),
        .EXU_ready  (EXU_ready),
        .EXU_valid  (EXU_valid)
    );

    // ---- 输出采样寄存器 ----
    reg [DATA_WID-1:0] EXU_out_reg, EXU_pc_next_reg;
    reg EXU_reg_wen_reg, EXU_csr_wen_reg, EXU_csr_ren_reg, EXU_ready_reg, EXU_valid_reg;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            EXU_out_reg     <= 0;
            EXU_pc_next_reg <= 0;
            EXU_reg_wen_reg <= 0;
            EXU_csr_wen_reg <= 0;
            EXU_csr_ren_reg <= 0;
            EXU_ready_reg   <= 0;
            EXU_valid_reg   <= 0;
        end else begin
            EXU_out_reg     <= EXU_out;
            EXU_pc_next_reg <= EXU_pc_next;
            EXU_reg_wen_reg <= EXU_reg_wen;
            EXU_csr_wen_reg <= EXU_csr_wen;
            EXU_csr_ren_reg <= EXU_csr_ren;
            EXU_ready_reg   <= EXU_ready;
            EXU_valid_reg   <= EXU_valid;
        end
    end

    assign EXU_out_sampled       = EXU_out_reg;
    assign EXU_pc_next_sampled   = EXU_pc_next_reg;
    assign EXU_reg_wen_sampled   = EXU_reg_wen_reg;
    assign EXU_csr_wen_sampled   = EXU_csr_wen_reg;
    assign EXU_csr_ren_sampled   = EXU_csr_ren_reg;
    assign EXU_ready_sampled     = EXU_ready_reg;
    assign EXU_valid_sampled     = EXU_valid_reg;

endmodule