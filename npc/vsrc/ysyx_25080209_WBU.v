module ysyx_25080209_WBU#(DATA_WID = 32)(
    input clk,rst,
    input [2:0]wreg_sw,

    input csr_w_sw,
    input [DATA_WID-1:0]imm,exu_out,snpc,mem_wreg,csr_wreg,
    input [DATA_WID-1:0]csr_wrs1,csr_wzimm,
    output [DATA_WID-1:0]reg_wdata,
    output [DATA_WID-1:0]csr_wdata,
    //WBUstate
    input LSU_valid,
    output reg WBU_ready
);
//WBUstate
//0 idle
//1 wait_ready
reg WBU_state,nWBU_state;
always @(posedge clk) begin
    if(rst) WBU_state <= 0;
    else WBU_state <= nWBU_state;
end
always @(*) begin
  case (WBU_state)
    0:begin
        if(LSU_valid) nWBU_state = 1;
        else nWBU_state = 0;
    end 
    1:begin
        nWBU_state = 0;
    end
    default;
  endcase
end
always @(*) begin
  case (WBU_state)
    0:begin
        WBU_ready = 1;
    end
    1:begin
        WBU_ready = 1;
    end
    default;
  endcase
end
//
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
