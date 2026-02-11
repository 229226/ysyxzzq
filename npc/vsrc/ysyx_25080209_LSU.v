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
//0 wait valid
//1 wait SRAM and ready
//2 wait ready
reg [1:0]LSU_state,nLSU_state;
wire LSU_work;
assign LSU_work = LSU_ren | LSU_wen;
always @(posedge clk) begin
    if(rst) LSU_state <= 0;
    else LSU_state <= nLSU_state;
end
always @(*) begin
  case (LSU_state)
    0:if(EXU_valid)
          if(LSU_work == 0) nLSU_state = 2;
          else nLSU_state = 1;
        else  nLSU_state = 0;
    1:if(SRAM_rfini || SRAM_wfini)
          if(WBU_ready) nLSU_state = 0;
          else nLSU_state = 2;
        else nLSU_state = 1;
    2:if(WBU_ready) nLSU_state = 0;
      else nLSU_state = 2;
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
        if(SRAM_rfini || SRAM_wfini) begin
          LSU_valid = 1;
          if(WBU_ready) LSU_ready = 1;
          else LSU_ready = 0;
        end 
        else begin
          LSU_valid = 0;
          LSU_ready = 0;
        end 
    end 
    2:begin
        if(EXU_valid) LSU_valid = 1;
        else LSU_valid = 0;
        if(WBU_ready) LSU_ready = 1;
        else LSU_ready = 0;
    end
    default;
  endcase
end
//SRAM控制信号
wire SRAM_ren,SRAM_awen,SRAM_wen,SRAM_rfini,SRAM_wfini,SRAM_wres,SRAM_rres;
assign SRAM_ren = (LSU_state == 0)&&LSU_ren&&(AR_vtime==0);
assign SRAM_awen = (LSU_state == 0)&&LSU_wen&&(AW_vtime==0);
assign SRAM_wen = (LSU_state == 0)&&LSU_wen&&(W_vtime==0);
assign SRAM_rfini = RVALID;
assign SRAM_wfini = BVALID;
assign SRAM_wres = B_rtime==0;
assign SRAM_rres = R_rtime==0;
//LSFR测试
wire [4:0]AR_vt_init,AW_vt_init,W_vt_init,R_rt_init,B_rt_init;
LSFR AR_LSFR(.clk(clk),.rst(rst),.data(AR_vt_init  ));
LSFR AW_LSFR(.clk(clk),.rst(rst),.data(AW_vt_init  ));
LSFR W_LSFR(.clk(clk),.rst(rst),.data(W_vt_init  ));
LSFR R_LSFR(.clk(clk),.rst(rst),.data(R_rt_init  ));
LSFR B_LSFR(.clk(clk),.rst(rst),.data(B_rt_init  ));
reg [4:0]AR_vtime,AW_vtime,W_vtime,R_rtime,B_rtime;
always @(posedge clk) begin
    if(rst)begin
        AR_vtime<=AR_vt_init;AW_vtime<=AW_vt_init;W_vtime<=W_vt_init;
        R_rtime<=R_rt_init;B_rtime<=B_rt_init;
    end
    else begin
        if(AR_vtime!=0)AR_vtime<=AR_vtime-1;else begin AR_vtime<=AR_vt_init;end
        if(AW_vtime!=0)AW_vtime<=AW_vtime-1;else begin AW_vtime<=AW_vt_init;end
        if(W_vtime!=0)W_vtime<=W_vtime-1;else begin W_vtime<=W_vt_init;end
        if(R_rtime!=0)R_rtime<=R_rtime-1;else begin R_rtime<=R_rt_init;end
        if(B_rtime!=0)B_rtime<=B_rtime-1;else begin B_rtime<=B_rt_init;end
    end
