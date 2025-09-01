module ysyx_25080209_IDU#(DATA_WID = 32,RADDR_WID = 5)(
    input [DATA_WID-1:0]ins,
    output [DATA_WID-1:0]imm,
    output sub_add,             //1-,0+
    output rs2_imm,             //1 rs2,0 imm
    output reg_wen,
    output [RADDR_WID-1:0] reg_raddr1,reg_raddr2,reg_waddr
);
import "DPI-C" function int ebreak();
wire status_ebreak;
wire [DATA_WID-1:0]r_ebreak;
assign r_ebreak = status_ebreak ? ebreak() : 32'b0;

wire [6:0]opcode;
wire [2:0]func3;
assign opcode = ins[6:0];
assign func3 = ins[14:12];

assign reg_raddr1 = ins[19:15];
assign reg_raddr2 = ins[24:20];
assign reg_waddr  = ins[11:7];

MuxKeyWithDefault #(1,32,1) Mux_ebreak (status_ebreak,ins,1'b0,{
    32'b000000000001_00000_000_00000_1110011,1'b1
}
);

MuxKeyWithDefault #(1,10,1) Mux_sub_add (sub_add,{func3,opcode},1'b0,{
    10'b000_0010011, 1'b0
}
);

MuxKeyWithDefault #(1,10,1) Mux_rs2_imm (rs2_imm,{func3,opcode},1'b0,{
    10'b000_0010011, 1'b0
}
);

MuxKeyWithDefault #(1,7,32) Mux_imm (imm,opcode,32'b0,{
    7'b0010011,{{20{ins[31]}},ins[31:20]}
}
);

MuxKeyWithDefault #(1,7,1) Mux_reg_wen (reg_wen,opcode,1'b0,{
    7'b0010011,1'b1
}
);
endmodule
