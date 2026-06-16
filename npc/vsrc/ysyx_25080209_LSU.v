module ysyx_25080209_LSU#(ADDR_WID = 32,DATA_WID = 32)(
  input clk,rst,
  input LSU_ren,LSU_wen,
  input [ADDR_WID-1:0]raddr,waddr,
  input [DATA_WID-1:0]wdata,
  input [3:0]wmask,
  input [2:0]rmask,
  input [ADDR_WID-1:0]EXU_npc,
  output reg [ADDR_WID-1:0]LSU_npc,
  output reg [DATA_WID-1:0]rdata_out,
  //中转信号
  input   EXU_reg_wen,EXU_csr_wen,EXU_csr_ren,
  output  LSU_reg_wen,LSU_csr_wen,LSU_csr_ren,
  //LSUstate
  input EXU_valid,WBU_ready,
  output reg LSU_ready,LSU_valid,

//AXI4接口
  input 		io_master_awready,
  output 		io_master_awvalid,
  output 	[31:0] 	io_master_awaddr,
  output 	[3:0] 	io_master_awid,
  output 	[7:0] 	io_master_awlen,
  output 	[2:0] 	io_master_awsize,
  output 	[1:0] 	io_master_awburst,
  input 		io_master_wready,
  output 		io_master_wvalid,
  output 	[31:0] 	io_master_wdata,
  output 	[3:0] 	io_master_wstrb,
  output 		io_master_wlast,
  output 		io_master_bready,
  input 		io_master_bvalid,
  input 	[1:0] 	io_master_bresp,
  input 	[3:0] 	io_master_bid,
  input 		io_master_arready,
  output 		io_master_arvalid,
  output 	[31:0] 	io_master_araddr,
  output 	[3:0] 	io_master_arid,
  output 	[7:0] 	io_master_arlen,
  output 	[2:0] 	io_master_arsize,
  output 	[1:0] 	io_master_arburst,
  output 		io_master_rready,
  input 		io_master_rvalid,
  input 	[1:0] 	io_master_rresp,
  input 	[31:0] 	io_master_rdata,
  input 		io_master_rlast,
  input 	[3:0] 	io_master_rid
);
//LSUstate
  //0 wait EXU valid
  //1 wait SRAM and ready
  //2 wait WBU ready
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
      1:if(R_fin || W_fin)
            if(WBU_ready) nLSU_state = 0;
            else nLSU_state = 2;
          else nLSU_state = 1;
      2:if(WBU_ready) nLSU_state = 0;
        else nLSU_state = 2;
      default:nLSU_state = 0;
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
          if(R_fin || W_fin) begin
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
          LSU_valid = 1;
          if(WBU_ready) LSU_ready = 1;
          else LSU_ready = 0;
      end
      default:begin LSU_valid=0;LSU_ready=0; end
    endcase
  end
//slave控制信号
  wire R_en,AW_en,W_en,R_fin,W_fin,W_res,R_res;
  assign R_en = (LSU_state == 0)&&LSU_ren&&(AR_wtime==0);
  assign AW_en = (LSU_state == 0)&&LSU_wen&&(AW_wtime==0);
  assign W_en = (LSU_state == 0)&&LSU_wen&&(W_wtime==0);
  assign R_fin = io_master_rvalid&&io_master_rready;
  assign W_fin = (io_master_awvalid&&io_master_awready)
                  &&(io_master_wvalid&&io_master_wready);
  assign W_res = B_rtime==0;
  assign R_res = R_rtime==0;
//LSFR测试
  wire [4:0]AR_wt_init,AW_wt_init,W_wt_init,R_rt_init,B_rt_init;
  assign AR_wt_init = 0;
  assign AW_wt_init = 0;
  assign W_wt_init = 0;
  assign R_rt_init = 0;
  assign B_rt_init = 0;
  // ysyx_25080209_LSFR AR_LSFR(.clk(clk),.rst(rst),.data(AR_wt_init  ));
  // ysyx_25080209_LSFR AW_LSFR(.clk(clk),.rst(rst),.data(AW_wt_init  ));
  // ysyx_25080209_LSFR W_LSFR(.clk(clk),.rst(rst),.data(W_wt_init  ));
  // ysyx_25080209_LSFR R_LSFR(.clk(clk),.rst(rst),.data(R_rt_init  ));
  // ysyx_25080209_LSFR B_LSFR(.clk(clk),.rst(rst),.data(B_rt_init  ));
  reg [4:0]AR_wtime,AW_wtime,W_wtime,R_rtime,B_rtime;
  always @(posedge clk) begin
      if(rst)begin
          AR_wtime<=AR_wt_init;AW_wtime<=AW_wt_init;W_wtime<=W_wt_init;
          R_rtime<=R_rt_init;B_rtime<=B_rt_init;
      end
      else begin
          if(AR_wtime!=0)AR_wtime<=AR_wtime-1;else begin AR_wtime<=AR_wt_init;end
          if(AW_wtime!=0)AW_wtime<=AW_wtime-1;else begin AW_wtime<=AW_wt_init;end
          if(W_wtime!=0)W_wtime<=W_wtime-1;else begin W_wtime<=W_wt_init;end
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
  reg [DATA_WID-1:0]rdata;
