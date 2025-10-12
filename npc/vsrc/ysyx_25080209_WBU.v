module ysyx_25080209_WBU#(DATA_WID = 32)(
    input [2:0]wreg_sw,
    input [1:0]pc_sw,
    input csr_w_sw,
    input [DATA_WID-1:0]pc,imm,exu_out,mem_wreg,csr_wreg,
    input [DATA_WID-1:0]csr_wrs1,csr_wzimm,
    output [DATA_WID-1:0]pc_in,
    output [DATA_WID-1:0]reg_wdata,
    output [DATA_WID-1:0]csr_wdata,

    input ecall,mret,
    input [DATA_WID-1:0]mtvec,mepc
);
wire [DATA_WID-1:0]pc_4;
assign pc_4 = pc + 4;

wire branch;
assign branch = exu_out[0];

wire [DATA_WID-1:0]branch_out;
assign branch_out = branch ? imm + pc : pc_4;

MuxKeyWithDefault #(5,3,32) Mux_reg_wdata (reg_wdata,wreg_sw,32'b0,{
   3'b000,exu_out,
   3'b001,imm,
   3'b010,pc_4,
   3'b011,mem_wreg,
   3'b100,csr_wreg
});

wire [DATA_WID-1:0]pc_in_1;
MuxKeyWithDefault #(4,2,32) Mux_pc_wdata1 (pc_in_1,pc_sw,32'b0,{
    2'b00,pc_4,
    2'b01,exu_out,
    2'b10,branch_out,
    2'b11,pc
});

MuxKeyWithDefault #(3,2,32) Mux_pc_wdata (pc_in,{ecall,mret},32'b0,{
    2'b00,pc_in_1,
    2'b01,mepc,
    2'b10,mtvec
});

MuxKeyWithDefault #(2,1,32) Mux_csr_wdata (csr_wdata,csr_w_sw,32'b0,{
    1'b0,csr_wrs1,
    1'b1,csr_wzimm
});
endmodule
