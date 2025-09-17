module ysyx_25080209_LSU#(ADDR_WID = 32,DATA_WID = 32)(
    input valid,wen,
    input [ADDR_WID-1:0]raddr,waddr,
    input [DATA_WID-1:0]wdata,
    input [7:0]wmask,
    output reg [DATA_WID-1:0]rdata
);
import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);
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
