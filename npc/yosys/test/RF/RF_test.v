// RF_test.v
// 顶层测试模块，包含 RegisterFile 子模块并插入输出触发器
module RF_test (
    input  wire        clock,          // 时钟信号，连接到子模块的 clk
    input  wire [31:0] wdata,          // 写数据
    input  wire [3:0]  waddr,          // 写地址 (ADDR_WIDTH=4)
    input  wire [3:0]  raddr1,         // 读地址1
    input  wire [3:0]  raddr2,         // 读地址2
    input  wire        wen,            // 写使能
    output wire [31:0] rdata1_sampled, // 采样后的读数据1（触发器输出）
    output wire [31:0] rdata2_sampled  // 采样后的读数据2（触发器输出）
);

    // 子模块内部读数据线
    wire [31:0] rdata1, rdata2;

    // 实例化 RegisterFile，地址宽度固定为 4
    RegisterFile #(
        .ADDR_WIDTH(4)
    ) u_RegisterFile (
        .clk   (clock),
        .wdata (wdata),
        .waddr (waddr),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .wen   (wen)
    );

    // 插入触发器：在时钟上升沿采样读数据输出，用于评估时序
    reg [31:0] rdata1_reg, rdata2_reg;
    always @(posedge clock) begin
        rdata1_reg <= rdata1;
        rdata2_reg <= rdata2;
    end

    // 将采样后的值输出
    assign rdata1_sampled = rdata1_reg;
    assign rdata2_sampled = rdata2_reg;

endmodule