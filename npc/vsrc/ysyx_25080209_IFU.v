module ysyx_25080209_IFU #(ADDR_WID = 32,DATA_WID = 32)(
    input clk,rst,
    input [DATA_WID-1:0]pc_next,
    output reg [DATA_WID-1:0]ins,snpc,pc,

    input IDU_ready,
    output IFU_valid
);
//0 fetching
//1 wait ready
wire IFU_state;
reg IFU_renew;
assign IFU_state = SRAM_fin;
assign IFU_valid = SRAM_fin;
always @(*) begin
    case (IFU_state)
        0:IFU_renew = 0;
        1:if(IDU_ready) IFU_renew = 1;
        else IFU_renew = 0;
        default;
    endcase
end
//SRAM工作信号
wire SRAM_work,SRAM_fin,SRAM_res;
assign SRAM_work = (IFU_state == 0) && (AR_vtime == 0);
assign SRAM_fin = RVALID;
assign SRAM_res = (IFU_renew == 1) && (R_rtime == 0);
//PC写信号
wire PC_wen;
assign PC_wen = (IFU_renew == 1) && (R_rtime == 0);

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

//AXI SRAM 主 使用米利状态机
//raddr
//0 wait addr
//1 wait ready
reg AR_state,nAR_state;
//rdata
//0 wait valid
//1 wait work
reg R_state,nR_state;
always @(posedge ACLK) begin
    if(!ARESETn) begin
        AR_state <= 1'b0;R_state <= 1'b0; 
    end 
    else begin
        AR_state <= nAR_state;R_state <= nR_state;
    end 
end
always @(*) begin
    case (AR_state)
    1'b0:if(SRAM_work) nAR_state = 1;
    else nAR_state = 0;
    1'b1:if(ARREADY) nAR_state = 0;
    else nAR_state = 1;
    endcase
    case (R_state)
    1'b0:if(RVALID) nR_state = 1;
    else nR_state = 0;
    1'b1:if(SRAM_res) nR_state = 0;
    else nR_state = 1;
    endcase
end
always @(*) begin
    case (AR_state)
    1'b0:if(SRAM_work) ARVALID = 1;
    else ARVALID = 0;
    1'b1:if(SRAM_work) ARVALID = 1;
    else ARVALID = 0;
    endcase
    case (R_state)
    1'b0:if(SRAM_res) RREADY = 1;
    else RREADY = 0;
    1'b1:if(SRAM_res) RREADY = 1;
    else RREADY = 0;
    endcase
end
wire [ADDR_WID-1:0]ARADDR;
wire [DATA_WID-1:0]RDATA;
wire ACLK,ARESETn,AWREADY,WREADY,BVALID,ARREADY,RVALID;
reg ARVALID,RREADY;
wire [1:0]BRESP,RRESP;
assign ACLK = clk;
assign ARESETn = ~rst;
assign ARADDR = pc;
assign ins = RDATA;
SRAM_AXI IFU_SRAM_AXI(
    .ACLK    	(ACLK),.ARESETn 	(ARESETn),
    .AWADDR  	(0),.AWVALID 	(0),.AWREADY 	(AWREADY),
    .WDATA   	(0),.WSTRB   	(0),.WVALID  	(0),.WREADY  	(WREADY),
    .BREADY  	(0),.BRESP   	(BRESP),.BVALID  	(BVALID),
    .ARADDR  	(ARADDR   ),
    .ARVALID 	(ARVALID  ),
    .ARREADY 	(ARREADY  ),
    .RDATA   	(RDATA    ),
    .RRESP   	(RRESP    ),
    .RREADY  	(RREADY   ),
    .RVALID  	(RVALID   )
);
//
import "DPI-C" function void itrace(int ins);
always @(posedge clk) begin
    itrace(ins);
end
//PC
always @(posedge clk) begin
    if(rst) pc <= 32'h80000000;
    else begin
        if(PC_wen)  pc <= pc_next;
    end
end

import "DPI-C" function void read_reg(int val,int num);
always @(*) begin
    read_reg(pc,32);
end

assign snpc = pc + 32'h4;
endmodule