//AXI SRAM 主 使用米利状态机
  //waddr 
  //0 wait addr
  //1 wait ready
  reg AW_state,nAW_state;
  //wdata
  //0 wait wdata
  //1 wait ready
  reg W_state,nW_state;
  //wres
  //W_res==1 > bready==1;
  //raddr
  //0 wait addr
  //1 wait ready
  reg AR_state,nAR_state;
  //rdata
  //R_res==1 > rready==1;
  always @(posedge clk) begin
      if(rst) begin
          AW_state <= 1'b0;W_state <= 1'b0;
          AR_state <= 1'b0;
      end 
      else begin
          AW_state <= nAW_state;W_state <= nW_state;
          AR_state <= nAR_state;
      end 
  end
  always @(*) begin
      case (AW_state)
      1'b0:if(AW_en) nAW_state = 1;
      else nAW_state = 0;
      1'b1:if(io_master_awready) nAW_state = 0;
      else nAW_state = 1;
      endcase
      case (W_state)
      1'b0:if(W_en) nW_state = 1;
      else nW_state = 0;
      1'b1:if(io_master_wready) nW_state = 0;
      else nW_state = 1;
      endcase
      case (AR_state)
      1'b0:if(R_en) nAR_state = 1;
      else nAR_state = 0;
      1'b1:if(io_master_arready) nAR_state = 0;
      else nAR_state = 1;
      endcase
  end
  always @(*) begin
      case (AW_state)
      1'b0:io_master_awvalid = 0;
      1'b1:io_master_awvalid = 1;
      endcase
      case (W_state)
      1'b0:io_master_wvalid = 0;
      1'b1:io_master_wvalid = 1;
      endcase
      if(W_res)io_master_bready = 1;
      else io_master_bready = 0;
      case (AR_state)
      1'b0:io_master_arvalid = 0;
      1'b1:io_master_arvalid = 1;
      endcase
      if(R_res)io_master_rready = 1;
      else io_master_rready = 0;
  end
