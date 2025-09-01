module ysyx_25080209_IFU #(DATA_WID = 32)(
    input clk,
    input rst,
    input [DATA_WID-1:0]pc_in,
    output [DATA_WID-1:0]pc
);
//pc
Reg #(32,32'h8000_0000) reg_pc (
    .clk    (clk),
    .din    (pc_in),
    .dout   (pc),
    .rst    (rst),
    .wen    (1'b1)
);
endmodule
