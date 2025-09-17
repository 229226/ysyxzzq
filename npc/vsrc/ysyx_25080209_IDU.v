module ysyx_25080209_IDU#(DATA_WID = 32,RADDR_WID = 5)(
    input [DATA_WID-1:0]ins,mem_rdata,
    output [DATA_WID-1:0]imm,
    output reg [3:0]alu_op,            
    output rs2_imm,             //1 rs2,0 imm
    output reg_wen,
    output [1:0]wreg_sw,
    output pc_rs1,
    output [1:0]pc_sw,
    output [RADDR_WID-1:0] reg_raddr1,reg_raddr2,reg_waddr,
    output  mem_valid,mem_wen,
    output  [7:0]mem_wmask,
    output [DATA_WID-1:0]mem_wreg
);
import "DPI-C" function void ebreak();
wire status_ebreak;
always @(*) begin
    if(status_ebreak) begin
        ebreak();
    end
end

wire [6:0]opcode;
wire [2:0]func3;
assign opcode = ins[6:0];
assign func3 = ins[14:12];

assign reg_raddr1 = ins[19:15];
assign reg_raddr2 = ins[24:20];
assign reg_waddr  = ins[11:7];

MuxKeyWithDefault #(1,32,1) Mux_ebreak (status_ebreak,ins,1'b0,{
    32'b000000000001_00000_000_00000_1110011,1'b1   //ebreak
});
//alu_op
always @(*) begin
    casez ({ins[31:25],func3,opcode})
        17'b???????_000_1100011:alu_op = 4'b1000;       //beq
        17'b???????_001_1100011:alu_op = 4'b1001;       //bne
        17'b???????_100_1100011:alu_op = 4'b1010;       //blt
        17'b???????_101_1100011:alu_op = 4'b1100;       //bge
        17'b???????_110_1100011:alu_op = 4'b1011;       //bltu
        17'b???????_111_1100011:alu_op = 4'b1101;       //bgeu
        //0000 addi
        17'b???????_010_0010011:alu_op = 4'b1010;       //slti
        17'b???????_011_0010011:alu_op = 4'b1011;       //sltu
        17'b???????_100_0010011:alu_op = 4'b0100;       //xori
        17'b???????_110_0010011:alu_op = 4'b0011;       //ori
        17'b???????_111_0010011:alu_op = 4'b0010;       //andi
        17'b0000000_001_0010011:alu_op = 4'b0101;       //slli
        17'b0000000_101_0010011:alu_op = 4'b0110;       //srli
        17'b0100000_101_0010011:alu_op = 4'b0111;       //srai
        //0000 add
        17'b0100000_000_0110011:alu_op = 4'b0001;       //sub
        17'b0000000_001_0110011:alu_op = 4'b0101;       //sll
        17'b0000000_010_0110011:alu_op = 4'b1010;       //slt
        17'b0000000_011_0110011:alu_op = 4'b1011;       //sltu
        17'b0000000_100_0110011:alu_op = 4'b0100;       //xor
        17'b0000000_101_0110011:alu_op = 4'b0110;       //srl
        17'b0100000_101_0110011:alu_op = 4'b0111;       //sra
        17'b0000000_110_0110011:alu_op = 4'b0011;       //or
        17'b0000000_111_0110011:alu_op = 4'b0010;       //and
    default:alu_op = 4'b0;
    endcase
