(* keep_hierarchy = "yes" *)  // 保持模块层次结构
module  ysyx_25080209_UART #(ADDR_WID = 32,DATA_WID = 32) (
    input clk,rst,
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
    always @(posedge clk) begin
        if(rst) begin
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
            1:nAW_state = 0;
            default:nAW_state = 0;
        endcase
        case (W_state)
            0:if(WVALID) nW_state = 1;
            else nW_state = 0;
            1:nW_state = 0;
            default:nAW_state = 0;
        endcase
        case (B_state)
            2'b00:if((AW_state==1)&(W_state==1))
                    nB_state = 2'b01; 
                else nB_state = 2'b00;
            2'b01:if(BREADY) nB_state = 2'b00;
                    else nB_state = 2'b10;
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
            2'b01:if(RREADY) nR_state = 2'b00;
                else nR_state = 2'b10;
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
                BVALID = 1;
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
                RVALID = 1;
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
//UART控制信号
    reg [DATA_WID-1:0]UART_data;
    assign UART_data = WDATA;

    reg UART_wen,UART_ren;
    assign UART_wen = (B_state==0)&&(nB_state==1);
    always @(posedge clk) begin
        if(UART_wen) $write("%c",UART_data[7:0]);
    end
endmodule
