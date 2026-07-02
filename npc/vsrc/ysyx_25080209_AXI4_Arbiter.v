module ysyx_25080209_AXI4_Arbiter #(DATA_WID=32,ADDR_WID=32) (
    input clk, rst,

    output reg arbiter_valid,
    input xbar_valid,

//AXI4接口 master0
    output                  io_master0_awready,
    input                   io_master0_awvalid,
    input  [ADDR_WID-1:0]   io_master0_awaddr,
    input  [3:0]            io_master0_awid,
    input  [7:0]            io_master0_awlen,
    input  [2:0]            io_master0_awsize,
    input  [1:0]            io_master0_awburst,
    output                  io_master0_wready,
    input                   io_master0_wvalid,
    input  [DATA_WID-1:0]   io_master0_wdata,
    input  [3:0]            io_master0_wstrb,
    input                   io_master0_wlast,
    input                   io_master0_bready,
    output                  io_master0_bvalid,
    output [1:0]            io_master0_bresp,
    output [3:0]            io_master0_bid,
    output                  io_master0_arready,
    input                   io_master0_arvalid,
    input  [ADDR_WID-1:0]   io_master0_araddr,
    input  [3:0]            io_master0_arid,
    input  [7:0]            io_master0_arlen,
    input  [2:0]            io_master0_arsize,
    input  [1:0]            io_master0_arburst,
    input                   io_master0_rready,
    output                  io_master0_rvalid,
    output [1:0]            io_master0_rresp,
    output [DATA_WID-1:0]   io_master0_rdata,
    output                  io_master0_rlast,
    output [3:0]            io_master0_rid,

//AXI4接口 master1
    output                  io_master1_awready,
    input                   io_master1_awvalid,
    input  [ADDR_WID-1:0]   io_master1_awaddr,
    input  [3:0]            io_master1_awid,
    input  [7:0]            io_master1_awlen,
    input  [2:0]            io_master1_awsize,
    input  [1:0]            io_master1_awburst,
    output                  io_master1_wready,
    input                   io_master1_wvalid,
    input  [DATA_WID-1:0]   io_master1_wdata,
    input  [3:0]            io_master1_wstrb,
    input                   io_master1_wlast,
    input                   io_master1_bready,
    output                  io_master1_bvalid,
    output [1:0]            io_master1_bresp,
    output [3:0]            io_master1_bid,
    output                  io_master1_arready,
    input                   io_master1_arvalid,
    input  [ADDR_WID-1:0]   io_master1_araddr,
    input  [3:0]            io_master1_arid,
    input  [7:0]            io_master1_arlen,
    input  [2:0]            io_master1_arsize,
    input  [1:0]            io_master1_arburst,
    input                   io_master1_rready,
    output                  io_master1_rvalid,
    output [1:0]            io_master1_rresp,
    output [DATA_WID-1:0]   io_master1_rdata,
    output                  io_master1_rlast,
    output [3:0]            io_master1_rid,

//AXI4接口 slave
    input                   io_slave_awready,
    output                  io_slave_awvalid,
    output [31:0]           io_slave_awaddr,
    output [3:0]            io_slave_awid,
    output [7:0]            io_slave_awlen,
    output [2:0]            io_slave_awsize,
    output [1:0]            io_slave_awburst,
    input                   io_slave_wready,
    output                  io_slave_wvalid,
    output [31:0]           io_slave_wdata,
    output [3:0]            io_slave_wstrb,
    output                  io_slave_wlast,
    output                  io_slave_bready,
    input                   io_slave_bvalid,
    input [1:0]             io_slave_bresp,
    input [3:0]             io_slave_bid,
    input                   io_slave_arready,
    output                  io_slave_arvalid,
    output [31:0]           io_slave_araddr,
    output [3:0]            io_slave_arid,
    output [7:0]            io_slave_arlen,
    output [2:0]            io_slave_arsize,
    output [1:0]            io_slave_arburst,
    output                  io_slave_rready,
    input                   io_slave_rvalid,
    input [1:0]             io_slave_rresp,
    input [31:0]            io_slave_rdata,
    input                   io_slave_rlast,
    input [3:0]             io_slave_rid
);
wire m0_req,m1_req;
reg m0_valid,m1_valid,m0_fin,m1_fin;
assign m0_req = io_master0_awvalid || io_master0_wvalid || io_master0_arvalid;
assign m1_req = io_master1_awvalid || io_master1_wvalid || io_master1_arvalid;
assign m0_fin = (io_master0_bvalid&&io_master0_bready) || 
                (io_master0_rvalid&&io_master0_rready);
