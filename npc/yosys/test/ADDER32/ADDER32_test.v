module ADDER32_test (
    input  wire        clock,
    input  wire        rst_n,
    input  wire [31:0] A,
    input  wire [31:0] B,
    output reg  [31:0] S,
    output reg         Cout
);

    // 输入寄存器
    reg [31:0] A_reg;
    reg [31:0] B_reg;

    // 组合加法结果（内部连线）
    wire [31:0] sum_w;
    wire        cout_w;

    // 组合逻辑加法器
    assign {cout_w, sum_w} = A_reg + B_reg;

    // 时序逻辑：输入采样 + 输出寄存
    always @(posedge clock or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 32'b0;
            B_reg <= 32'b0;
            S     <= 32'b0;
            Cout  <= 1'b0;
        end else begin
            // 输入寄存器采样
            A_reg <= A;
            B_reg <= B;
            // 输出寄存器锁存组合结果（使用A_reg/B_reg的旧值，即上一周期输入）
            S     <= sum_w;
            Cout  <= cout_w;
        end
    end

endmodule
