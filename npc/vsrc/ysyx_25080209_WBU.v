module ysyx_25080209_WBU#(DATA_WID = 32)(
    input [1:0]wreg_sw,
    input [1:0]pc_sw,
    input [DATA_WID-1:0]pc,imm,exu_out,mem_wreg,
    output [DATA_WID-1:0]pc_in,
    output [DATA_WID-1:0]reg_wdata
);
wire [DATA_WID-1:0]pc_4;
assign pc_4 = pc + 4;

wire branch;
assign branch = exu_out[0];

wire [DATA_WID-1:0]branch_out;
assign branch_out = branch ? imm + pc : pc_4;

MuxKeyWithDefault #(4,2,32) Mux_reg_wdata (reg_wdata,wreg_sw,32'b0,{
   2'b00,exu_out,
   2'b01,imm,
   2'b10,pc_4,
   2'b11,mem_wreg
});

MuxKeyWithDefault #(3,2,32) Mux_pc_sw_WBU (pc_in,pc_sw,32'b0,{
    2'b00,pc_4,
    2'b01,exu_out,
    2'b10,branch_out
});

endmodule
