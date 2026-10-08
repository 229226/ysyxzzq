module ysyx_25080209_ALU #(DATA_WID = 32)(
    input [DATA_WID-1:0]rs1,rs2,
    input [13:0]alu_op,
    output reg [DATA_WID-1:0]alu_out
);
wire overflow,carry,zero;
wire Cin;
wire [4:0]shamt = rs2[4:0];
wire signed [DATA_WID-1:0]s_rs1 = rs1;

assign Cin = alu_op[1] | alu_op[8] | alu_op[9] | alu_op[10] |
             alu_op[11] | alu_op[12] | alu_op[13];

wire [DATA_WID-1:0]add1,add2,add_out;
assign add1 = rs1;
assign add2 = ({DATA_WID{Cin}}^rs2 );
assign {carry,add_out} = add1 + add2 + {{(DATA_WID-1){1'b0}},Cin};
assign overflow = (add1[DATA_WID-1] == add2[DATA_WID-1]) && (add_out [DATA_WID-1] != add1[DATA_WID-1]);
assign zero = ~(|add_out);

always @(*) begin
    case (alu_op)
        14'b00000000000001: alu_out = add_out;                                          //add
        14'b00000000000010: alu_out = add_out;                                          //sub
        14'b00000000000100: alu_out = rs1&rs2;                                          //and
        14'b00000000001000: alu_out = rs1|rs2;                                          //or
        14'b00000000010000: alu_out = rs1^rs2;                                          //xor
        14'b00000000100000: alu_out = rs1<<shamt;                                       //logic left shift
        14'b00000001000000: alu_out = rs1>>shamt;                                       //logic right shift
        14'b00000010000000: alu_out = s_rs1>>>shamt;                                    //arthmetric right shift
        14'b00000100000000: alu_out = {{(DATA_WID-1){1'b0}},zero};                      //eq
        14'b00001000000000: alu_out = {{(DATA_WID-1){1'b0}},|add_out};                  //neq
        14'b00010000000000: alu_out = {{(DATA_WID-1){1'b0}},add_out[DATA_WID-1]^overflow}; //less than
        14'b00100000000000: alu_out = {{(DATA_WID-1){1'b0}},Cin^carry};                 //unsigned less than
        14'b01000000000000: alu_out = {{(DATA_WID-1){1'b0}},~(add_out[DATA_WID-1]^overflow)}; //greater or equal than//
        14'b10000000000000: alu_out = {{(DATA_WID-1){1'b0}},~(Cin^carry)};              //unsigned greater or equal than//
        default:            alu_out = {DATA_WID{1'b0}};
    endcase
end

endmodule
