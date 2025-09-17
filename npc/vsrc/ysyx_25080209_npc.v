module ysyx_25080209_npc #(DATA_WID = 32)(
    input clk,
    input rst,
    input [DATA_WID-1:0]ins_in,
    output [DATA_WID-1:0] pc
);
//IFU
ysyx_25080209_IFU IFU (
    .clk(clk),
    .ins( ins_in)
);
//IDU
wire [3:0]alu_op;
wire rs2_imm,reg_wen,pc_rs1;
wire [1:0]pc_sw;
wire [1:0]wreg_sw;
wire [DATA_WID-1:0]imm;

ysyx_25080209_IDU IDU (
    .ins    (ins_in),
    .imm    (imm),
    .rs2_imm(rs2_imm),
    .alu_op(alu_op),
    .reg_wen(reg_wen),
    .wreg_sw(wreg_sw),
    .pc_rs1 (pc_rs1 ),
    .pc_sw  (pc_sw  ),
    .reg_raddr1 (reg_raddr1),
    .reg_raddr2 (reg_raddr2),
    .reg_waddr  (reg_waddr),
    .mem_valid  (mem_valid),
    .mem_wen    (mem_wen),
    .mem_wmask  (mem_wmask),
    .mem_rdata  (mem_rdata),
    .mem_wreg   (mem_wreg)
);
//EXU
wire [DATA_WID-1:0] exu_out;
ysyx_25080209_EXU EXU(
    .rs1     	(reg_rdata1 ),
    .rs2     	(reg_rdata2 ),
    .imm     	(imm        ),
    .pc         (pc         ),
    .alu_op 	(alu_op    ),
    .rs2_imm 	(rs2_imm    ),
    .pc_rs1     (pc_rs1     ),
    .rd      	(exu_out    )
);
//LSU
wire mem_valid,mem_wen;
wire [7:0]mem_wmask;
wire [DATA_WID-1:0]mem_rdata,mem_wreg;

ysyx_25080209_LSU LSU(
    .valid(mem_valid),
    .wen  (mem_wen),
    .wmask(mem_wmask),
    .raddr(exu_out),
    .rdata(mem_rdata),
    .waddr(exu_out),
    .wdata(reg_rdata2)
);
//WBU
wire [DATA_WID-1:0] pc_in;

ysyx_25080209_WBU WBU(
    .wreg_sw    (wreg_sw),
    .pc_sw      (pc_sw  ),
    .pc    	    (pc     ),
    .pc_in 	    (pc_in  ),
    .exu_out    (exu_out),
    .imm        (imm    ),
    .reg_wdata  (reg_wdata),
    .mem_wreg  (mem_wreg)
);
//regs
wire [4:0]reg_raddr1,reg_raddr2,reg_waddr;
wire [DATA_WID-1:0] reg_wdata,reg_rdata1,reg_rdata2;

RegisterFile #(5,32) Regs (
    .clk    (clk),
    .raddr1 (reg_raddr1),
    .raddr2 (reg_raddr2),
    .rdata1 (reg_rdata1),
    .rdata2 (reg_rdata2),
    .waddr  (reg_waddr),
    .wdata  (reg_wdata),
    .wen    (reg_wen)
);
//pc
Reg #(32,32'h8000_0000) reg_pc (
    .clk    (clk),
    .din    (pc_in),
    .dout   (pc),
    .rst    (rst),
    .wen    (1'b1)
);
endmodule
