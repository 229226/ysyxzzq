module  SRAM_LSU #(ADDR_WID = 32,DATA_WID = 32) (
    input clk,
    input wen,ren,
    input [3:0]wmask,
    input [ADDR_WID-1:0]raddr,waddr,
    input [DATA_WID-1:0]wdata,
    output reg [DATA_WID-1:0]rdata
);
import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

always @(posedge clk) begin
    if(ren) rdata <= pmem_read(raddr);
    if(wen) pmem_write(waddr,wdata,{4'b0000,wmask});
end

endmodule
