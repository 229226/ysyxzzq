// ALU_test.v
// 顶层测试模块，包含 ysyx_25080209_ALU，输入和输出均插入触发器
module ALU_test #(
    parameter DATA_WID = 32
)(
    input  wire clock,
    input  wire rst,

    // 所有输入信号（加 _in 后缀）
    input  wire [DATA_WID-1:0]  rs1_in,
    input  wire [DATA_WID-1:0]  rs2_in,
    input  wire [13:0]          alu_op_in,

    // 采样后的输出（加 _sampled 后缀）
    output wire [DATA_WID-1:0]  alu_out_sampled
);

    // ---- 输入采样寄存器 ----
    reg [DATA_WID-1:0]  rs1;
    reg [DATA_WID-1:0]  rs2;
    reg [13:0]          alu_op;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            rs1    <= 0;
            rs2    <= 0;
            alu_op <= 0;
        end else begin
            rs1    <= rs1_in;
            rs2    <= rs2_in;
            alu_op <= alu_op_in;
        end
    end

    // ---- 子模块实例化 ----
    wire [DATA_WID-1:0] alu_out;

    ysyx_25080209_ALU #(
        .DATA_WID(DATA_WID)
    ) u_ALU (
        .rs1     (rs1),
        .rs2     (rs2),
        .alu_op  (alu_op),
        .alu_out (alu_out)
    );

    // ---- 输出采样寄存器 ----
    reg [DATA_WID-1:0] alu_out_reg;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            alu_out_reg <= 0;
        end else begin
            alu_out_reg <= alu_out;
        end
    end

    // ---- 采样输出赋值 ----
    assign alu_out_sampled = alu_out_reg;

endmodule