assign m1_fin = (io_master1_bvalid&&io_master1_bready) || 
                (io_master1_rvalid&&io_master1_rready);

// reg m0_AW_fin,m0_W_fin,m0_B_fin,m0_AR_fin,m0_R_fin,
//     m1_AW_fin,m1_W_fin,m1_B_fin,m1_AR_fin,m1_R_fin;
// always @(posedge clk) begin
//     if(rst)begin
//         m0_AW_fin<=0;m0_W_fin<=0;m0_B_fin<=0;m0_AR_fin<=0;m0_R_fin<=0;
//         m1_AW_fin<=0;m1_W_fin<=0;m1_B_fin<=0;m1_AR_fin<=0;m1_R_fin<=0;
//     end else if(m0_fin || m1_fin) begin
//         m0_AW_fin<=0;m0_W_fin<=0;m0_B_fin<=0;m0_AR_fin<=0;m0_R_fin<=0;
//         m1_AW_fin<=0;m1_W_fin<=0;m1_B_fin<=0;m1_AR_fin<=0;m1_R_fin<=0;
//     end else begin
//         if(io_master0_awvalid&&io_master0_awready) m0_AW_fin<=1;
//         if(io_master0_wvalid&&io_master0_wready) m0_W_fin<=1;
//         if(io_master0_bvalid&&io_master0_bready) m0_B_fin<=1;
//         if(io_master0_arvalid&&io_master0_arready) m0_AR_fin<=1;
//         if(io_master0_rvalid&&io_master0_rready) m0_R_fin<=1;
//         if(io_master1_awvalid&&io_master1_awready) m1_AW_fin<=1;
//         if(io_master1_wvalid&&io_master1_wready) m1_W_fin<=1;
//         if(io_master1_bvalid&&io_master1_bready) m1_B_fin<=1;
//         if(io_master1_arvalid&&io_master1_arready) m1_AR_fin<=1;
//         if(io_master1_rvalid&&io_master1_rready) m1_R_fin<=1;
//     end
// end
// assign m0_fin = (m0_AW_fin&&m0_W_fin&&m0_B_fin)||(m0_AR_fin&&m0_R_fin);
// assign m1_fin = (m1_AW_fin&&m1_W_fin&&m1_B_fin)||(m1_AR_fin&&m1_R_fin);


//00 无master请求
//01 m0有效与等待s回应 优先
//10 m1有效与等待s回应
reg [1:0]Arbiter_state,nArbiter_state;
always @(posedge clk) begin
    if(rst) Arbiter_state <= 0;
    else Arbiter_state <= nArbiter_state;
end
always @(*) begin
    case (Arbiter_state)
    2'b00:begin
        if(m0_req) begin
            nArbiter_state = 2'b01;
        end 
        else if(m1_req) begin
            nArbiter_state = 2'b10;
        end 
        else nArbiter_state = 2'b00;
    end 
    2'b01:begin
        if(m0_fin) begin
            nArbiter_state = 2'b00;
        end 
        else begin
            nArbiter_state = 2'b01;
        end 
    end 
    2'b10:begin
        if(m1_fin) begin
            nArbiter_state = 2'b00;
        end 
        else begin
            nArbiter_state = 2'b10;
        end 
    end 
    default:nArbiter_state = 2'b00;
    endcase
end
always @(posedge clk) begin
    arbiter_valid <= 0;
    m0_valid <= 0;m1_valid <= 0;
    case (Arbiter_state)
    2'b00:begin
        if(m0_req) begin m0_valid <= 1;arbiter_valid <= 1;end
        else if(m1_req) begin m1_valid <= 1;arbiter_valid <= 1;end
    end
    2'b01:begin 
        if(m0_fin) begin m0_valid <= 0;arbiter_valid <= 0; end
        else begin m0_valid <= 1;arbiter_valid <= 1; end 
    end
    2'b10:begin 
        if(m1_fin) begin m1_valid <= 0;arbiter_valid <= 0; end
        else begin m1_valid <= 1;arbiter_valid <= 1; end 
    end
    default:;
    endcase
end

always @(*) begin
// 无master获得控制权输出置0
//master0
    io_master0_awready = 0;
    io_master0_wready  = 0;
    io_master0_bvalid  = 0;
    io_master0_bresp   = 0;
    io_master0_bid     = 0;
    io_master0_arready = 0;
    io_master0_rvalid  = 0;
    io_master0_rresp   = 0;
    io_master0_rdata   = 0;
    io_master0_rlast   = 0;
    io_master0_rid     = 0;
