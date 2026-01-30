module ysyx_25080209_LSU#(ADDR_WID = 32,DATA_WID = 32)(
  input clk,rst,
  input valid,wen,
  input [ADDR_WID-1:0]raddr,waddr,
  input [DATA_WID-1:0]wdata,
  input [7:0]wmask,
  input [2:0]rmask,
  output reg [DATA_WID-1:0]rdata_out,
  //中转信号
  input   EXU_reg_wen,EXU_csr_wen,EXU_csr_ren,
  output  LSU_reg_wen,LSU_csr_wen,LSU_csr_ren,
  //LSUstate
  input EXU_valid,WBU_ready,
  output reg LSU_ready,LSU_valid
);
//LSUstate
//0 idle
//1 wait_ready
reg LSU_state,nLSU_state;
always @(posedge clk) begin
    if(rst) LSU_state <= 0;
    else LSU_state <= nLSU_state;
end
always @(*) begin
  case (LSU_state)
    0:begin
        if(EXU_valid) nLSU_state = 1;
        else nLSU_state = 0;
    end 
    1:begin
        if(WBU_ready) nLSU_state = 0;
        else nLSU_state = 1;
    end
    default;
  endcase
end
always @(*) begin
  case (LSU_state)
    0:begin
        if(EXU_valid) LSU_valid = 1;
        else LSU_valid = 0;
        if(WBU_ready) LSU_ready = 1;
        else LSU_ready = 0;
    end
    1:begin
        if(EXU_valid) LSU_valid = 1;
        else LSU_valid = 0;
        if(WBU_ready) LSU_ready = 1;
        else LSU_ready = 0;
    end
    default;
  endcase
end
//LOAD data
MuxKeyWithDefault #(5,3,32) Mux_mem_wreg (rdata_out,rmask,32'b0,{
    3'b001,{{24{rdata[7]}},rdata[7:0]},     //lb
    3'b010,{{16{rdata[15]}},rdata[15:0]},   //lh
    3'b011,rdata,                               //lw
    3'b100,{24'b0,rdata[7:0]},                  //lbu
    3'b101,{16'b0,rdata[15:0]}                  //lhu
});     

import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

reg [DATA_WID-1:0]rdata;
always @(*) begin
  if (valid && (nLSU_state == 1)) begin // 有读请求时
    rdata = pmem_read(raddr);
  end
  else begin
    rdata = 0;
  end
end
always @(posedge clk) begin
  if (valid && wen) begin // 有写请求时
    if(nLSU_state == 1)pmem_write(waddr, wdata, wmask);
  end
end

assign	LSU_reg_wen = EXU_reg_wen;
assign	LSU_csr_wen = EXU_csr_wen;
assign	LSU_csr_ren = EXU_csr_ren;

// Mem #(8,32) u_Mem(
//   .clk   	(clk    ),
//   .wdata 	(wdata  ),
//   .waddr 	(waddr[7:0]  ),
//   .raddr 	(raddr[7:0]  ),
//   .wen   	(wen    ),
//   .rdata 	(rdata  )
// );
endmodule
