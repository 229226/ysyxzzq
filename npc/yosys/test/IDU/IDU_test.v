// IDU_test.v
// 顶层测试模块，包含 ysyx_25080209_IDU，输入和输出均插入触发器
module IDU_test #(
    parameter DATA_WID = 32,
    parameter RADDR_WID = 4
)(
    input  wire clock,
    input  wire rst,

    // 所有输入信号（加 _in 后缀）
    input  wire                 IFU_valid_in,
    input  wire [DATA_WID-1:0]  IFU_instr_in,
    input  wire                 EXU_ready_in,

    // 采样后的输出（加 _sampled 后缀）
    output wire                 IDU_ready_sampled,
    output wire                 IDU_valid_sampled,
    output wire                 IDU_ALU_op1_sampled,
    output wire                 IDU_ALU_op2_sampled,
    output wire [3:0]           IDU_ALU_opcode_sampled,
    output wire [DATA_WID-1:0]  IDU_imm_sampled,
    output wire [1:0]           IDU_pc_sw_sampled,
    output wire [RADDR_WID-1:0] IDU_reg_raddr1_sampled,
    output wire [RADDR_WID-1:0] IDU_reg_raddr2_sampled,
    output wire                 IDU_reg_wen_sampled,
    output wire [RADDR_WID-1:0] IDU_reg_waddr_sampled,
    output wire [2:0]           IDU_wreg_sw_sampled,
    output wire                 IDU_mem_ren_sampled,
    output wire                 IDU_mem_wen_sampled,
    output wire [3:0]           IDU_mem_wmask_sampled,
    output wire [2:0]           IDU_mem_rmask_sampled,
    output wire                 IDU_csr_wen_sampled,
    output wire                 IDU_csr_ren_sampled,
    output wire                 IDU_csr_w_sw_sampled,
    output wire [DATA_WID-1:0]  IDU_csr_zimm_sampled,
    output wire                 IDU_ecall_sampled,
    output wire                 IDU_mret_sampled
);

    // ---- 输入采样寄存器 ----
    reg                 IFU_valid;
    reg [DATA_WID-1:0]  IFU_instr;
    reg                 EXU_ready;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            IFU_valid <= 0;
            IFU_instr <= 0;
            EXU_ready <= 0;
        end else begin
            IFU_valid <= IFU_valid_in;
            IFU_instr <= IFU_instr_in;
            EXU_ready <= EXU_ready_in;
        end
    end

    // ---- 子模块实例化 ----
    wire                 IDU_ready;
    wire                 IDU_valid;
    wire                 IDU_ALU_op1;
    wire                 IDU_ALU_op2;
    wire [3:0]           IDU_ALU_opcode;
    wire [DATA_WID-1:0]  IDU_imm;
    wire [1:0]           IDU_pc_sw;
    wire [RADDR_WID-1:0] IDU_reg_raddr1;
    wire [RADDR_WID-1:0] IDU_reg_raddr2;
    wire                 IDU_reg_wen;
    wire [RADDR_WID-1:0] IDU_reg_waddr;
    wire [2:0]           IDU_wreg_sw;
    wire                 IDU_mem_ren;
    wire                 IDU_mem_wen;
    wire [3:0]           IDU_mem_wmask;
    wire [2:0]           IDU_mem_rmask;
    wire                 IDU_csr_wen;
    wire                 IDU_csr_ren;
    wire                 IDU_csr_w_sw;
    wire [DATA_WID-1:0]  IDU_csr_zimm;
    wire                 IDU_ecall;
    wire                 IDU_mret;

    ysyx_25080209_IDU #(
        .DATA_WID(DATA_WID),
        .RADDR_WID(RADDR_WID)
    ) u_IDU (
        .clk              (clock),
        .rst              (rst),
        .IFU_valid        (IFU_valid),
        .IDU_ready        (IDU_ready),
        .IFU_instr        (IFU_instr),
        .EXU_ready        (EXU_ready),
        .IDU_valid        (IDU_valid),
        .IDU_ALU_op1      (IDU_ALU_op1),
        .IDU_ALU_op2      (IDU_ALU_op2),
        .IDU_ALU_opcode   (IDU_ALU_opcode),
        .IDU_imm          (IDU_imm),
        .IDU_pc_sw        (IDU_pc_sw),
        .IDU_reg_raddr1   (IDU_reg_raddr1),
        .IDU_reg_raddr2   (IDU_reg_raddr2),
        .IDU_reg_wen      (IDU_reg_wen),
        .IDU_reg_waddr    (IDU_reg_waddr),
        .IDU_wreg_sw      (IDU_wreg_sw),
        .IDU_mem_ren      (IDU_mem_ren),
        .IDU_mem_wen      (IDU_mem_wen),
        .IDU_mem_wmask    (IDU_mem_wmask),
        .IDU_mem_rmask    (IDU_mem_rmask),
        .IDU_csr_wen      (IDU_csr_wen),
        .IDU_csr_ren      (IDU_csr_ren),
        .IDU_csr_w_sw     (IDU_csr_w_sw),
        .IDU_csr_zimm     (IDU_csr_zimm),
        .IDU_ecall        (IDU_ecall),
        .IDU_mret         (IDU_mret)
    );

    // ---- 输出采样寄存器 ----
    reg                 IDU_ready_reg;
    reg                 IDU_valid_reg;
    reg                 IDU_ALU_op1_reg;
    reg                 IDU_ALU_op2_reg;
    reg [3:0]           IDU_ALU_opcode_reg;
    reg [DATA_WID-1:0]  IDU_imm_reg;
    reg [1:0]           IDU_pc_sw_reg;
    reg [RADDR_WID-1:0] IDU_reg_raddr1_reg;
    reg [RADDR_WID-1:0] IDU_reg_raddr2_reg;
    reg                 IDU_reg_wen_reg;
    reg [RADDR_WID-1:0] IDU_reg_waddr_reg;
    reg [2:0]           IDU_wreg_sw_reg;
    reg                 IDU_mem_ren_reg;
    reg                 IDU_mem_wen_reg;
    reg [3:0]           IDU_mem_wmask_reg;
    reg [2:0]           IDU_mem_rmask_reg;
    reg                 IDU_csr_wen_reg;
    reg                 IDU_csr_ren_reg;
    reg                 IDU_csr_w_sw_reg;
    reg [DATA_WID-1:0]  IDU_csr_zimm_reg;
    reg                 IDU_ecall_reg;
    reg                 IDU_mret_reg;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            IDU_ready_reg      <= 0;
            IDU_valid_reg      <= 0;
            IDU_ALU_op1_reg    <= 0;
            IDU_ALU_op2_reg    <= 0;
            IDU_ALU_opcode_reg <= 0;
            IDU_imm_reg        <= 0;
            IDU_pc_sw_reg      <= 0;
            IDU_reg_raddr1_reg <= 0;
            IDU_reg_raddr2_reg <= 0;
            IDU_reg_wen_reg    <= 0;
            IDU_reg_waddr_reg  <= 0;
            IDU_wreg_sw_reg    <= 0;
            IDU_mem_ren_reg    <= 0;
            IDU_mem_wen_reg    <= 0;
            IDU_mem_wmask_reg  <= 0;
            IDU_mem_rmask_reg  <= 0;
            IDU_csr_wen_reg    <= 0;
            IDU_csr_ren_reg    <= 0;
            IDU_csr_w_sw_reg   <= 0;
            IDU_csr_zimm_reg   <= 0;
            IDU_ecall_reg      <= 0;
            IDU_mret_reg       <= 0;
        end else begin
            IDU_ready_reg      <= IDU_ready;
            IDU_valid_reg      <= IDU_valid;
            IDU_ALU_op1_reg    <= IDU_ALU_op1;
            IDU_ALU_op2_reg    <= IDU_ALU_op2;
            IDU_ALU_opcode_reg <= IDU_ALU_opcode;
            IDU_imm_reg        <= IDU_imm;
            IDU_pc_sw_reg      <= IDU_pc_sw;
            IDU_reg_raddr1_reg <= IDU_reg_raddr1;
            IDU_reg_raddr2_reg <= IDU_reg_raddr2;
            IDU_reg_wen_reg    <= IDU_reg_wen;
            IDU_reg_waddr_reg  <= IDU_reg_waddr;
            IDU_wreg_sw_reg    <= IDU_wreg_sw;
            IDU_mem_ren_reg    <= IDU_mem_ren;
            IDU_mem_wen_reg    <= IDU_mem_wen;
            IDU_mem_wmask_reg  <= IDU_mem_wmask;
            IDU_mem_rmask_reg  <= IDU_mem_rmask;
            IDU_csr_wen_reg    <= IDU_csr_wen;
            IDU_csr_ren_reg    <= IDU_csr_ren;
            IDU_csr_w_sw_reg   <= IDU_csr_w_sw;
            IDU_csr_zimm_reg   <= IDU_csr_zimm;
            IDU_ecall_reg      <= IDU_ecall;
            IDU_mret_reg       <= IDU_mret;
        end
    end

    // ---- 采样输出赋值 ----
    assign IDU_ready_sampled      = IDU_ready_reg;
    assign IDU_valid_sampled      = IDU_valid_reg;
    assign IDU_ALU_op1_sampled    = IDU_ALU_op1_reg;
    assign IDU_ALU_op2_sampled    = IDU_ALU_op2_reg;
    assign IDU_ALU_opcode_sampled = IDU_ALU_opcode_reg;
    assign IDU_imm_sampled        = IDU_imm_reg;
    assign IDU_pc_sw_sampled      = IDU_pc_sw_reg;
    assign IDU_reg_raddr1_sampled = IDU_reg_raddr1_reg;
    assign IDU_reg_raddr2_sampled = IDU_reg_raddr2_reg;
    assign IDU_reg_wen_sampled    = IDU_reg_wen_reg;
    assign IDU_reg_waddr_sampled  = IDU_reg_waddr_reg;
    assign IDU_wreg_sw_sampled    = IDU_wreg_sw_reg;
    assign IDU_mem_ren_sampled    = IDU_mem_ren_reg;
    assign IDU_mem_wen_sampled    = IDU_mem_wen_reg;
    assign IDU_mem_wmask_sampled  = IDU_mem_wmask_reg;
    assign IDU_mem_rmask_sampled  = IDU_mem_rmask_reg;
    assign IDU_csr_wen_sampled    = IDU_csr_wen_reg;
    assign IDU_csr_ren_sampled    = IDU_csr_ren_reg;
    assign IDU_csr_w_sw_sampled   = IDU_csr_w_sw_reg;
    assign IDU_csr_zimm_sampled   = IDU_csr_zimm_reg;
    assign IDU_ecall_sampled      = IDU_ecall_reg;
    assign IDU_mret_sampled       = IDU_mret_reg;

endmodule