end
//LOAD data
MuxKeyWithDefault #(5,3,32) Mux_mem_wreg (rdata_out,rmask,32'b0,{
    3'b001,{{24{rdata[7]}},rdata[7:0]},     //lb
    3'b010,{{16{rdata[15]}},rdata[15:0]},   //lh
    3'b011,rdata,                               //lw
    3'b100,{24'b0,rdata[7:0]},                  //lbu
    3'b101,{16'b0,rdata[15:0]}                  //lhu
});
wire [DATA_WID-1:0]rdata;
//AXI SRAM 主 使用米利状态机
//waddr 
//0 idle
//1 wait ready
reg AW_state,nAW_state;
//wdata
//0 idle
//1 wait ready
reg W_state,nW_state;
//wres
//0 wait valid
//1 wait work
reg B_state,nB_state;
//raddr
//0 idle
//1 wait ready
reg AR_state,nAR_state;
//rdata
//0 wait valid
//1 wait work
reg R_state,nR_state;
always @(posedge ACLK) begin
    if(!ARESETn) begin
        AW_state <= 1'b0;W_state <= 1'b0;B_state <= 1'b0;
        AR_state <= 1'b0;R_state <= 1'b0; 
    end 
    else begin
        AW_state <= nAW_state;W_state <= nW_state;B_state <= nB_state;
        AR_state <= nAR_state;R_state <= nR_state;
    end 
end
always @(*) begin
    case (AW_state)
    1'b0:if(SRAM_awen) nAW_state = 1;
    else nAW_state = 0;
    1'b1:if(AWREADY) nAW_state = 0;
    else nAW_state = 1;
    endcase
    case (W_state)
    1'b0:if(SRAM_wen) nW_state = 1;
    else nW_state = 0;
    1'b1:if(WREADY) nW_state = 0;
    else nW_state = 1;
    endcase
    case (B_state)
    1'b0:if(BVALID) nB_state = 1;
    else nB_state = 0;
    1'b1:if(SRAM_wres)nB_state = 0;
    else nB_state = 1;
    endcase
    case (AR_state)
    1'b0:if(SRAM_ren) nAR_state = 1;
    else nAR_state = 0;
    1'b1:if(ARREADY) nAR_state = 0;
    else nAR_state = 1;
    endcase
    case (R_state)
    1'b0:if(RVALID) nR_state = 1;
    else nR_state = 0;
    1'b1:if(SRAM_rres)nR_state = 0;
    else nR_state = 1;
    endcase
end
always @(*) begin
    case (AW_state)
    1'b0:if(SRAM_awen) AWVALID = 1;
    else AWVALID = 0;
    1'b1:AWVALID = 0;
    endcase
    case (W_state)
    1'b0:if(SRAM_wen) WVALID = 1;
    else WVALID = 0;
    1'b1:WVALID = 0;
    endcase
    case (B_state)
    1'b0:if(SRAM_wres)BREADY = 1;
    else BREADY = 0;
    1'b1:BREADY = 0;
    endcase
    case (AR_state)
    1'b0:if(SRAM_ren) ARVALID = 1;
    else ARVALID = 0;
    1'b1:ARVALID = 0;
    endcase
    case (R_state)
    1'b0:if(SRAM_rres)RREADY = 1;
    else RREADY = 0;
    1'b1:RREADY = 0;
    endcase
end
reg AWVALID,WVALID,BREADY,ARVALID,RREADY;
wire ACLK,ARESETn,AWREADY,WREADY,BVALID,ARREADY,RVALID;
wire [1:0]BRESP,RRESP;
wire [ADDR_WID-1:0] AWADDR,ARADDR;
wire [DATA_WID-1:0] WDATA,RDATA;
wire [3:0]WSTRB;
assign ACLK = clk;
assign ARESETn = ~rst;
assign AWADDR = waddr;
assign WDATA = wdata;
assign WSTRB = wmask;
assign ARADDR = raddr;
assign rdata = RDATA;
SRAM_AXI LSU_SRAM_AXI(
  .ACLK    	(ACLK     ),
  .ARESETn 	(ARESETn  ),
  .AWADDR  	(AWADDR   ),
  .AWVALID 	(AWVALID  ),
  .AWREADY 	(AWREADY  ),
  .WDATA   	(WDATA    ),
  .WSTRB   	(WSTRB    ),
  .WVALID  	(WVALID   ),
  .WREADY  	(WREADY   ),
  .BREADY  	(BREADY   ),
  .BRESP   	(BRESP    ),
  .BVALID  	(BVALID   ),
  .ARADDR  	(ARADDR   ),
  .ARVALID 	(ARVALID  ),
  .ARREADY 	(ARREADY  ),
  .RDATA   	(RDATA    ),
  .RRESP   	(RRESP    ),
  .RREADY  	(RREADY   ),
  .RVALID  	(RVALID   )
);

assign	LSU_reg_wen = EXU_reg_wen;
assign	LSU_csr_wen = EXU_csr_wen;
assign	LSU_csr_ren = EXU_csr_ren;
endmodule
