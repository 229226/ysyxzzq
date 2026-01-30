(* keep_hierarchy = "yes" *)  // 保持模块层次结构
module Mem #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,raddr,
  input wen,
  output [DATA_WIDTH-1:0] rdata
);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
  end

assign rdata = rf[raddr];
endmodule