//AXI4接口信号
  reg [DATA_WID-1:0]AXI4_wdata;
  reg [3:0]AXI4_strb;
  wire [DATA_WID-1:0]AXI4_rdata;
  always@(*) begin
    AXI4_wdata = 0;
    AXI4_strb = 0;
    case(wmask)
    4'b0001:begin
      case(waddr[1:0])
      2'b00:begin
        AXI4_wdata = {24'b0,wdata[7:0]};
        AXI4_strb = 4'b0001;
      end 
      2'b01:begin
        AXI4_wdata = {16'b0,wdata[7:0],8'b0};
        AXI4_strb = 4'b0010;
      end 
      2'b10:begin
        AXI4_wdata = {8'b0,wdata[7:0],16'b0};
        AXI4_strb = 4'b0100;
      end 
      2'b11:begin
        AXI4_wdata = {wdata[7:0],24'b0};
        AXI4_strb = 4'b1000;
      end 
      endcase
    end
    4'b0011:begin
      case(waddr[1:0])
      2'b00:begin
        AXI4_wdata = {16'b0,wdata[15:0]};
        AXI4_strb = 4'b0011;
      end 
      2'b01:begin
        AXI4_wdata = {8'b0,wdata[15:0],8'b0};
        AXI4_strb = 4'b0110;
      end 
      2'b10:begin
        AXI4_wdata = {wdata[15:0],16'b0};
        AXI4_strb = 4'b1100;
      end 
      2'b11:begin
        AXI4_wdata = {wdata[7:0],24'b0};
        AXI4_strb = 4'b1000;
      end 
      endcase
    end
    4'b1111:begin
      case(waddr[1:0])
      2'b00:begin
        AXI4_wdata = wdata;
        AXI4_strb = 4'b1111;
      end 
      2'b01:begin
        AXI4_wdata = {wdata[23:0],8'b0};
        AXI4_strb = 4'b1110;
      end 
      2'b10:begin
        AXI4_wdata = {wdata[15:0],16'b0};
        AXI4_strb = 4'b1100;
      end 
      2'b11:begin
        AXI4_wdata = {wdata[7:0],24'b0};
        AXI4_strb = 4'b1000;
      end 
      endcase
    end
    default:AXI4_wdata = 0;
    endcase
    case(rmask)
    3'b001:begin
      case(waddr[1:0])
      2'b00:rdata = {24'b0,AXI4_rdata[7:0]};
      2'b01:rdata = {24'b0,AXI4_rdata[15:8]};
      2'b10:rdata = {24'b0,AXI4_rdata[23:16]};
      2'b11:rdata = {24'b0,AXI4_rdata[31:24]};
      endcase
    end
    3'b010:begin
      case(waddr[1:0])
      2'b00:rdata = {16'b0,AXI4_rdata[15:0]};
      2'b01:rdata = {16'b0,AXI4_rdata[23:8]};
      2'b10:rdata = {16'b0,AXI4_rdata[31:16]};
      2'b11:rdata = {24'b0,AXI4_rdata[31:24]};
      endcase
    end
    3'b011:begin
      case(waddr[1:0])
      2'b00:rdata = AXI4_rdata;
      2'b01:rdata = {8'b0,AXI4_rdata[31:8]};
      2'b10:rdata = {16'b0,AXI4_rdata[31:16]};
      2'b11:rdata = {24'b0,AXI4_rdata[31:24]};
      endcase
    end
    3'b100:begin
      case(waddr[1:0])
      2'b00:rdata = {24'b0,AXI4_rdata[7:0]};
      2'b01:rdata = {24'b0,AXI4_rdata[15:8]};
      2'b10:rdata = {24'b0,AXI4_rdata[23:16]};
      2'b11:rdata = {24'b0,AXI4_rdata[31:24]};
      endcase
    end
    3'b101:begin
      case(waddr[1:0])
      2'b00:rdata = {16'b0,AXI4_rdata[15:0]};
      2'b01:rdata = {16'b0,AXI4_rdata[23:8]};
      2'b10:rdata = {16'b0,AXI4_rdata[31:16]};
      2'b11:rdata = {24'b0,AXI4_rdata[31:24]};
      endcase
    end
    default:rdata = 0;
    endcase
  end

  reg [2:0] awsize,arsize;
  always @(*) begin
    awsize = 0;
    arsize = 0;
    case(wmask)
    4'b0001:awsize = 3'b000;
    4'b0011:awsize = 3'b001;
    4'b1111:awsize = 3'b010;
    default:awsize = 3'b000;
    endcase
    case(rmask)
    3'b001:arsize = 3'b000;
    3'b010:arsize = 3'b001;
    3'b011:arsize = 3'b010;
    3'b100:arsize = 3'b000;
    3'b101:arsize = 3'b001;
    default:arsize = 3'b000;
    endcase
  end
  assign io_master_awaddr = waddr&32'hfffffffC;
  assign io_master_awsize = awsize;
  assign io_master_awburst = 2'b01;
  assign io_master_wlast = 1;

  assign io_master_wdata = AXI4_wdata;
  assign io_master_wstrb = AXI4_strb;

  assign io_master_araddr = raddr&32'hfffffffC;
  assign io_master_arsize = arsize;
  assign io_master_arburst = 2'b01;

  assign AXI4_rdata = io_master_rdata;

  assign io_master_awid = 0;
  assign io_master_awlen = 0;
  assign io_master_arid = 0;
  assign io_master_arlen = 0;
//AXI4读写反馈处理
  reg [1:0]bresp,rresp;
  always @(posedge clk) begin
    if(rst)begin
      bresp <= 0;
      rresp <= 0;
    end
    else if(io_master_bvalid) bresp <= io_master_bresp;
    else if(io_master_rvalid) rresp <= io_master_rresp;
  end
  always @(*) begin
    if((bresp!=0)||(rresp!=0)) LSU_npc = 0;
    else LSU_npc = EXU_npc;
  end

assign	LSU_reg_wen = EXU_reg_wen;
assign	LSU_csr_wen = EXU_csr_wen;
assign	LSU_csr_ren = EXU_csr_ren;
endmodule
