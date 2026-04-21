(* keep_hierarchy = "yes" *)  // 保持模块层次结构
module  ysyx_25080209_SRAM_AXI #(ADDR_WID = 32,DATA_WID = 32) (
    //AXI
    input ACLK,ARESETn,
    //waddr
    input [ADDR_WID-1:0]AWADDR,
    //input [2:0]AWPROT,
    input AWVALID,
    output reg AWREADY,
    //wdata
    input [DATA_WID-1:0]WDATA,
    input [3:0]WSTRB,
    input WVALID,
    output reg WREADY,
    //wresponse
    input BREADY,
    output [1:0]BRESP,
    output BVALID,
    //raddr
    input [ADDR_WID-1:0]ARADDR,
    //input [2:0]ARPROT,
    input ARVALID,
    output ARREADY,
    //rdata
    output reg [DATA_WID-1:0]RDATA,
    output [1:0]RRESP,
    input RREADY,
    output RVALID
);
//AXI4-lite 从 
//米利状态机
    //waddr 
        //0 wait valid
        //1 wait work
        reg AW_state,nAW_state;
    //wdata
        //0 wait valid
        //1 wait work
        reg W_state,nW_state;
    //wres
        //00 wait wdata
        //01 wait sram and ready
        //10 wait ready
        reg [1:0]B_state,nB_state;
    //raddr
        //0 wait valid
        //1 wait work
        reg AR_state,nAR_state;
    //rdata
        //00 wait raddr
        //01 wait sram and ready
        //10 wait ready
        reg [1:0]R_state,nR_state;
    always @(posedge ACLK) begin
        if(!ARESETn) begin
            AW_state <= 1'b0;W_state <= 1'b0;B_state <= 2'b0;
            AR_state <= 1'b0;R_state <= 2'b0; 
        end 
        else begin
            AW_state <= nAW_state;W_state <= nW_state;B_state <= nB_state;
            AR_state <= nAR_state;R_state <= nR_state;
        end 
    end
    always @(*) begin
        case (AW_state)
            0:if(AWVALID) nAW_state = 1;
            else nAW_state = 0;
            1:if(SRAM_wfini) nAW_state = 0;
            else nAW_state = 1;
            default:nAW_state = 0;
        endcase
        case (W_state)
            0:if(WVALID) nW_state = 1;
            else nW_state = 0;
            1:if(SRAM_wfini) nW_state = 0;
            else nW_state = 1;
            default:nAW_state = 0;
        endcase
        case (B_state)
            2'b00:if((AW_state==1)&(W_state==1))
                    nB_state = 2'b01; 
                else nB_state = 2'b00;
            2'b01:if(SRAM_wfini)
                    if(BREADY) nB_state = 2'b00;
                    else nB_state = 2'b10;
                else nB_state = 2'b01;
            2'b10:if(BREADY) nB_state = 2'b00;
                    else nB_state = 2'b10;
            default:nB_state = 2'b00;
        endcase
        case (AR_state)
            1'b0:begin 
                if(ARVALID) nAR_state = 1'b1;
                else nAR_state = 1'b0;
            end 
            1'b1:nAR_state = 1'b0;
        endcase
        case (R_state)
            2'b00:begin
                if(ARVALID && ARREADY) begin
                    nR_state = 2'b01;
                end
                else nR_state = 2'b00;
            end
            2'b01:if(SRAM_rfini)
                    if(RREADY) nR_state = 2'b00;
                    else nR_state = 2'b10;
                else nR_state = 2'b01;
            2'b10:if(RREADY) nR_state = 2'b00;
                    else nR_state = 2'b10;
            default:nR_state = 2'b00;
        endcase
    end
    always @(*) begin
        case (AW_state)
            0:AWREADY=1;
            1:AWREADY=0;
            default:AWREADY=0;
        endcase
        case (W_state)
            0:WREADY = 1;
            1:WREADY = 0;
            default:WREADY = 0;
        endcase
        case (B_state)
            2'b00:begin 
                BVALID = 0;
                BRESP = 2'b0;
            end
            2'b01:begin
                if(SRAM_wfini) BVALID = 1;
                else BVALID = 0;
                BRESP = 2'b0;
            end
            2'b10:begin
                BVALID = 1;
                BRESP = 2'b0;
            end
            default:begin
                BVALID = 0;
                BRESP = 2'b0;
            end 
        endcase
        case (AR_state)
            1'b0:begin
                ARREADY = 1;
            end
            1'b1:begin
                ARREADY = 0;
            end
        endcase
        case (R_state)
            2'b00:begin
                RVALID = 0;
                RRESP = 2'b0;
            end
            2'b01:begin
                if(SRAM_rfini) RVALID = 1;
                else RVALID = 0;
                RRESP = 2'b0;
            end
            2'b10:begin
                RVALID = 1;
                RRESP = 2'b0;
            end
            default:begin
                RVALID = 0;
                RRESP = 2'b0;
            end
        endcase
    end
