module ysyx_25080209_CLINT_AXI4 #(ADDR_WID = 32, DATA_WID = 32)(
    input clk,rst,

//AXI4接口 slave
    output reg              io_slave_awready,
    input                   io_slave_awvalid,
    input  [ADDR_WID-1:0]   io_slave_awaddr,
    input  [3:0]            io_slave_awid,
    input  [7:0]            io_slave_awlen,
    input  [2:0]            io_slave_awsize,
    input  [1:0]            io_slave_awburst,
    output                  io_slave_wready,
    input                   io_slave_wvalid,
    input  [DATA_WID-1:0]   io_slave_wdata,
    input  [3:0]            io_slave_wstrb,
    input                   io_slave_wlast,
    input                   io_slave_bready,
    output                  io_slave_bvalid,
    output [1:0]            io_slave_bresp,
    output [3:0]            io_slave_bid,
    output                  io_slave_arready,
    input                   io_slave_arvalid,
    input  [ADDR_WID-1:0]   io_slave_araddr,
    input  [3:0]            io_slave_arid,
    input  [7:0]            io_slave_arlen,
    input  [2:0]            io_slave_arsize,
    input  [1:0]            io_slave_arburst,
    input                   io_slave_rready,
    output                  io_slave_rvalid,
    output [1:0]            io_slave_rresp,
    output [DATA_WID-1:0]   io_slave_rdata,
    output                  io_slave_rlast,
    output [3:0]            io_slave_rid
);
//AXI4-lite 从 
//米利状态机
    //从设备控制
        wire w_req,r_req;
        wire w_fin,r_fin;
        assign w_req = (nAW_state == 1) && (nW_state == 1);
        assign r_req = nAR_state == 1;
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
        //01 wait work and ready
        //10 wait ready
        reg [1:0]B_state,nB_state;
    //raddr
        //0 wait valid
        //1 wait work
        reg AR_state,nAR_state;
    //rdata
        //00 wait raddr
        //01 wait work and ready
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
            0:if(io_slave_awvalid) nAW_state = 1;
            else nAW_state = 0;
            1:if(w_fin) nAW_state = 0;
            else nAW_state = 1;
            default:nAW_state = 0;
        endcase
        case (W_state)
            0:if(io_slave_wvalid) nW_state = 1;
            else nW_state = 0;
            1:if(w_fin) nW_state = 0;
            else nW_state = 1;
            default:nAW_state = 0;
        endcase
        case (B_state)
            2'b00:if((AW_state==1)&(W_state==1))
                    nB_state = 2'b01; 
                else nB_state = 2'b00;
            2'b01:if(w_fin)
                    if(io_slave_rready) nB_state = 2'b00;
                    else nB_state = 2'b10;
                else nB_state = 2'b01;
            2'b10:if(io_slave_rready) nB_state = 2'b00;
                    else nB_state = 2'b10;
            default:nB_state = 2'b00;
        endcase
        case (AR_state)
            1'b0:begin 
                if(io_slave_arvalid) nAR_state = 1'b1;
                else nAR_state = 1'b0;
            end 
            1'b1:nAR_state = 1'b0;
        endcase
        case (R_state)
            2'b00:begin
                if(io_slave_arvalid && io_slave_arready) begin
                    nR_state = 2'b01;
                end
                else nR_state = 2'b00;
            end
            2'b01:if(r_fin)
                    if(io_slave_rready) nR_state = 2'b00;
                    else nR_state = 2'b10;
                else nR_state = 2'b01;
            2'b10:if(io_slave_rready) nR_state = 2'b00;
                    else nR_state = 2'b10;
            default:nR_state = 2'b00;
        endcase
    end
    always @(*) begin
        case (AW_state)
            0:io_slave_awready=1;
            1:io_slave_awready=0;
            default:io_slave_awready=0;
        endcase
        case (W_state)
            0:io_slave_wready = 1;
            1:io_slave_wready = 0;
            default:io_slave_wready = 0;
        endcase
        case (B_state)
            2'b00:begin 
                io_slave_bvalid = 0;
                io_slave_bresp = 2'b0;
            end
            2'b01:begin
                if(w_fin) io_slave_bvalid = 1;
                else io_slave_bvalid = 0;
                io_slave_bresp = 2'b0;
            end
            2'b10:begin
                io_slave_bvalid = 1;
                io_slave_bresp = 2'b0;
            end
            default:begin
                io_slave_bvalid = 0;
                io_slave_bresp = 2'b0;
            end 
        endcase
        case (AR_state)
            1'b0:begin
                io_slave_arready = 1;
            end
            1'b1:begin
                io_slave_arready = 0;
            end
        endcase
        case (R_state)
            2'b00:begin
                io_slave_rvalid = 0;
                io_slave_rresp = 2'b0;
            end
            2'b01:begin
                if(r_fin) io_slave_rvalid = 1;
                else io_slave_rvalid = 0;
                io_slave_rresp = 2'b0;
            end
            2'b10:begin
                io_slave_rvalid = 1;
                io_slave_rresp = 2'b0;
            end
            default:begin
                io_slave_rvalid = 0;
                io_slave_rresp = 2'b0;
            end
        endcase
    end

assign w_fin = 1;
assign r_fin = 1;

reg [DATA_WID*2-1:0] mtime;
always @(posedge clk) begin
    mtime <= 0;
    io_slave_rdata <= 0;

    if(rst) begin
        mtime <= 0;
        io_slave_rdata <= 0;
    end 
    else begin
        mtime <= mtime + 1;
        if(r_req) begin
            case (io_slave_araddr[2])
            1'b0:io_slave_rdata <= mtime[DATA_WID-1:0];
            1'b1:io_slave_rdata <= mtime[DATA_WID*2-1:DATA_WID];
            default:;
            endcase
        end
    end
end
endmodule