//master1
    io_master1_awready = 0;
    io_master1_wready  = 0;
    io_master1_bvalid  = 0;
    io_master1_bresp   = 0;
    io_master1_bid     = 0;
    io_master1_arready = 0;
    io_master1_rvalid  = 0;
    io_master1_rresp   = 0;
    io_master1_rdata   = 0;
    io_master1_rlast   = 0;
    io_master1_rid     = 0;
//slave
    io_slave_awvalid = 0;
    io_slave_awaddr  = 0;
    io_slave_awid    = 0;
    io_slave_awlen   = 0;
    io_slave_awsize  = 0;
    io_slave_awburst = 0;
    io_slave_wvalid  = 0;
    io_slave_wdata   = 0;
    io_slave_wstrb   = 0;
    io_slave_wlast   = 0;
    io_slave_bready  = 0;
    io_slave_arvalid = 0;
    io_slave_araddr  = 0;
    io_slave_arid    = 0;
    io_slave_arlen   = 0;
    io_slave_arsize  = 0;
    io_slave_arburst = 0;
    io_slave_rready  = 0;
if(m0_valid) begin
    // Master 0 获得总线控制权
    // 将 Master 0 的输出连接到 Slave 的输入（请求通道）
    io_slave_awvalid = io_master0_awvalid;
    io_slave_awaddr  = io_master0_awaddr;
    io_slave_awid    = io_master0_awid;
    io_slave_awlen   = io_master0_awlen;
    io_slave_awsize  = io_master0_awsize;
    io_slave_awburst = io_master0_awburst;
    io_slave_wvalid  = io_master0_wvalid;
    io_slave_wdata   = io_master0_wdata;
    io_slave_wstrb   = io_master0_wstrb;
    io_slave_wlast   = io_master0_wlast;
    io_slave_bready  = io_master0_bready;
    io_slave_arvalid = io_master0_arvalid;
    io_slave_araddr  = io_master0_araddr;
    io_slave_arid    = io_master0_arid;
    io_slave_arlen   = io_master0_arlen;
    io_slave_arsize  = io_master0_arsize;
    io_slave_arburst = io_master0_arburst;
    io_slave_rready  = io_master0_rready;

    // 将 Slave 的输出连接到 Master 0 的输入（响应通道）
    io_master0_awready = io_slave_awready;
    io_master0_wready  = io_slave_wready;
    io_master0_bvalid  = io_slave_bvalid;
    io_master0_bresp   = io_slave_bresp;
    io_master0_bid     = io_slave_bid;
    io_master0_arready = io_slave_arready;
    io_master0_rvalid  = io_slave_rvalid;
    io_master0_rresp   = io_slave_rresp;
    io_master0_rdata   = io_slave_rdata;
    io_master0_rlast   = io_slave_rlast;
    io_master0_rid     = io_slave_rid;
end
else if(m1_valid) begin
    // Master 1 获得总线控制权
    // 将 Master 1 的输出连接到 Slave 的输入（请求通道）
    io_slave_awvalid = io_master1_awvalid;
    io_slave_awaddr  = io_master1_awaddr;
    io_slave_awid    = io_master1_awid;
    io_slave_awlen   = io_master1_awlen;
    io_slave_awsize  = io_master1_awsize;
    io_slave_awburst = io_master1_awburst;
    io_slave_wvalid  = io_master1_wvalid;
    io_slave_wdata   = io_master1_wdata;
    io_slave_wstrb   = io_master1_wstrb;
    io_slave_wlast   = io_master1_wlast;
    io_slave_bready  = io_master1_bready;
    io_slave_arvalid = io_master1_arvalid;
    io_slave_araddr  = io_master1_araddr;
    io_slave_arid    = io_master1_arid;
    io_slave_arlen   = io_master1_arlen;
    io_slave_arsize  = io_master1_arsize;
    io_slave_arburst = io_master1_arburst;
    io_slave_rready  = io_master1_rready;

    // 将 Slave 的输出连接到 Master 1 的输入（响应通道）
    io_master1_awready = io_slave_awready;
    io_master1_wready  = io_slave_wready;
    io_master1_bvalid  = io_slave_bvalid;
    io_master1_bresp   = io_slave_bresp;
    io_master1_bid     = io_slave_bid;
    io_master1_arready = io_slave_arready;
    io_master1_rvalid  = io_slave_rvalid;
    io_master1_rresp   = io_slave_rresp;
    io_master1_rdata   = io_slave_rdata;
    io_master1_rlast   = io_slave_rlast;
    io_master1_rid     = io_slave_rid;
end
end
endmodule
