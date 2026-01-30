module  SRAM #(ADDR_WID = 32,DATA_WID = 32) (
    input clk,
    input [ADDR_WID-1:0]addr,
    output reg [DATA_WID-1:0]data
);
import "DPI-C" function int pmem_read(input int raddr);

always @(posedge clk) begin
    data <= pmem_read(addr);
end

endmodule
