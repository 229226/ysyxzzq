module ysyx_25080209_ALU #(DATA_WID = 32)(
    input [DATA_WID-1:0]rs1,rs2,
    input [3:0]alu_op,
    output [DATA_WID-1:0]alu_out
);
wire overflow,carry,zero;
wire Cin;
wire [4:0]shamt = rs2[4:0];
wire signed [DATA_WID-1:0]s_rs1 = rs1;

MuxKeyWithDefault #(8,4,1) Mux_Cin (Cin,alu_op,1'b0,{
    4'b0000,1'b0,
    4'b0001,1'b1,
    4'b1000,1'b1,
    4'b1001,1'b1,
    4'b1010,1'b1,
    4'b1011,1'b1,
    4'b1100,1'b1,
    4'b1101,1'b1
}
);

wire [DATA_WID-1:0]add1,add2,add_out;
assign add1 = rs1;
assign add2 = ({DATA_WID{Cin}}^rs2 );
assign {carry,add_out} = add1 + add2 + {{(DATA_WID-1){1'b0}},Cin};
assign overflow = (add1[DATA_WID-1] == add2[DATA_WID-1]) && (add_out [DATA_WID-1] != add1[DATA_WID-1]);
assign zero = ~(|add_out);

MuxKeyWithDefault #(14,4,DATA_WID) Mux_alu_out (alu_out,alu_op,{DATA_WID{1'b0}},{
    4'b0000,add_out,        //add
    4'b0001,add_out,        //sub
    4'b0010,rs1&rs2,        //and
    4'b0011,rs1|rs2,        //or
    4'b0100,rs1^rs2,        //xor
    4'b0101,rs1<<shamt,     //logic left shift
    4'b0110,rs1>>shamt,     //logic right shift
    4'b0111,s_rs1>>>shamt,    //arthmetric right shift
    4'b1000,{{(DATA_WID-1){1'b0}},zero},                            //eq
    4'b1001,{{(DATA_WID-1){1'b0}},|add_out},                        //neq
    4'b1010,{{(DATA_WID-1){1'b0}},add_out[DATA_WID-1]^overflow},    //less than
    4'b1011,{{(DATA_WID-1){1'b0}},Cin^carry},                       //unsigned less than
    4'b1100,{{(DATA_WID-1){1'b0}},~(add_out[DATA_WID-1]^overflow)}, //greater or equal than//
    4'b1101,{{(DATA_WID-1){1'b0}},~(Cin^carry)}                     //unsigned greater or equal than//
});

endmodule
