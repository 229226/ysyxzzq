module ysyx_25080209_npc #(DATA_WID = 32)(
    input clk,
    input rst
);
wire [DATA_WID-1:0]ins,pc,snpc;
//IFU
ysyx_25080209_IFU IFU (
    .clk(clk),
    .pc(pc),
    .ins( ins),
    .snpc(snpc)
);
//IDU
wire [DATA_WID-1:0]imm;
wire [3:0]alu_op;
wire rs2_imm,reg_wen,pc_rs1;
wire [1:0]pc_sw;
wire [2:0]wreg_sw;
//IDU_csr
wire wen_csr,ren_csr,csr_w_sw;
wire [DATA_WID-1:0] csr_zimm;
//IDU_ecall
wire ecall;
//IDU_mret
wire mret;
ysyx_25080209_IDU #(32,4) IDU (
    .ins    (ins),
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
    .mem_rmask  (mem_rmask),

    .wen_csr    (wen_csr ),
    .ren_csr    (ren_csr),
    .csr_w_sw   (csr_w_sw),
    .csr_zimm   (csr_zimm),

    .ecall      (ecall),

    .mret       (mret)
);
//EXU
wire [DATA_WID-1:0] exu_out,pc_next;
ysyx_25080209_EXU EXU(
    .rs1     	(reg_rdata1 ),
    .rs2     	(reg_rdata2 ),
    .imm     	(imm        ),
    .pc         (pc         ),
    .alu_op 	(alu_op     ),
    .rs2_imm 	(rs2_imm    ),
    .pc_rs1     (pc_rs1     ),
    .exu_out    (exu_out    ),

    .snpc       (snpc),
    .pc_sw      (pc_sw),
    .ecall      (ecall),
    .mret       (mret),
    .mtvec      (mtvec_out),
    .mepc       (mepc_out),
    .pc_next    (pc_next)
);
//LSU
wire mem_valid,mem_wen;
wire [7:0]mem_wmask;
wire [DATA_WID-1:0]mem_rdata;
wire [2:0]mem_rmask;
ysyx_25080209_LSU LSU(
    .valid(mem_valid),
    .wen  (mem_wen),
    .wmask(mem_wmask),
    .rmask (mem_rmask),
    .raddr(exu_out),
    .rdata_out(mem_rdata),
    .waddr(exu_out),
    .wdata(reg_rdata2)
);
//WBU
ysyx_25080209_WBU WBU(
    .wreg_sw    (wreg_sw),
    .exu_out    (exu_out),
    .imm        (imm    ),
    .mem_wreg  (mem_rdata),
    .csr_wreg   (csr_rdata),

    .csr_w_sw   (csr_w_sw),
    .csr_wrs1   (reg_rdata1),
    .csr_wzimm  (csr_zimm),

    .snpc 	    (snpc  ),
    .reg_wdata  (reg_wdata),
    .csr_wdata  (csr_wdata)
);
//regs
wire [3:0]reg_raddr1,reg_raddr2,reg_waddr;
wire [DATA_WID-1:0] reg_wdata,reg_rdata1,reg_rdata2;
RegisterFile #(4,32) Regs (
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
    .din    (pc_next),
    .dout   (pc),
    .rst    (rst),
    .wen    (1'b1)
);
//csr
// output declaration of module ysyx_25080209_CSR
wire [DATA_WID-1:0] csr_rdata,csr_wdata;
wire [11:0]csr_raddr,csr_waddr;
assign csr_raddr = imm[11:0];
assign csr_waddr = imm[11:0];

wire [DATA_WID-1:0]mtvec_out,mepc_out;
ysyx_25080209_CSR u_ysyx_25080209_CSR(
    .clk   	(clk    ),
    .rst    (rst    ),

    .wen   	(wen_csr    ),
    .ren   	(ren_csr    ),
    .wdata 	(csr_wdata  ),
    .waddr 	(csr_waddr  ),
    .raddr 	(csr_raddr  ),
    .rdata 	(csr_rdata  ),

    .pc     (pc),
    .ecall  (ecall),
    
    .mtvec_out  (mtvec_out),
    .mepc_out   (mepc_out)
);

import "DPI-C" function void read_reg(int val,int num);
always @(*) begin
    read_reg(pc,32);
end
endmodule
