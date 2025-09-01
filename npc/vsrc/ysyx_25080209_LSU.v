module ysyx_25080209_LSU#(ADDR_WID = 5,DATA_WID = 32)(
    input clk,reg_wen,
    input [ADDR_WID-1:0] reg_raddr1,reg_raddr2,reg_waddr,
    input [DATA_WID-1:0] reg_wdata,
    output [DATA_WID-1:0] reg_rdata1,reg_rdata2
);

RegisterFile #(5,32) Regs (
    .clk    (clk),
    .raddr1 (reg_raddr1),
    .raddr2 (reg_raddr2),
    .rdata1 (reg_rdata1),
    .rdata2 (reg_rdata2),
    .waddr  (reg_waddr),
    .wdata  (reg_wdata),
    .wen    (reg_wen)
);
endmodule
