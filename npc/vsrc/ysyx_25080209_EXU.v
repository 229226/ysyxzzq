module ysyx_25080209_EXU #(DATA_WID = 32)(
    input [DATA_WID-1:0]rs1,rs2,imm,pc,
    input rs2_imm,pc_rs1,
    input [3:0]alu_op,
    output [DATA_WID-1:0]rd
);
wire [DATA_WID-1:0]alu_in2,alu_in1;

assign alu_in1 = pc_rs1  ? pc : rs1;
assign alu_in2 = rs2_imm ? rs2 : imm;

ysyx_25080209_ALU u_ysyx_25080209_ALU(
    .rs1    	(alu_in1     ),
    .rs2    	(alu_in2     ),
    .alu_op  	(alu_op),
    .alu_out 	(rd  )
);

endmodule
