module ysyx_25080209_LSU#(ADDR_WID = 32,DATA_WID = 32)(
  input clk,rst,
  input LSU_ren,LSU_wen,
  input [ADDR_WID-1:0]raddr,waddr,
  input [DATA_WID-1:0]wdata,
  input [3:0]wmask,
  input [2:0]rmask,
  output reg [DATA_WID-1:0]rdata_out,
  //中转信号
  input   EXU_reg_wen,EXU_csr_wen,EXU_csr_ren,
  output  LSU_reg_wen,LSU_csr_wen,LSU_csr_ren,
  //LSUstate
  input EXU_valid,WBU_ready,
  output reg LSU_ready,LSU_valid
);
//LSUstate
//0 idle
//1 wait_ready
reg LSU_state,nLSU_state;
wire LSU_work;
assign LSU_work = LSU_ren | LSU_wen;
always @(posedge clk) begin
    if(rst) LSU_state <= 0;
    else LSU_state <= nLSU_state;
end
always @(*) begin
  case (LSU_state)
    0:begin
        if(EXU_valid) nLSU_state = 1;
        else nLSU_state = 0;
    end 
    1:begin
        if(WBU_ready) nLSU_state = 0;
        else nLSU_state = 1;
    end
    default;
  endcase
end
always @(*) begin
  case (LSU_state)
    0:begin
        if(LSU_work == 0) begin
          if(EXU_valid) LSU_valid = 1;
          else LSU_valid = 0;
          if(WBU_ready) LSU_ready = 1;
          else LSU_ready = 0;
        end 
        else begin
          LSU_valid = 0;
          LSU_ready = 0;
        end
    end
    1:begin
        if(EXU_valid) LSU_valid = 1;
        else LSU_valid = 0;
        if(WBU_ready) LSU_ready = 1;
        else LSU_ready = 0;
    end
    default;
  endcase
end
//LOAD data
MuxKeyWithDefault #(5,3,32) Mux_mem_wreg (rdata_out,rmask,32'b0,{
    3'b001,{{24{rdata[7]}},rdata[7:0]},     //lb
    3'b010,{{16{rdata[15]}},rdata[15:0]},   //lh
    3'b011,rdata,                               //lw
    3'b100,{24'b0,rdata[7:0]},                  //lbu
    3'b101,{16'b0,rdata[15:0]}                  //lhu
});     

reg wen,ren;
always @(*) begin
  if(nLSU_state == 1) begin 
    ren = LSU_ren;wen = LSU_wen;
  end
  else begin
    ren = 0;wen = 0;
  end 
end
wire [DATA_WID-1:0]rdata;
SRAM_LSU u_SRAM_LSU (
  .clk(clk),
  .wen(wen),.ren(ren),
  .wmask(wmask),
  .raddr(raddr),.waddr(waddr),.rdata(rdata),.wdata(wdata)
);

assign	LSU_reg_wen = EXU_reg_wen;
assign	LSU_csr_wen = EXU_csr_wen;
assign	LSU_csr_ren = EXU_csr_ren;

// Mem #(8,32) u_Mem(
//   .clk   	(clk    ),
//   .wdata 	(wdata  ),
//   .waddr 	(waddr[7:0]  ),
//   .raddr 	(raddr[7:0]  ),
//   .wen   	(wen    ),
//   .rdata 	(rdata  )
// );
endmodule
