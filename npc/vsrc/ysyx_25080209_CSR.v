module ysyx_25080209_CSR #(DATA_WID = 32, ADDR_WID = 12)(
    input clk, rst,

    // 来自 IDU 的控制信号
    input                IDU_csr_wen,
    input                IDU_csr_ren,
    input [ADDR_WID-1:0] IDU_csr_waddr,
    input [ADDR_WID-1:0] IDU_csr_raddr,

    // 来自 WBU 的写数据
    input [DATA_WID-1:0] WBU_csr_wdata,

    // 来自 IFU 的 PC
    input [DATA_WID-1:0] IFU_pc,

    // 来自 IDU 的 ecall 信号
    input                IDU_ecall,

    // 输出到 WBU 的读数据
    output reg [DATA_WID-1:0] CSR_rdata,

    // 输出到 EXU 的 mtvec 和 mepc
    output [DATA_WID-1:0] CSR_mtvec,
    output [DATA_WID-1:0] CSR_mepc
);

    // CSR 寄存器
    reg [DATA_WID-1:0] mstatus, mcause, mtvec, mepc;

    // 只读寄存器
    wire [DATA_WID-1:0] mvendorid = 32'h79737978;  // "ysyx" ASCII
    wire [DATA_WID-1:0] marchid   = 32'd25080209;

    // 写操作与异常处理
    always @(posedge clk) begin
        if(rst) begin
            mstatus <= 0;
            mtvec   <= 0;
            mepc    <= 0;
            mcause  <= 0;
        end else begin
            if(IDU_csr_wen) begin
                case (IDU_csr_waddr)
                    12'h300: mstatus <= WBU_csr_wdata;
                    12'h305: mtvec   <= WBU_csr_wdata;
                    12'h341: mepc    <= WBU_csr_wdata;
                    12'h342: mcause  <= WBU_csr_wdata;
                    default: ;
                endcase
            end else begin
                if(IDU_ecall) begin
                    mepc   <= IFU_pc;
                    mcause <= 32'hb;   // 环境调用异常码
                end
            end
        end
    end

    // 读操作（组合逻辑）
    always @(*) begin
        if(IDU_csr_ren) begin
            case (IDU_csr_raddr)
                12'h300: CSR_rdata = mstatus;
                12'h305: CSR_rdata = mtvec;
                12'h341: CSR_rdata = mepc;
                12'h342: CSR_rdata = mcause;
                12'hf11: CSR_rdata = mvendorid;
                12'hf12: CSR_rdata = marchid;
                default: CSR_rdata = 0;
            endcase
        end else begin
            CSR_rdata = 0;
        end
    end

    // 输出连续赋值
    assign CSR_mtvec = mtvec;
    assign CSR_mepc  = mepc;

endmodule
