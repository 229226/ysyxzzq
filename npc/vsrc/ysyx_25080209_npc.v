module ysyx_25080209_npc #(DATA_WID = 32)(
    input clk,
    input rst,
    input [DATA_WID-1:0]ins_in,
    output [DATA_WID-1:0] pc
);
//IFU
ysyx_25080209_IFU IFU (
    .clk    (clk     ),
    .rst    (rst     ),
    .pc     (pc      ),
    .pc_in  (pc_in)
);
//IDU
wire rs2_imm,sub_add,reg_wen;
wire [DATA_WID-1:0]imm;

ysyx_25080209_IDU IDU (
    .ins    (ins_in),
    .imm    (imm),
    .rs2_imm(rs2_imm),
    .sub_add(sub_add),
    .reg_wen(reg_wen),
    .reg_raddr1 (reg_raddr1),
    .reg_raddr2 (reg_raddr2),
    .reg_waddr  (reg_waddr)
);
//EXU
ysyx_25080209_EXU u_ysyx_25080209_EXU(
    .rs1     	(reg_rdata1),
    .rs2     	(reg_rdata2),
    .imm     	(imm      ),
    .sub_add 	(sub_add  ),
    .rs2_imm 	(rs2_imm  ),
    .rd      	(reg_wdata)
);

//LSU
wire [4:0]reg_raddr1,reg_raddr2,reg_waddr;
wire [DATA_WID-1:0] reg_wdata,reg_rdata1,reg_rdata2;

ysyx_25080209_LSU u_ysyx_25080209_LSU(
    .clk        	(clk         ),
    .reg_wen    	(reg_wen     ),
    .reg_raddr1 	(reg_raddr1  ),
    .reg_raddr2 	(reg_raddr2  ),
    .reg_waddr  	(reg_waddr   ),
    .reg_wdata  	(reg_wdata   ),
    .reg_rdata1 	(reg_rdata1  ),
    .reg_rdata2 	(reg_rdata2  )
);
//WBU
wire [DATA_WID-1:0] pc_in;

ysyx_25080209_WBU u_ysyx_25080209_WBU(
    .pc    	(pc     ),
    .pc_in 	(pc_in  )
);


endmodule
