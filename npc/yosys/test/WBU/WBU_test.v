// WBU_test.v
// 顶层测试模块，包含 ysyx_25080209_WBU，输入和输出均插入触发器
module WBU_test #(
    parameter DATA_WID = 32
)(
    input  wire clock,
    input  wire rst,

    // 所有输入信号（加 _in 后缀）
    input  wire [2:0]           IDU_wreg_sw_in,
    input  wire                 IDU_csr_w_sw_in,
    input  wire [DATA_WID-1:0]  IDU_imm_in,
    input  wire [DATA_WID-1:0]  EXU_out_in,
    input  wire [DATA_WID-1:0]  IFU_snpc_in,
    input  wire [DATA_WID-1:0]  LSU_rdata_in,
    input  wire                 LSU_reg_wen_in,
    input  wire                 LSU_csr_wen_in,
    input  wire                 LSU_csr_ren_in,
    input  wire [DATA_WID-1:0]  CSR_wreg_in,
    input  wire [DATA_WID-1:0]  CSR_wrs1_in,
    input  wire [DATA_WID-1:0]  CSR_wzimm_in,
    input  wire                 LSU_valid_in,

    // 采样后的输出（加 _sampled 后缀）
    output wire [DATA_WID-1:0]  WBU_reg_wdata_sampled,
    output wire [DATA_WID-1:0]  WBU_csr_wdata_sampled,
    output wire                 WBU_reg_wen_sampled,
    output wire                 WBU_csr_wen_sampled,
    output wire                 WBU_csr_ren_sampled,
    output wire                 WBU_ready_sampled
);

    // ---- 输入采样寄存器 ----
    reg [2:0]           IDU_wreg_sw;
    reg                 IDU_csr_w_sw;
    reg [DATA_WID-1:0]  IDU_imm;
    reg [DATA_WID-1:0]  EXU_out;
    reg [DATA_WID-1:0]  IFU_snpc;
    reg [DATA_WID-1:0]  LSU_rdata;
    reg                 LSU_reg_wen;
    reg                 LSU_csr_wen;
    reg                 LSU_csr_ren;
    reg [DATA_WID-1:0]  CSR_wreg;
    reg [DATA_WID-1:0]  CSR_wrs1;
    reg [DATA_WID-1:0]  CSR_wzimm;
    reg                 LSU_valid;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            IDU_wreg_sw  <= 0;
            IDU_csr_w_sw <= 0;
            IDU_imm      <= 0;
            EXU_out      <= 0;
            IFU_snpc     <= 0;
            LSU_rdata    <= 0;
            LSU_reg_wen  <= 0;
            LSU_csr_wen  <= 0;
            LSU_csr_ren  <= 0;
            CSR_wreg     <= 0;
            CSR_wrs1     <= 0;
            CSR_wzimm    <= 0;
            LSU_valid    <= 0;
        end else begin
            IDU_wreg_sw  <= IDU_wreg_sw_in;
            IDU_csr_w_sw <= IDU_csr_w_sw_in;
            IDU_imm      <= IDU_imm_in;
            EXU_out      <= EXU_out_in;
            IFU_snpc     <= IFU_snpc_in;
            LSU_rdata    <= LSU_rdata_in;
            LSU_reg_wen  <= LSU_reg_wen_in;
            LSU_csr_wen  <= LSU_csr_wen_in;
            LSU_csr_ren  <= LSU_csr_ren_in;
            CSR_wreg     <= CSR_wreg_in;
            CSR_wrs1     <= CSR_wrs1_in;
            CSR_wzimm    <= CSR_wzimm_in;
            LSU_valid    <= LSU_valid_in;
        end
    end

    // ---- 子模块实例化 ----
    wire [DATA_WID-1:0] WBU_reg_wdata;
    wire [DATA_WID-1:0] WBU_csr_wdata;
    wire                WBU_reg_wen;
    wire                WBU_csr_wen;
    wire                WBU_csr_ren;
    wire                WBU_ready;

    ysyx_25080209_WBU #(
        .DATA_WID(DATA_WID)
    ) u_WBU (
        .clk            (clock),
        .rst            (rst),
        .IDU_wreg_sw    (IDU_wreg_sw),
        .IDU_csr_w_sw   (IDU_csr_w_sw),
        .IDU_imm        (IDU_imm),
        .EXU_out        (EXU_out),
        .IFU_snpc       (IFU_snpc),
        .LSU_rdata      (LSU_rdata),
        .LSU_reg_wen    (LSU_reg_wen),
        .LSU_csr_wen    (LSU_csr_wen),
        .LSU_csr_ren    (LSU_csr_ren),
        .CSR_wreg       (CSR_wreg),
        .CSR_wrs1       (CSR_wrs1),
        .CSR_wzimm      (CSR_wzimm),
        .WBU_reg_wdata  (WBU_reg_wdata),
        .WBU_csr_wdata  (WBU_csr_wdata),
        .WBU_reg_wen    (WBU_reg_wen),
        .WBU_csr_wen    (WBU_csr_wen),
        .WBU_csr_ren    (WBU_csr_ren),
        .WBU_ready      (WBU_ready),
        .LSU_valid      (LSU_valid)
    );

    // ---- 输出采样寄存器 ----
    reg [DATA_WID-1:0] WBU_reg_wdata_reg;
    reg [DATA_WID-1:0] WBU_csr_wdata_reg;
    reg                WBU_reg_wen_reg;
    reg                WBU_csr_wen_reg;
    reg                WBU_csr_ren_reg;
    reg                WBU_ready_reg;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            WBU_reg_wdata_reg <= 0;
            WBU_csr_wdata_reg <= 0;
            WBU_reg_wen_reg   <= 0;
            WBU_csr_wen_reg   <= 0;
            WBU_csr_ren_reg   <= 0;
            WBU_ready_reg     <= 0;
        end else begin
            WBU_reg_wdata_reg <= WBU_reg_wdata;
            WBU_csr_wdata_reg <= WBU_csr_wdata;
            WBU_reg_wen_reg   <= WBU_reg_wen;
            WBU_csr_wen_reg   <= WBU_csr_wen;
            WBU_csr_ren_reg   <= WBU_csr_ren;
            WBU_ready_reg     <= WBU_ready;
        end
    end

    // ---- 采样输出赋值 ----
    assign WBU_reg_wdata_sampled = WBU_reg_wdata_reg;
    assign WBU_csr_wdata_sampled = WBU_csr_wdata_reg;
    assign WBU_reg_wen_sampled   = WBU_reg_wen_reg;
    assign WBU_csr_wen_sampled   = WBU_csr_wen_reg;
    assign WBU_csr_ren_sampled   = WBU_csr_ren_reg;
    assign WBU_ready_sampled     = WBU_ready_reg;

endmodule