end
//pc_rs1 determin the alu_in1
//0 rs1
//1 pc
MuxKeyWithDefault #(2,7,1) Mux_pc_rs1  (pc_rs1,opcode,1'b0,{
    7'b0010111, 1'b1,   //auipc
    7'b1101111, 1'b1    //jal
});
//rs2_imm determine the alu_in2
//0 imm
//1 rs2
MuxKeyWithDefault #(2,7,1) Mux_rs2_imm (rs2_imm,opcode,1'b0,{
    //0 auipc,jal,jalr
    7'b1100011,1'b1,   //bwq,bnw,blt,bge,bltu,bgeu
    //0 lb,lh,lw,lbu,lhu,sb,sh,sw,addi,slti,sltiu,xori,ori,andi,slli,srli,srai
    7'b0110011,1'b1   //add,sub,sll,slt,sltu,xor,srl,sra,or,and
});
wire [DATA_WID-1:0]imm_U = {ins[31:12],{12{1'b0}}};
wire [DATA_WID-1:0]imm_J = {{11{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0};
wire [DATA_WID-1:0]imm_I = {{20{ins[31]}},ins[31:20]};
wire [DATA_WID-1:0]imm_B = {{20{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0};
wire [DATA_WID-1:0]imm_S = {{20{ins[31]}},ins[31:25],ins[11:7]};

MuxKeyWithDefault #(8,7,32) Mux_imm (imm,opcode,32'b0,{
    7'b0110111,imm_U,   //lui
    7'b0010111,imm_U,   //auipc
    7'b1101111,imm_J,   //jal
    7'b1100111,imm_I,   //jalr
    7'b1100011,imm_B,   //beq,bne,blt,bge,bltu,bgeu
    7'b0000011,imm_I,   //lb,lh,lw,lbu,lhu
    7'b0100011,imm_S,   //sb,sh,sw
    7'b0010011,imm_I    //addi,slti,sltiu,xori,ori,andi,slli,srli,srai
});
//reg_wen
//0 disable
//1 enable
MuxKeyWithDefault #(7,7,1) Mux_reg_wen (reg_wen,opcode,1'b0,{
    7'b0110111,1'b1,            //lui
    7'b0010111,1'b1,            //auipc
    7'b1101111,1'b1,            //jal
    7'b1100111,1'b1,            //jalr
    7'b0000011,1'b1,            //lb,lh,lw,lbu,lhu
    //0 sb,sh,sw
    7'b0010011,1'b1,            //addi,slti,sltiu,xori,ori,andi,slli,srli,srai
    7'b0110011,1'b1             //add,sub,sll,slt,sltu,xor,srl,sra,or,and
}
);
//wreg_sw
//00 write exu_out
//01 write imm 
//10 write pc+4
//11 write mem_wreg
MuxKeyWithDefault #(4,7,2) Mux_wreg_sw (wreg_sw,opcode,2'b0,{
    7'b0110111,2'b01,           //lui
    7'b1101111,2'b10,           //jal
    7'b1100111,2'b10,           //jalr
    7'b0000011,2'b11            //lb,lh,lw,lbu,lhu
}
);
//pc_sw
//00 pc+4
//01 exu_out
//10 branch
MuxKeyWithDefault #(3,7,2) Mux_pc_sw (pc_sw,opcode,2'b0,{
    7'b1101111,2'b01,           //jal
    7'b1100111,2'b01,           //jalr
    7'b1100011,2'b10            //beq,bne,blt.bge,bltu,bgeu
});
//mem_valid
MuxKeyWithDefault #(2,7,1) Mux_mem_valid (mem_valid,opcode,1'b0,{
    7'b0100011,1'b1,            //sb,sh,sw
    7'b0000011,1'b1             //lb,lh,lw,lbu,lhu
});
//mem_wen
MuxKeyWithDefault #(1,7,1) Mux_mem_wen (mem_wen,opcode,1'b0,{
    7'b0100011,1'b1             //sb,sh,sw
});
//mem_wmask
MuxKeyWithDefault #(3,10,8) Mux_mem_wmask (mem_wmask,{func3,opcode},8'b0,{
    10'b0000100011,8'b00000001, //sb
    10'b0010100011,8'b00000011, //sh
    10'b0100100011,8'b00001111  //sw
});
//mem_wreg
MuxKeyWithDefault #(5,10,32) Mux_mem_wreg (mem_wreg,{func3,opcode},32'b0,{
    10'b0000000011,{{24{mem_rdata[7]}},mem_rdata[7:0]},     //lb
    10'b0010000011,{{16{mem_rdata[15]}},mem_rdata[15:0]},   //lh
    10'b0100000011,mem_rdata,                               //lw
    10'b1000000011,{24'b0,mem_rdata[7:0]},                  //lbu
    10'b1010000011,{16'b0,mem_rdata[15:0]}                  //lhu
});     
endmodule
