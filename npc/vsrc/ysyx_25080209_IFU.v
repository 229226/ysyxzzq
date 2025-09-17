module ysyx_25080209_IFU #(DATA_WID = 32)(
    input clk,
    input [DATA_WID-1:0]ins
);
import "DPI-C" function void itrace(int ins);

always @(posedge clk) begin
    itrace(ins);
end

endmodule
