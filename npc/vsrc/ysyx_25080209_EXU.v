module ysyx_25080209_EXU #(DATA_WID = 32)(
    input clk, rst,

    // 来自 IDU
    input                IDU_valid,
    input [DATA_WID-1:0] IDU_rs1,
    input [DATA_WID-1:0] IDU_rs2,
    input [DATA_WID-1:0] IDU_imm,
    input                IDU_ALU_op1,
    input                IDU_ALU_op2,
    input [3:0]          IDU_ALU_opcode,
    input [1:0]          IDU_pc_sw,
    input                IDU_ecall,
    input                IDU_mret,
    input                IDU_reg_wen,
    input                IDU_csr_wen,
    input                IDU_csr_ren,

    // 来自 IFU
    input [DATA_WID-1:0] IFU_pc,
    input [DATA_WID-1:0] IFU_snpc,

    // 来自 CSR
    input [DATA_WID-1:0] CSR_mtvec,
    input [DATA_WID-1:0] CSR_mepc,

    // 来自 LSU
    input                LSU_ready,

    // 输出到 LSU / 其他
    output reg [DATA_WID-1:0] EXU_out,
    output [DATA_WID-1:0] EXU_pc_next,

    // 输出到 IDU
    output                EXU_reg_wen,
    output                EXU_csr_wen,
    output                EXU_csr_ren,
    output reg            EXU_ready,
    output reg            EXU_valid
);

    // ========== EXU 状态机 ==========
    // 0 idle, 1 wait_ready
    reg EXU_state, nEXU_state;
    always @(posedge clk) begin
        if(rst) EXU_state <= 0;
        else    EXU_state <= nEXU_state;
    end

    always @(*) begin
        case (EXU_state)
            0: nEXU_state = IDU_valid ? 1 : 0;
            1: nEXU_state = LSU_ready ? 0 : 1;
            default: nEXU_state = 0;
        endcase
    end

    always @(*) begin
        case (EXU_state)
            0: begin
                EXU_valid = 0;
                EXU_ready = 0;
            end
            1: begin
                EXU_valid = IDU_valid;
                EXU_ready = LSU_ready;
            end
            default: begin
                EXU_valid = 0;
                EXU_ready = 0;
            end
        endcase
    end

    // ========== ALU 数据选择 ==========
    wire [DATA_WID-1:0] alu_in1, alu_in2;
    assign alu_in1 = IDU_ALU_op1 ? IFU_pc : IDU_rs1;
    assign alu_in2 = IDU_ALU_op2 ? IDU_rs2 : IDU_imm;

    // ========== ALU 实例 ==========
    wire [DATA_WID-1:0] alu_out;
    ysyx_25080209_ALU u_ysyx_25080209_ALU(
        .rs1    (alu_in1),
        .rs2    (alu_in2),
        .alu_op (IDU_ALU_opcode),
        .alu_out(alu_out)
    );

    always @(posedge clk) begin
        if(rst) begin
            EXU_out <= 0;
        end else begin
            EXU_out <= alu_out;
        end
    end  

    // ========== PC 更新逻辑 ==========
    wire branch;
    assign branch = alu_out[0];
    wire [DATA_WID-1:0] bnpc;
    assign bnpc = branch ? (IDU_imm + IFU_pc) : IFU_snpc;

    wire [DATA_WID-1:0] pc_next_1;
    MuxKeyWithDefault #(4, 2, 32) Mux_pc_wdata1 (pc_next_1, IDU_pc_sw, 32'b0, {
        2'b00, IFU_snpc,
        2'b01, alu_out,
        2'b10, bnpc,
        2'b11, IFU_pc
    });

    MuxKeyWithDefault #(3, 2, 32) Mux_pc_wdata (EXU_pc_next, {IDU_ecall, IDU_mret}, 32'b0, {
        2'b00, pc_next_1,
        2'b01, CSR_mepc,
        2'b10, CSR_mtvec
    });

    // ========== 透传控制信号 ==========
    assign EXU_reg_wen = IDU_reg_wen;
    assign EXU_csr_wen = IDU_csr_wen;
    assign EXU_csr_ren = IDU_csr_ren;

`ifndef YOSYS

    // ========== 性能计数器 ==========
    import "DPI-C" function void EXU_fini();
    always @(posedge clk) begin
        if(EXU_valid && LSU_ready) EXU_fini();
    end

`endif

endmodule
