module ysyx_25080209_EXU #(DATA_WID = 32)(
    input [DATA_WID-1:0]rs1,rs2,imm,pc,
    input rs2_imm,pc_rs1,
    input [3:0]alu_op,
    output [DATA_WID-1:0]exu_out,

    input [DATA_WID-1:0]snpc,
    input [1:0]pc_sw,
    input ecall,mret,
    input [DATA_WID-1:0]mtvec,mepc,
    output [DATA_WID-1:0]pc_next
);


wire [DATA_WID-1:0]alu_in2,alu_in1,alu_out;
assign alu_in1 = pc_rs1  ? pc : rs1;
assign alu_in2 = rs2_imm ? rs2 : imm;
ysyx_25080209_ALU u_ysyx_25080209_ALU(
    .rs1    	(alu_in1     ),
    .rs2    	(alu_in2     ),
    .alu_op  	(alu_op),
    .alu_out 	(alu_out  )
);
assign exu_out = alu_out;

//renew pc
wire branch;
assign branch = alu_out[0];
wire [DATA_WID-1:0]bnpc;
assign bnpc = branch ? imm + pc : snpc;

wire [DATA_WID-1:0]pc_next_1;
MuxKeyWithDefault #(4,2,32) Mux_pc_wdata1 (pc_next_1,pc_sw,32'b0,{
    2'b00,snpc,
    2'b01,alu_out,
    2'b10,bnpc,
    2'b11,pc
});

MuxKeyWithDefault #(3,2,32) Mux_pc_wdata (pc_next,{ecall,mret},32'b0,{
    2'b00,pc_next_1,
    2'b01,mepc,
    2'b10,mtvec
});

endmodule
