module ysyx_25080209_LSU#(ADDR_WID = 32,DATA_WID = 32)(
    input valid,wen,
    input [ADDR_WID-1:0]raddr,waddr,
    input [DATA_WID-1:0]wdata,
    input [7:0]wmask,
    input [2:0]rmask,
    output reg [DATA_WID-1:0]rdata_out
);

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
  if (valid) begin // 有读写请求时
    rdata = pmem_read(raddr);
    if (wen) begin // 有写请求时
      pmem_write(waddr, wdata, wmask);
    end
  end
  else begin
    rdata = 0;
  end
end

endmodule
