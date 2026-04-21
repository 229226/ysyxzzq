module ysyx_25080209_IDU#(DATA_WID = 32,RADDR_WID = 4)(
    input clk,rst,
    input [DATA_WID-1:0]IDU_ins,
    //ALU signal
    output [DATA_WID-1:0]imm,         
    output pc_rs1,rs2_imm,
    output reg [3:0]alu_op,   
    //PC signal
    output [1:0]pc_sw,
    //reg signal
    //read reg
    output [RADDR_WID-1:0] reg_raddr1,reg_raddr2,
    //write reg
    output IDU_reg_wen,
    output [RADDR_WID-1:0]reg_waddr,
    output [2:0]wreg_sw,
    //MEM signal
    output mem_ren,mem_wen,
    output [3:0]mem_wmask,
    output [2:0]mem_rmask,
    //CSR signal
    output IDU_csr_wen,IDU_csr_ren,csr_w_sw,
    output [DATA_WID-1:0]csr_zimm,
    //特殊信号
    output ecall,mret,
    //IDUstate
    input IFU_valid,EXU_ready,
    output IDU_ready,IDU_valid
);
//IDUstate
//0 idle
//1 wait_ready
reg IDU_state,nIDU_state;
always @(posedge clk) begin
    if(rst) IDU_state <= 0;
    else IDU_state <= nIDU_state;
end
always @(*) begin
    case (IDU_state)
        0:begin
            if(IFU_valid) nIDU_state = 1;
            else nIDU_state = 0;
        end 
        1:begin
            if(EXU_ready) nIDU_state = 0;
            else nIDU_state = 1;
        end
        default;
    endcase
end
always @(*) begin
    case (IDU_state)
        0:begin
            if(IFU_valid) IDU_valid = 1;
            else IDU_valid = 0;
            if(EXU_ready) IDU_ready = 1;
            else IDU_ready = 0;
        end
        1:begin
            if(IFU_valid) IDU_valid = 1;
            else IDU_valid = 0;
            if(EXU_ready) IDU_ready = 1;
            else IDU_ready = 0;
        end
        default;
    endcase
end
//多周期处理
wire [DATA_WID-1:0] ins;
assign ins = IDU_valid ? IDU_ins : 0;
//
wire [6:0]opcode;
wire [2:0]func3;
assign opcode = ins[6:0];
assign func3 = ins[14:12];

assign reg_raddr1 = ins[15+RADDR_WID-1:15];
assign reg_raddr2 = ins[20+RADDR_WID-1:20];
assign reg_waddr  = ins[7+RADDR_WID-1:7];
//ebreak
import "DPI-C" function void ebreak();
wire status_ebreak;
always @(*) begin
    if(status_ebreak) begin
        ebreak();
    end
