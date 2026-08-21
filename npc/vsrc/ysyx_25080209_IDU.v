module ysyx_25080209_IDU#(DATA_WID = 32, RADDR_WID = 4)(
    input clk, rst,

    // Handshake with IFU
    input                   IFU_valid,
    output reg              IDU_ready,   // 组合逻辑输出（不寄存）

    // IFU input
    input [DATA_WID-1:0]    IFU_instr,
    
    // Handshake with EXU
    input                   EXU_ready,
    output reg              IDU_valid,   // 组合逻辑输出（不寄存）

    // output to EXU
    output reg              IDU_ALU_op1,
    output reg              IDU_ALU_op2,
    output reg [3:0]        IDU_ALU_opcode,
    output reg [DATA_WID-1:0] IDU_imm,
    output reg [1:0]        IDU_pc_sw,

    // output to Register
    output reg [RADDR_WID-1:0] IDU_reg_raddr1,
    output reg [RADDR_WID-1:0] IDU_reg_raddr2,
    output reg               IDU_reg_wen,
    output reg [RADDR_WID-1:0] IDU_reg_waddr,
    output reg [2:0]         IDU_wreg_sw,

    // output to LSU
    output reg               IDU_mem_ren,
    output reg               IDU_mem_wen,
    output reg [3:0]         IDU_mem_wmask,
    output reg [2:0]         IDU_mem_rmask,

    // output to CSR
    output reg               IDU_csr_wen,
    output reg               IDU_csr_ren,
    output reg               IDU_csr_w_sw,
    output reg [DATA_WID-1:0] IDU_csr_zimm,

    // Special signals
    output reg               IDU_ecall,
    output reg               IDU_mret
);

    // ========== IDU state machine ==========
    reg IDU_state, nIDU_state;
    always @(posedge clk) begin
        if (rst) IDU_state <= 0;
        else     IDU_state <= nIDU_state;
    end

    // 组合逻辑：状态转移
    always @(*) begin
        case (IDU_state)
            0: nIDU_state = IFU_valid ? 1 : 0;
            1: nIDU_state = EXU_ready ? 0 : 1;
            default: nIDU_state = 0;
        endcase
    end

    // 组合逻辑：IDU_valid 和 IDU_ready（不寄存）
    always @(*) begin
        case (IDU_state)
            0: begin
                IDU_valid = 0;
                IDU_ready = 0;
            end
            1: begin
                IDU_valid = IFU_valid;
                IDU_ready = EXU_ready;
            end
            default: begin
                IDU_valid = 0;
                IDU_ready = 0;
            end
        endcase
    end

    // ========== 组合逻辑中间信号（用于寄存的输出） ==========
    wire [6:0] opcode = IFU_instr[6:0];
    wire [2:0] func3  = IFU_instr[14:12];

    wire [RADDR_WID-1:0] reg_raddr1_comb = IFU_instr[15 + RADDR_WID - 1 : 15];
    wire [RADDR_WID-1:0] reg_raddr2_comb = IFU_instr[20 + RADDR_WID - 1 : 20];
    wire [RADDR_WID-1:0] reg_waddr_comb  = IFU_instr[7  + RADDR_WID - 1 : 7];

    // ========== ebreak (DPI-C) ==========
    wire status_ebreak;
    MuxKeyWithDefault #(1, 32, 1) Mux_ebreak (status_ebreak, IFU_instr, 1'b0, {
        32'b000000000001_00000_000_00000_1110011, 1'b1   // ebreak
    });

    // ========== ecall / mret ==========
    wire ecall_comb, mret_comb;
    MuxKeyWithDefault #(1, 32, 1) Mux_ecall (ecall_comb, IFU_instr, 1'b0, {
        32'b000000000000_00000_000_00000_1110011, 1'b1
    });
    MuxKeyWithDefault #(1, 32, 1) Mux_mret (mret_comb, IFU_instr, 1'b0, {
        32'b0011000_00010_00000_000_00000_1110011, 1'b1
    });

    // ========== ALU opcode ==========
    reg [3:0] ALU_opcode_comb;
    always @(*) begin
        casez ({IFU_instr[31:25], func3, opcode})
            17'b???????_000_1100011: ALU_opcode_comb = 4'b1000; // beq
            17'b???????_001_1100011: ALU_opcode_comb = 4'b1001; // bne
            17'b???????_100_1100011: ALU_opcode_comb = 4'b1010; // blt
            17'b???????_101_1100011: ALU_opcode_comb = 4'b1100; // bge
            17'b???????_110_1100011: ALU_opcode_comb = 4'b1011; // bltu
            17'b???????_111_1100011: ALU_opcode_comb = 4'b1101; // bgeu
            17'b???????_010_0010011: ALU_opcode_comb = 4'b1010; // slti
            17'b???????_011_0010011: ALU_opcode_comb = 4'b1011; // sltu
            17'b???????_100_0010011: ALU_opcode_comb = 4'b0100; // xori
            17'b???????_110_0010011: ALU_opcode_comb = 4'b0011; // ori
            17'b???????_111_0010011: ALU_opcode_comb = 4'b0010; // andi
            17'b0000000_001_0010011: ALU_opcode_comb = 4'b0101; // slli
            17'b0000000_101_0010011: ALU_opcode_comb = 4'b0110; // srli
            17'b0100000_101_0010011: ALU_opcode_comb = 4'b0111; // srai
            17'b0100000_000_0110011: ALU_opcode_comb = 4'b0001; // sub
            17'b0000000_001_0110011: ALU_opcode_comb = 4'b0101; // sll
            17'b0000000_010_0110011: ALU_opcode_comb = 4'b1010; // slt
            17'b0000000_011_0110011: ALU_opcode_comb = 4'b1011; // sltu
            17'b0000000_100_0110011: ALU_opcode_comb = 4'b0100; // xor
            17'b0000000_101_0110011: ALU_opcode_comb = 4'b0110; // srl
            17'b0100000_101_0110011: ALU_opcode_comb = 4'b0111; // sra
            17'b0000000_110_0110011: ALU_opcode_comb = 4'b0011; // or
            17'b0000000_111_0110011: ALU_opcode_comb = 4'b0010; // and
            default: ALU_opcode_comb = 4'b0;
        endcase
    end

    // ========== ALU operand 1 select ==========
    wire ALU_op1_comb;
    MuxKeyWithDefault #(2, 7, 1) Mux_pc_rs1 (ALU_op1_comb, opcode, 1'b0, {
        7'b0010111, 1'b1,   // auipc
        7'b1101111, 1'b1    // jal
    });

    // ========== ALU operand 2 select ==========
    wire ALU_op2_comb;
    MuxKeyWithDefault #(2, 7, 1) Mux_rs2_imm (ALU_op2_comb, opcode, 1'b0, {
        7'b1100011, 1'b1,   // branch
        7'b0110011, 1'b1    // R-type
    });

    // ========== Immediate generation ==========
    wire [DATA_WID-1:0] imm_U = {IFU_instr[31:12], {12{1'b0}}};
    wire [DATA_WID-1:0] imm_J = {{11{IFU_instr[31]}}, IFU_instr[31], IFU_instr[19:12], IFU_instr[20], IFU_instr[30:21], 1'b0};
    wire [DATA_WID-1:0] imm_I = {{20{IFU_instr[31]}}, IFU_instr[31:20]};
    wire [DATA_WID-1:0] imm_B = {{20{IFU_instr[31]}}, IFU_instr[7], IFU_instr[30:25], IFU_instr[11:8], 1'b0};
    wire [DATA_WID-1:0] imm_S = {{20{IFU_instr[31]}}, IFU_instr[31:25], IFU_instr[11:7]};

    wire [DATA_WID-1:0] imm_comb;
    MuxKeyWithDefault #(9, 7, 32) Mux_imm (imm_comb, opcode, 32'b0, {
        7'b0110111, imm_U,   // lui
        7'b0010111, imm_U,   // auipc
        7'b1101111, imm_J,   // jal
        7'b1100111, imm_I,   // jalr
        7'b1100011, imm_B,   // branch
        7'b0000011, imm_I,   // load
        7'b0100011, imm_S,   // store
        7'b0010011, imm_I,   // I-type ALU
        7'b1110011, imm_I    // CSR
    });

    // ========== Register write enable ==========
    wire reg_wen_comb;
    MuxKeyWithDefault #(8, 7, 1) Mux_reg_wen (reg_wen_comb, opcode, 1'b0, {
        7'b0110111, 1'b1,   // lui
        7'b0010111, 1'b1,   // auipc
        7'b1101111, 1'b1,   // jal
        7'b1100111, 1'b1,   // jalr
        7'b0000011, 1'b1,   // load
        7'b0010011, 1'b1,   // I-type ALU
        7'b0110011, 1'b1,   // R-type
        7'b1110011, 1'b1    // CSR
    });

    // ========== Write-back data select ==========
    wire [2:0] wreg_sw_comb;
    MuxKeyWithDefault #(5, 7, 3) Mux_wreg_sw (wreg_sw_comb, opcode, 3'b0, {
        7'b0110111, 3'b001, // lui -> imm
        7'b1101111, 3'b010, // jal -> snpc
        7'b1100111, 3'b010, // jalr -> snpc
        7'b0000011, 3'b011, // load -> mem
        7'b1110011, 3'b100  // CSR -> csr
    });

    // ========== PC selection ==========
    wire [1:0] pc_sw_comb;
    MuxKeyWithDefault #(4, 7, 2) Mux_pc_sw (pc_sw_comb, opcode, 2'b0, {
        7'b1101111, 2'b01,  // jal
        7'b1100111, 2'b01,  // jalr
        7'b1100011, 2'b10,  // branch
        7'b0000000, 2'b11   // invalid
    });

    // ========== Memory read / write ==========
    wire mem_ren_comb;
    MuxKeyWithDefault #(1, 7, 1) Mux_mem_valid (mem_ren_comb, opcode, 1'b0, {
        7'b0000011, 1'b1    // load
    });

    wire mem_wen_comb;
    MuxKeyWithDefault #(1, 7, 1) Mux_mem_wen (mem_wen_comb, opcode, 1'b0, {
        7'b0100011, 1'b1    // store
    });

    wire [3:0] mem_wmask_comb;
    MuxKeyWithDefault #(3, 10, 4) Mux_mem_wmask (mem_wmask_comb, {func3, opcode}, 4'b0, {
        10'b000_0100011, 4'b0001, // sb
        10'b001_0100011, 4'b0011, // sh
        10'b010_0100011, 4'b1111  // sw
    });

    wire [2:0] mem_rmask_comb;
    MuxKeyWithDefault #(5, 10, 3) Mux_mem_wreg (mem_rmask_comb, {func3, opcode}, 3'b0, {
        10'b000_0000011, 3'b001, // lb
        10'b001_0000011, 3'b010, // lh
        10'b010_0000011, 3'b011, // lw
        10'b100_0000011, 3'b100, // lbu
        10'b101_0000011, 3'b101  // lhu
    });

    // ========== CSR control ==========
    wire [1:0] csr_sc_w;
    wire csr_w_sw_comb;
    wire [DATA_WID-1:0] csr_zimm_comb = {{(DATA_WID-5){1'b0}}, IFU_instr[24:20]};

    MuxKeyWithDefault #(6, 10, 3) Mux_csr_sc_w ({csr_sc_w, csr_w_sw_comb}, {func3, opcode}, 3'b0, {
        10'b001_1110011, 3'b01_0,
        10'b010_1110011, 3'b10_0,
        10'b011_1110011, 3'b10_0,
        10'b101_1110011, 3'b01_1,
        10'b110_1110011, 3'b10_1,
        10'b111_1110011, 3'b10_1
    });

    reg csr_wen_comb, csr_ren_comb;
    always @(*) begin
        casez ({reg_raddr1_comb, csr_sc_w})
            6'b????_00: csr_wen_comb = 1'b0;
            6'b0000_10: csr_wen_comb = 1'b0;
            default: csr_wen_comb = 1'b1;
        endcase
    end

    always @(*) begin
        casez ({reg_waddr_comb, csr_sc_w})
            6'b????_00: csr_ren_comb = 1'b0;
            6'b0000_01: csr_ren_comb = 1'b0;
            default: csr_ren_comb = 1'b1;
        endcase
    end

    // ========== 所有输出（除 valid/ready）寄存器化 ==========
    always @(posedge clk) begin
        if (rst) begin
            IDU_ALU_op1    <= 0;
            IDU_ALU_op2    <= 0;
            IDU_ALU_opcode <= 0;
            IDU_imm        <= 0;
            IDU_pc_sw      <= 0;
            IDU_reg_raddr1 <= 0;
            IDU_reg_raddr2 <= 0;
            IDU_reg_wen    <= 0;
            IDU_reg_waddr  <= 0;
            IDU_wreg_sw    <= 0;
            IDU_mem_ren    <= 0;
            IDU_mem_wen    <= 0;
            IDU_mem_wmask  <= 0;
            IDU_mem_rmask  <= 0;
            IDU_csr_wen    <= 0;
            IDU_csr_ren    <= 0;
            IDU_csr_w_sw   <= 0;
            IDU_csr_zimm   <= 0;
            IDU_ecall      <= 0;
            IDU_mret       <= 0;
        end else begin
            IDU_ALU_op1    <= ALU_op1_comb;
            IDU_ALU_op2    <= ALU_op2_comb;
            IDU_ALU_opcode <= ALU_opcode_comb;
            IDU_imm        <= imm_comb;
            IDU_pc_sw      <= pc_sw_comb;
            IDU_reg_raddr1 <= reg_raddr1_comb;
            IDU_reg_raddr2 <= reg_raddr2_comb;
            IDU_reg_wen    <= reg_wen_comb;
            IDU_reg_waddr  <= reg_waddr_comb;
            IDU_wreg_sw    <= wreg_sw_comb;
            IDU_mem_ren    <= mem_ren_comb;
            IDU_mem_wen    <= mem_wen_comb;
            IDU_mem_wmask  <= mem_wmask_comb;
            IDU_mem_rmask  <= mem_rmask_comb;
            IDU_csr_wen    <= csr_wen_comb;
            IDU_csr_ren    <= csr_ren_comb;
            IDU_csr_w_sw   <= csr_w_sw_comb;
            IDU_csr_zimm   <= csr_zimm_comb;
            IDU_ecall      <= ecall_comb;
            IDU_mret       <= mret_comb;
        end
    end

`ifndef YOSYS

    // ========== ebreak (DPI-C) ==========
    import "DPI-C" function void ebreak();
    always @(*) begin
        if (status_ebreak) ebreak();
    end

    // ========== Performance counter ==========
    import "DPI-C" function void IDU_U();
    import "DPI-C" function void IDU_J();
    import "DPI-C" function void IDU_I();
    import "DPI-C" function void IDU_Ical();
    import "DPI-C" function void IDU_B();
    import "DPI-C" function void IDU_Rcal();

    import "DPI-C" function void IDU_LOAD();
    import "DPI-C" function void IDU_STORE();

    import "DPI-C" function void IDU_CSR();
    
    import "DPI-C" function void IDU_wait_IFU();
    import "DPI-C" function void IDU_update_output();
    import "DPI-C" function void IDU_wait_EXU();

    always @(posedge clk) begin
        if(!rst) begin
            if((IDU_state == 0) && (!IFU_valid)) IDU_wait_IFU();
            else if((IDU_state == 0) && IFU_valid) IDU_update_output();
            else if(IDU_state == 1) IDU_wait_EXU();

            if (IDU_valid && EXU_ready) begin  // 使用组合逻辑的 IDU_valid
            case(opcode)
            7'b0110111: IDU_U();
            7'b0010111: IDU_U();
            7'b1101111: IDU_J();
            7'b1100111: IDU_I();
            7'b1100011: IDU_B();
            7'b0000011: IDU_LOAD();
            7'b0100011: IDU_STORE();
            7'b0010011: IDU_Ical();
            7'b0110011: IDU_Rcal();
            7'b1110011: begin
                if(func3 == 3'b000) IDU_I();
                else IDU_CSR();
            end
            default;
            endcase
        end 
        end
    end
    
`endif

endmodule
