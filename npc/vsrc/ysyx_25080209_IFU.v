module ysyx_25080209_IFU #(ADDR_WID = 32,DATA_WID = 32)(
    input clk,rst,
    input [DATA_WID-1:0]pc_next,
    output reg [DATA_WID-1:0]ins,snpc,pc,

    //AXI4_lite接口
    output [ADDR_WID-1:0]AWADDR,ARADDR,
    output AWVALID,WVALID,BREADY,ARVALID,RREADY,
    input AWREADY,WREADY,BVALID,ARREADY,RVALID,
    output [DATA_WID-1:0]WDATA,
    input [DATA_WID-1:0]RDATA,
    output [3:0]WSTRB,
    input [1:0]BRESP,RRESP,

    input IDU_ready,
    output IFU_valid
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
        1:if(SRAM_fin) begin
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
        1:if(SRAM_fin) begin IFU_valid=1;ins=ins_new; end
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
        else if(SRAM_fin) ins_old <= ins_new;
        else ins_old <= ins_old;
    end
//SRAM工作信号
    wire SRAM_work,SRAM_fin,SRAM_res;
    assign SRAM_work = (IFU_state==0) || ((IFU_state==1)&&(nIFU_state==0)) || 
                        ((IFU_state==2)&&(nIFU_state==0));
    assign SRAM_res = R_rtime == 0;
    assign SRAM_fin = RVALID&&RREADY;
//PC写信号
    wire PC_wen;
    assign PC_wen =  ((IFU_state==1)&&(nIFU_state==0)) || 
                        ((IFU_state==2)&&(nIFU_state==0));
//LSFR测试
    wire [4:0]AR_wt_init,AW_wt_init,W_wt_init,R_rt_init,B_rt_init;
    // assign AR_wt_init = 0;
    // assign AW_wt_init = 0;
    // assign W_wt_init = 0;
    // assign R_rt_init = 0;
    // assign B_rt_init = 0;
    ysyx_25080209_LSFR AR_LSFR(.clk(clk),.rst(rst),.data(AR_wt_init  ));
    ysyx_25080209_LSFR AW_LSFR(.clk(clk),.rst(rst),.data(AW_wt_init  ));
    ysyx_25080209_LSFR W_LSFR(.clk(clk),.rst(rst),.data(W_wt_init  ));
    ysyx_25080209_LSFR R_LSFR(.clk(clk),.rst(rst),.data(R_rt_init  ));
    ysyx_25080209_LSFR B_LSFR(.clk(clk),.rst(rst),.data(B_rt_init  ));
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
        1'b1:ARVALID = 1;
        endcase
        case (R_state)
        1'b0:if(SRAM_res) RREADY = 1;
        else RREADY = 0;
        1'b1:if(SRAM_res) RREADY = 1;
        else RREADY = 0;
        endcase
    end
    wire ACLK,ARESETn;
    assign ACLK = clk;
    assign ARESETn = ~rst;
    assign ARADDR = pc;
    assign ins_new = RDATA;
    assign AWADDR = 0;
    assign ARADDR = 0;
    assign AWVALID = 0;
    assign WVALID = 0;
    assign WDATA = 0;
    assign BREADY = 0;
    assign WSTRB = 0;
//itrace
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
