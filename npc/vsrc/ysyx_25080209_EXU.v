module ysyx_25080209_EXU #(DATA_WID = 32)(
    input [DATA_WID-1:0]rs1,rs2,imm,
    input sub_add,rs2_imm,
    output [DATA_WID-1:0]rd
);
wire [DATA_WID-1:0]rs2_in;
assign rs2_in = rs2_imm ? rs2 : imm;

//adder
wire [DATA_WID-1:0]add2,adder_out;
assign add2 = sub_add ? (~rs2_in) : rs2_in;
assign adder_out = rs1 + add2 + {{31{1'b0}},sub_add};

assign rd = adder_out;
endmodule