//SRAM
//控制信号
    wire SRAM_wfini,SRAM_rfini;
    assign SRAM_wfini = SRAM_wtime == 0;
    assign SRAM_rfini = SRAM_rtime == 0;
    wire SRAM_wen,SRAM_ren;
    assign SRAM_wen = ((B_state==0)&&(nB_state==1));
    assign SRAM_ren = (R_state == 0) && (nR_state == 1);
    //注:SRAM延迟为SRAM_wt_init/SRAM_rt_init + 1
    wire [4:0]SRAM_wt_init,SRAM_rt_init;
    // assign SRAM_wt_init = 0;
    // assign SRAM_rt_init = 0;
    ysyx_25080209_LSFR SRAM_LSFR1(.clk(ACLK),.rst(!ARESETn),.data(SRAM_wt_init));
    ysyx_25080209_LSFR SRAM_LSFR2(.clk(ACLK),.rst(!ARESETn),.data(SRAM_rt_init));
    reg [4:0] SRAM_wtime,SRAM_rtime;
    wire SRAM_wt_wk,SRAM_rt_wk;
    assign SRAM_wt_wk = ((B_state==0)&&(nB_state==1)) || ((B_state==1)&&(nB_state==1));
    assign SRAM_rt_wk = ((R_state==0)&&(nR_state==1)) || ((R_state==1)&&(nR_state==1));
    always @(posedge ACLK) begin
        if(!ARESETn) begin
            SRAM_wtime <= SRAM_wt_init;SRAM_rtime <= SRAM_rt_init;
        end
        else begin
            if(SRAM_wt_wk) 
                if(SRAM_wtime != 0) SRAM_wtime <= SRAM_wtime - 1;
                else SRAM_wtime <= SRAM_wt_init;
            else SRAM_wtime <= SRAM_wtime;
            if(SRAM_rt_wk)
                if(SRAM_rtime != 0) SRAM_rtime <= SRAM_rtime - 1;
                else SRAM_rtime <= SRAM_rt_init;
            else SRAM_rtime <= SRAM_rtime;
        end
    end
//读写DPI-C
    import "DPI-C" function int pmem_read(input int raddr);
    import "DPI-C" function void pmem_write(
    input int waddr, input int wdata, input byte wmask);
    always @(posedge ACLK) begin
        if(!ARESETn) begin
            RDATA <= 0;
        end 
        else begin
            if(SRAM_ren) RDATA <= pmem_read(ARADDR);
            else RDATA <= RDATA;
        end
        if(SRAM_wen) pmem_write(AWADDR,WDATA,{4'b0000,WSTRB});
    end
//SRAM读写
    // reg [DATA_WID-1:0] SRAM [2**ADDR_WID-1:0];
    // always @(posedge ACLK) begin
    //     if(SRAM_ren) RDATA <= SRAM[ARADDR];
    //     else RDATA <= RDATA;
    //     if(SRAM_wen) SRAM[AWADDR] <= WDATA;
    // end
endmodule