end
MuxKeyWithDefault #(1,32,1) Mux_ebreak (status_ebreak,ins,1'b0,{
    32'b000000000001_00000_000_00000_1110011,1'b1   //ebreak
});
//ecall
//0 not ecall
//1 ecall
MuxKeyWithDefault #(1,32,1) Mux_ecall (ecall,ins,1'b0,{
    32'b000000000000_00000_000_00000_1110011,1'b1
});
//mret
//0 not mret
//1 mret
MuxKeyWithDefault #(1,32,1) Mux_mret (mret,ins,1'b0,{
    32'b0011000_00010_00000_000_00000_1110011,1'b1
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
//pc_rs1 determine the alu_in1
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
//imm
wire [DATA_WID-1:0]imm_U = {ins[31:12],{12{1'b0}}};
wire [DATA_WID-1:0]imm_J = {{11{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0};
wire [DATA_WID-1:0]imm_I = {{20{ins[31]}},ins[31:20]};
wire [DATA_WID-1:0]imm_B = {{20{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0};
wire [DATA_WID-1:0]imm_S = {{20{ins[31]}},ins[31:25],ins[11:7]};
MuxKeyWithDefault #(9,7,32) Mux_imm (imm,opcode,32'b0,{
    7'b0110111,imm_U,   //lui
    7'b0010111,imm_U,   //auipc
    7'b1101111,imm_J,   //jal
    7'b1100111,imm_I,   //jalr
    7'b1100011,imm_B,   //beq,bne,blt,bge,bltu,bgeu
    7'b0000011,imm_I,   //lb,lh,lw,lbu,lhu
    7'b0100011,imm_S,   //sb,sh,sw
    7'b0010011,imm_I,   //addi,slti,sltiu,xori,ori,andi,slli,srli,srai
    7'b1110011,imm_I    //csrr
});
//IDU_reg_wen
//0 disable
//1 enable
MuxKeyWithDefault #(8,7,1) Mux_reg_wen (IDU_reg_wen,opcode,1'b0,{
    7'b0110111,1'b1,            //lui
    7'b0010111,1'b1,            //auipc
    7'b1101111,1'b1,            //jal
    7'b1100111,1'b1,            //jalr
    7'b0000011,1'b1,            //lb,lh,lw,lbu,lhu
    //0 sb,sh,sw
    7'b0010011,1'b1,            //addi,slti,sltiu,xori,ori,andi,slli,srli,srai
    7'b0110011,1'b1,            //add,sub,sll,slt,sltu,xor,srl,sra,or,and
    7'b1110011,1'b1             //csrr csrrw的rs1=0的时候由于ren=0读出的CSR=0，写入到X0当中，不会产生侧效应
    }
);
//wreg_sw
//000 write exu_out
//001 write imm 
//010 write snpc
//011 write mem_wreg
//100 write csr
MuxKeyWithDefault #(5,7,3) Mux_wreg_sw (wreg_sw,opcode,3'b0,{
    7'b0110111,3'b001,           //lui
    7'b1101111,3'b010,           //jal
    7'b1100111,3'b010,           //jalr
    7'b0000011,3'b011,           //lb,lh,lw,lbu,lhu
    7'b1110011,3'b100            //csrr
}
);
//pc_sw
//00 pc+4
//01 exu_out
//10 branch
//11 pc=pc
MuxKeyWithDefault #(4,7,2) Mux_pc_sw (pc_sw,opcode,2'b0,{
    7'b1101111,2'b01,           //jal
    7'b1100111,2'b01,           //jalr
    7'b1100011,2'b10,           //beq,bne,blt.bge,bltu,bgeu
    7'b0000000,2'b11            //无效指令
});
//mem_ren
MuxKeyWithDefault #(1,7,1) Mux_mem_valid (mem_ren,opcode,1'b0,{
    7'b0000011,1'b1             //lb,lh,lw,lbu,lhu
});
//mem_wen
MuxKeyWithDefault #(1,7,1) Mux_mem_wen (mem_wen,opcode,1'b0,{
    7'b0100011,1'b1             //sb,sh,sw
});
//mem_wmask
MuxKeyWithDefault #(3,10,4) Mux_mem_wmask (mem_wmask,{func3,opcode},4'b0,{
    10'b0000100011,4'b0001, //sb
    10'b0010100011,4'b0011, //sh
    10'b0100100011,4'b1111  //sw
});
//mem_rmask
//000 not write
//001 write byte
//010 write half word
//011 write word
//100 write unsigned byte
//101 write unsigned half word 
MuxKeyWithDefault #(5,10,3) Mux_mem_wreg (mem_rmask,{func3,opcode},3'b0,{
    10'b000_0000011,3'b001,     //lb
    10'b001_0000011,3'b010,     //lh
    10'b010_0000011,3'b011,     //lw
    10'b100_0000011,3'b100,     //lbu
    10'b101_0000011,3'b101      //lhu
});     
//csr_sc_w
//00 not csr instruction
//01 csrrw
//10 csrrs/c
wire [1:0]csr_sc_w;
//csr_w_sw
//0 write rs1 to csr
//1 write zimm to csr
assign csr_zimm = {{(DATA_WID-5){1'b0}},ins[24:20]};
MuxKeyWithDefault #(6,10,3) Mux_csr_sc_w ({csr_sc_w,csr_w_sw},{func3,opcode},3'b0,{
    10'b001_1110011,3'b01_0,
    10'b010_1110011,3'b10_0,
    10'b011_1110011,3'b10_0,
    10'b101_1110011,3'b01_1,
    10'b110_1110011,3'b10_1,
    10'b111_1110011,3'b10_1
});
//IDU_csr_wen
always @(*) begin
    casez ({reg_raddr1,csr_sc_w})
        6'b????_00:IDU_csr_wen = 1'b0;
        6'b0000_10:IDU_csr_wen = 1'b0;
    default: IDU_csr_wen = 1'b1;
    endcase
end
//IDU_csr_ren
always @(*) begin
    casez ({reg_waddr,csr_sc_w})
        6'b????_00:IDU_csr_ren = 1'b0;
        6'b0000_01:IDU_csr_ren = 1'b0;
    default: IDU_csr_ren = 1'b1;
    endcase
end
endmodule
