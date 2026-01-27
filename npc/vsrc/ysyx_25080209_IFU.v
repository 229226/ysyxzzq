module ysyx_25080209_IFU #(DATA_WID = 32)(
    input clk,
    input [DATA_WID-1:0]pc,
    output reg [DATA_WID-1:0]ins,snpc
);
import "DPI-C" function void itrace(int ins);
import "DPI-C" function int pmem_read(input int raddr);

always @(*) begin
    ins = pmem_read(pc);
end

always @(posedge clk) begin
    itrace(ins);
end

assign snpc = pc + 32'h4;

endmodule
