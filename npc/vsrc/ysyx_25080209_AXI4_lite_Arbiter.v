module ysyx_25080209_AXI4_lite_Arbiter #(DATA_WID=32,ADDR_WID=32) (
    output reg xbar_work,

    input ACLK,ARESETn,
    //waddr
        //master
        input [ADDR_WID-1:0]AWADDR_m1,AWADDR_m2,
        input AWVALID_m1,AWVALID_m2,
        output reg AWREADY_m1,AWREADY_m2,
        //slave
        output [ADDR_WID-1:0]AWADDR_s,
        output AWVALID_s,
        input AWREADY_s,
    //wdata
        //master
        input [DATA_WID-1:0]WDATA_m1,WDATA_m2,
        input [3:0]WSTRB_m1,WSTRB_m2,
        input WVALID_m1,WVALID_m2,
        output reg WREADY_m1,WREADY_m2,
        //slave
        output [DATA_WID-1:0]WDATA_s,
        output [3:0]WSTRB_s,
        output WVALID_s,
        input WREADY_s,
    //wresponse
        //master
        input BREADY_m1,BREADY_m2,
        output [1:0]BRESP_m1,BRESP_m2,
        output BVALID_m1,BVALID_m2,
        //slave
        output BREADY_s,
        input [1:0]BRESP_s,
        input BVALID_s,
    //raddr
        //master
        input [ADDR_WID-1:0]ARADDR_m1,ARADDR_m2,
        input ARVALID_m1,ARVALID_m2,
        output ARREADY_m1,ARREADY_m2,
        //slave
        output [ADDR_WID-1:0]ARADDR_s,
        output ARVALID_s,
        input ARREADY_s,
    //rdata
        //master
        output reg [DATA_WID-1:0]RDATA_m1,RDATA_m2,
        output [1:0]RRESP_m1,RRESP_m2,
        input RREADY_m1,RREADY_m2,
        output RVALID_m1,RVALID_m2,
        //slave
        input [DATA_WID-1:0]RDATA_s,
        input [1:0]RRESP_s,
        output RREADY_s,
        input RVALID_s
);
wire m1_req,m2_req,m1_fini,m2_fini;
reg m1_valid,m2_valid;
assign m1_req = AWVALID_m1||WVALID_m1||ARVALID_m1;
assign m2_req = AWVALID_m2||WVALID_m2||ARVALID_m2;
assign m1_fini = (BVALID_s&&BREADY_m1) || (RVALID_s&&RREADY_m1);
assign m2_fini = (BVALID_s&&BREADY_m2) || (RVALID_s&&RREADY_m2);
//00 无master请求
//01 m1请求与等待s回应 优先
//10 m2请求与等待s回应
reg [1:0]Arbiter_state,nArbiter_state;
always @(posedge ACLK) begin
    if(!ARESETn) Arbiter_state <= 0;
    else Arbiter_state <= nArbiter_state;
end
always @(*) begin
    case (Arbiter_state)
    2'b00:if(m1_req) nArbiter_state = 2'b01;
        else if(m2_req) nArbiter_state = 2'b10;
        else nArbiter_state = 2'b00;
    2'b01:if(m1_fini) nArbiter_state = 2'b00;
        else nArbiter_state = 2'b01;
    2'b10:if(m2_fini) nArbiter_state = 2'b00;
        else nArbiter_state = 2'b10;
    default:nArbiter_state = 2'b00;
    endcase
end
always @(*) begin
    xbar_work = 0;
    case (Arbiter_state)
    2'b00:if(m1_req) begin m1_valid = 1;m2_valid = 0;xbar_work = 1;end 
        else if(m2_req) begin m1_valid = 0;m2_valid = 1;xbar_work = 1;end 
        else begin m1_valid = 0;m2_valid = 0;end
    2'b01:begin m1_valid = 1;m2_valid = 0;xbar_work = 1;end  
    2'b10:begin m1_valid = 0;m2_valid = 1;xbar_work = 1;end
    default:begin m1_valid = 0;m2_valid = 0;end
    endcase
end

always @(*) begin
    if(m1_valid) begin
        // Master 1获得总线控制权
        //waddr
        AWADDR_s = AWADDR_m1;AWVALID_s = AWVALID_m1;
        //wdata
        WDATA_s = WDATA_m1;WSTRB_s = WSTRB_m1;WVALID_s = WVALID_m1;
        //wres
        BREADY_s = BREADY_m1;
        //raddr
        ARADDR_s = ARADDR_m1;ARVALID_s = ARVALID_m1;
        //rdata
        RREADY_s = RREADY_m1;
    end
    else if(m2_valid) begin
        // Master 2获得总线控制权
        //waddr
        AWADDR_s = AWADDR_m2;AWVALID_s = AWVALID_m2;
        //wdata
        WDATA_s = WDATA_m2;WSTRB_s = WSTRB_m2;WVALID_s = WVALID_m2;
        //wres
        BREADY_s = BREADY_m2;
        //raddr
        ARADDR_s = ARADDR_m2;ARVALID_s = ARVALID_m2;
        //rdata
        RREADY_s = RREADY_m2;
    end
    else begin
        // 无master获得控制权，所有输出置0
        //waddr
        AWADDR_s = 0;AWVALID_s = 0;
        //wdata
        WDATA_s = 0;WSTRB_s = 0;WVALID_s = 0;
        //wres
        BREADY_s = 0;
        //raddr
        ARADDR_s = 0;ARVALID_s = 0;
        //rdata
        RREADY_s = 0;
    end
end
always @(*) begin
    AWREADY_m1 = AWREADY_s;
    AWREADY_m2 = AWREADY_s;
    WREADY_m1 = WREADY_s;
    WREADY_m2 = WREADY_s;
    BRESP_m1 = BRESP_s;BVALID_m1 = BVALID_s;
    BRESP_m2 = BRESP_s;BVALID_m2 = BVALID_s;
    ARREADY_m1 = ARREADY_s;
    ARREADY_m2 = ARREADY_s;
    RDATA_m1 = RDATA_s;RRESP_m1 = RRESP_s;RVALID_m1 = RVALID_s;
    RDATA_m2 = RDATA_s;RRESP_m2 = RRESP_s;RVALID_m2 = RVALID_s;
end
endmodule
