module ysyx_25080209_WBU#(DATA_WID = 32)(
    input [2:0]wreg_sw,

    input csr_w_sw,
    input [DATA_WID-1:0]imm,exu_out,snpc,mem_wreg,csr_wreg,
    input [DATA_WID-1:0]csr_wrs1,csr_wzimm,
    output [DATA_WID-1:0]reg_wdata,
    output [DATA_WID-1:0]csr_wdata
);

MuxKeyWithDefault #(5,3,32) Mux_reg_wdata (reg_wdata,wreg_sw,32'b0,{
   3'b000,exu_out,
   3'b001,imm,
   3'b010,snpc,
   3'b011,mem_wreg,
   3'b100,csr_wreg
});

MuxKeyWithDefault #(2,1,32) Mux_csr_wdata (csr_wdata,csr_w_sw,32'b0,{
    1'b0,csr_wrs1,
    1'b1,csr_wzimm
});
endmodule
