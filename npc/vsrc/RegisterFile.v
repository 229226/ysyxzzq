(* keep_hierarchy = "yes" *)  // 保持模块层次结构
module RegisterFile #(ADDR_WIDTH = 1, DATA_WIDTH = 32) (
  input clk,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input [ADDR_WIDTH-1:0] raddr1,
  input [ADDR_WIDTH-1:0] raddr2,
  output [DATA_WIDTH-1:0] rdata1,
  output [DATA_WIDTH-1:0] rdata2,
  input wen
);

reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];

wire [DATA_WIDTH -1:0]wdata_in;
assign wdata_in = (|waddr) ? wdata : 0;

always @(posedge clk) begin
  if (wen) rf[waddr] <= wdata_in;
end

`ifndef YOSYS

import "DPI-C" function void read_reg(int val,int num);
integer i;
always @(*) begin
  for(i = 0 ; i < 2**ADDR_WIDTH ; i++)begin
    read_reg(rf[i],i);
  end
end

`endif

assign rdata1 = rf[raddr1];
assign rdata2 = rf[raddr2];
endmodule
