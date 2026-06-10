module ysyx_25080209_IFU #(ADDR_WID = 32,DATA_WID = 32)(
    input clk,rst,
    input [DATA_WID-1:0]pc_next,
    output reg [DATA_WID-1:0]ins,snpc,pc,

    input IDU_ready,
    output IFU_valid,

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
//IFU状态机
    //0 idle
    //1 wait sram and IDU
    //2 wait IDU
    reg [1:0]IFU_state,nIFU_state;
    always @(posedge clk) begin
        if(rst) IFU_state <= 0;
        else IFU_state <= nIFU_state;
    end
    always @(*) begin
        case (IFU_state)
        0:nIFU_state = 1;
        1:if(R_fin) begin
            if(IDU_ready) nIFU_state = 0;
            else nIFU_state = 2;
        end
        else nIFU_state = 1;
        2:if(IDU_ready) nIFU_state = 0;
        else nIFU_state = 2;
        default:nIFU_state = 0;
        endcase
    end
    always @(*) begin
        case (IFU_state)
        0:begin IFU_valid=0;ins=ins_old; end
        1:if(R_fin) begin IFU_valid=1;ins=ins_new; end
        else begin IFU_valid=0;ins=ins_old; end
        2:begin IFU_valid=1;ins=ins_old; end
        default:begin IFU_valid=0;ins=ins_old; end
        endcase
    end
//控制ins无延迟输出与缓存
    wire [DATA_WID-1:0]ins_new;
    reg [DATA_WID-1:0]ins_old;
    always @(posedge clk) begin
        if(rst) ins_old <= 0;
        else if(R_fin) ins_old <= ins_new;
        else ins_old <= ins_old;
    end
//AXI4 slave工作信号
    wire AR_work,R_fin,R_res;
    assign AR_work = (IFU_state==0) || ((IFU_state==1)&&(nIFU_state==0)) || 
                        ((IFU_state==2)&&(nIFU_state==0));
    assign R_res = R_rtime == 0;
    assign R_fin = io_master_rvalid&&io_master_rready;
//PC写信号
    wire PC_wen;
    assign PC_wen =  ((IFU_state==1)&&(nIFU_state==0)) || 
                        ((IFU_state==2)&&(nIFU_state==0));
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
            if(AR_wtime!=5'b0)AR_wtime<=AR_wtime-1;else begin AR_wtime<=AR_wt_init;end
            if(AW_wtime!=5'b0)AW_wtime<=AW_wtime-1;else begin AW_wtime<=AW_wt_init;end
            if(W_wtime!=5'b0)W_wtime<=W_wtime-1;else begin W_wtime<=W_wt_init;end
            if(R_rtime!=5'b0)R_rtime<=R_rtime-1;else begin R_rtime<=R_rt_init;end
            if(B_rtime!=5'b0)B_rtime<=B_rtime-1;else begin B_rtime<=B_rt_init;end
        end
    end
//AXI4 master
    //raddr
    //0 wait addr
    //1 wait ready
    reg AR_state,nAR_state;
    //rdata
    //R_res==1 > rready==1;
    always @(posedge clk) begin
        if(rst) begin
            AR_state <= 1'b0;
        end 
        else 
        begin
            AR_state <= nAR_state;
        end 
    end
    always @(*) begin
        case (AR_state)
        1'b0:if(AR_work) nAR_state = 1;
        else nAR_state = 0;
        1'b1:if(io_master_arready) nAR_state = 0;
        else nAR_state = 1;
        endcase
    end
    always @(*) begin
        case (AR_state)
        1'b0:io_master_arvalid = 0;
        1'b1:io_master_arvalid = 1;
        endcase
        if(R_res)io_master_rready = 1;
        else io_master_rready = 0;
    end
    assign io_master_araddr = pc;
    assign io_master_arsize = 3'b010;
    assign io_master_arburst = 2'b01;

    assign ins_new = io_master_rdata;

    assign io_master_awvalid = 0;
    assign io_master_awaddr = 0;
    assign io_master_awid = 0;
    assign io_master_awlen = 0;
    assign io_master_awsize = 0;
    assign io_master_awburst = 0;
    assign io_master_wvalid = 0;
    assign io_master_wdata = 0;
    assign io_master_wstrb = 0;
    assign io_master_wlast = 0;
    assign io_master_bready = 0;
    assign io_master_arvalid = 0;
    assign io_master_araddr = 0;
    assign io_master_arid = 0;
    assign io_master_arlen = 0;
    assign io_master_rready = 0;
//itrace
    import "DPI-C" function void itrace(int ins);
    always @(posedge clk) begin
        itrace(ins);
    end
//PC
    always @(posedge clk) begin
        if(rst) pc <= 32'h2000_0000;
        else begin
            if(PC_wen)  pc <= pc_next;
        end
    end
    import "DPI-C" function void read_reg(int val,int num);
    always @(*) begin
        read_reg(pc,32);
    end
    assign snpc = pc + 32'h4;
//diff_test
import "DPI-C" function void ins_state(int state);
always @(posedge clk) begin
    if(PC_wen) ins_state(1); //finished
    else ins_state(0);       //running
end
endmodule
