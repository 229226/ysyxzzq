module ysyx_25080209_WBU #(DATA_WID = 32)(
    input clk, rst,

    // 来自 IDU 的控制信号
    input [2:0]         IDU_wreg_sw,
    input               IDU_csr_w_sw,
    input [DATA_WID-1:0] IDU_imm,

    // 来自 EXU
    input [DATA_WID-1:0] EXU_out,

    // 来自 IFU
    input [DATA_WID-1:0] IFU_snpc,

    // 来自 LSU
    input [DATA_WID-1:0] LSU_rdata,
    input                LSU_reg_wen,
    input                LSU_csr_wen,
    input                LSU_csr_ren,

    // 来自 CSR 模块
    input [DATA_WID-1:0] CSR_wreg,
    input [DATA_WID-1:0] CSR_wrs1,
    input [DATA_WID-1:0] CSR_wzimm,

    // 输出到寄存器文件和 CSR
    output [DATA_WID-1:0] WBU_reg_wdata,
    output [DATA_WID-1:0] WBU_csr_wdata,
    output reg            WBU_reg_wen,
    output reg            WBU_csr_wen,
    output reg            WBU_csr_ren,

    // 握手信号
    input  LSU_valid,
    output reg WBU_ready
);

    // ========== WBU 状态机 ==========
    // 0 idle, 1 working
    reg WBU_state, nWBU_state;
    always @(posedge clk) begin
        if(rst) WBU_state <= 0;
        else    WBU_state <= nWBU_state;
    end

    always @(*) begin
        case (WBU_state)
            0: nWBU_state = LSU_valid ? 1 : 0;
            1: nWBU_state = 0;
            default: nWBU_state = 0;
        endcase
    end

    always @(*) begin
        case (WBU_state)
            0, 1: WBU_ready = 1;
            default: WBU_ready = 1;
        endcase
    end

    // ========== 寄存器写使能（在状态转换时锁存） ==========
    always @(*) begin
        if(nWBU_state == 1) begin
            WBU_reg_wen = LSU_reg_wen;
            WBU_csr_wen = LSU_csr_wen;
            WBU_csr_ren = LSU_csr_ren;
        end else begin
            WBU_reg_wen = 0;
            WBU_csr_wen = 0;
            WBU_csr_ren = 0;
        end
    end

    // ========== 寄存器写数据选择 ==========
    MuxKeyWithDefault #(5, 3, 32) Mux_reg_wdata (WBU_reg_wdata, IDU_wreg_sw, 32'b0, {
        3'b000, EXU_out,
        3'b001, IDU_imm,
        3'b010, IFU_snpc,
        3'b011, LSU_rdata,
        3'b100, CSR_wreg
    });

    // ========== CSR 写数据选择 ==========
    MuxKeyWithDefault #(2, 1, 32) Mux_csr_wdata (WBU_csr_wdata, IDU_csr_w_sw, 32'b0, {
        1'b0, CSR_wrs1,
        1'b1, CSR_wzimm
    });

    `ifndef YOSYS

    // ========== 性能计数器 ==========

    import "DPI-C" function void WBU_wait_LSU();
    import "DPI-C" function void WBU_write_reg();

    always @(posedge clk) begin
        if(!rst) begin
            if((WBU_state == 0) && LSU_valid) WBU_write_reg();
            else WBU_wait_LSU();
        end
    end

    `endif

endmodule
