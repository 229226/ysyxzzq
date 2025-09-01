module ysyx_25080209_WBU#(DATA_WID = 32)(
    input [DATA_WID-1:0]pc,
    output [DATA_WID-1:0]pc_in
);

assign pc_in = pc + 4;

endmodule
