module ysyx_25080209_Xbar #(ADDR_WID = 32,DATA_WID = 32) (
    input clk, rst,

    input arbiter_valid,
    output reg xbar_valid,
    
//AXI4接口 master
    output                  io_master_awready,
    input                   io_master_awvalid,
    input  [ADDR_WID-1:0]   io_master_awaddr,
    input  [3:0]            io_master_awid,
    input  [7:0]            io_master_awlen,
    input  [2:0]            io_master_awsize,
    input  [1:0]            io_master_awburst,
    output                  io_master_wready,
    input                   io_master_wvalid,
    input  [DATA_WID-1:0]   io_master_wdata,
    input  [3:0]            io_master_wstrb,
    input                   io_master_wlast,
    input                   io_master_bready,
    output                  io_master_bvalid,
    output [1:0]            io_master_bresp,
    output [3:0]            io_master_bid,
    output                  io_master_arready,
    input                   io_master_arvalid,
    input  [ADDR_WID-1:0]   io_master_araddr,
    input  [3:0]            io_master_arid,
    input  [7:0]            io_master_arlen,
    input  [2:0]            io_master_arsize,
    input  [1:0]            io_master_arburst,
    input                   io_master_rready,
    output                  io_master_rvalid,
    output [1:0]            io_master_rresp,
    output [DATA_WID-1:0]   io_master_rdata,
    output                  io_master_rlast,
    output [3:0]            io_master_rid,
//AXI4接口 slave0
    input                   io_slave0_awready,
    output                  io_slave0_awvalid,
    output [31:0]           io_slave0_awaddr,
    output [3:0]            io_slave0_awid,
    output [7:0]            io_slave0_awlen,
    output [2:0]            io_slave0_awsize,
    output [1:0]            io_slave0_awburst,
    input                   io_slave0_wready,
    output                  io_slave0_wvalid,
    output [31:0]           io_slave0_wdata,
    output [3:0]            io_slave0_wstrb,
    output                  io_slave0_wlast,
    output                  io_slave0_bready,
    input                   io_slave0_bvalid,
    input [1:0]             io_slave0_bresp,
    input [3:0]             io_slave0_bid,
    input                   io_slave0_arready,
    output                  io_slave0_arvalid,
    output [31:0]           io_slave0_araddr,
    output [3:0]            io_slave0_arid,
    output [7:0]            io_slave0_arlen,
    output [2:0]            io_slave0_arsize,
    output [1:0]            io_slave0_arburst,
    output                  io_slave0_rready,
    input                   io_slave0_rvalid,
    input [1:0]             io_slave0_rresp,
    input [31:0]            io_slave0_rdata,
    input                   io_slave0_rlast,
    input [3:0]             io_slave0_rid,
//AXI4接口 slave1
    input                   io_slave1_awready,
    output                  io_slave1_awvalid,
    output [31:0]           io_slave1_awaddr,
    output [3:0]            io_slave1_awid,
    output [7:0]            io_slave1_awlen,
    output [2:0]            io_slave1_awsize,
    output [1:0]            io_slave1_awburst,
    input                   io_slave1_wready,
    output                  io_slave1_wvalid,
    output [31:0]           io_slave1_wdata,
    output [3:0]            io_slave1_wstrb,
    output                  io_slave1_wlast,
    output                  io_slave1_bready,
    input                   io_slave1_bvalid,
    input [1:0]             io_slave1_bresp,
    input [3:0]             io_slave1_bid,
    input                   io_slave1_arready,
    output                  io_slave1_arvalid,
    output [31:0]           io_slave1_araddr,
    output [3:0]            io_slave1_arid,
    output [7:0]            io_slave1_arlen,
    output [2:0]            io_slave1_arsize,
    output [1:0]            io_slave1_arburst,
    output                  io_slave1_rready,
    input                   io_slave1_rvalid,
    input [1:0]             io_slave1_rresp,
    input [31:0]            io_slave1_rdata,
    input                   io_slave1_rlast,
    input [3:0]             io_slave1_rid
);

//slave0 除slave1之外的地址
parameter SLAVE1_BASE = 32'h0200_0000;  // Slave1地址范围
parameter SLAVE1_END  = 32'h0200_ffff;

always @(posedge clk) begin
    en_slave0 <= 0;
    en_slave1 <= 0;
    xbar_valid <=0;
    if(rst) begin
        en_slave0 <= 0;
        en_slave1 <= 0;
        xbar_valid <=0;
    end else begin
        if(arbiter_valid) begin
            if(access_slave0) begin
                en_slave0 <= 1;
                xbar_valid <= 1;
            end 
            else if(access_slave1) begin
                en_slave1 <= 1;
                xbar_valid <= 1;
            end
        end
    end
end
// always @(*) begin
//     en_slave0 = 0;
//     en_slave1 = 0;
//     xbar_valid =0;
//     if(arbiter_valid) begin
//         if(access_slave0) begin
//             en_slave0 = 1;
//             xbar_valid = 1;
//         end 
//         else if(access_slave1) begin
//             en_slave1 = 1;
//             xbar_valid = 1;
//         end
//     end
// end

wire access_slave0, access_slave1;
reg en_slave0, en_slave1;

assign access_slave0 = !access_slave1;
assign access_slave1 = ((io_master_awaddr >= SLAVE1_BASE) 
                        && (io_master_awaddr <= SLAVE1_END)) ||
                        ((io_master_araddr >= SLAVE1_BASE) 
                        && (io_master_araddr <= SLAVE1_END));

always @(*) begin
//master
    io_master_awready = 0;
    io_master_wready  = 0;
    io_master_bvalid  = 0;
    io_master_bresp   = 0;
    io_master_bid     = 0;
    io_master_arready = 0;
    io_master_rvalid  = 0;
    io_master_rresp   = 0;
    io_master_rdata   = 0;
    io_master_rlast   = 0;
    io_master_rid     = 0;
//slave0
    io_slave0_awvalid = 0;
    io_slave0_awaddr = 0;
    io_slave0_awid = 0;
    io_slave0_awlen = 0;
    io_slave0_awsize = 0;
    io_slave0_awburst = 0;
    io_slave0_wvalid = 0;
    io_slave0_wdata = 0;
    io_slave0_wstrb = 0;
    io_slave0_wlast = 0;
    io_slave0_bready = 0;
    io_slave0_arvalid = 0;
    io_slave0_araddr = 0;
    io_slave0_arid = 0;
    io_slave0_arlen = 0;
    io_slave0_arsize = 0;
    io_slave0_arburst = 0;
    io_slave0_rready = 0;
//slave1
    io_slave1_awvalid = 0;
    io_slave1_awaddr = 0;
    io_slave1_awid = 0;
    io_slave1_awlen = 0;
    io_slave1_awsize = 0;
    io_slave1_awburst = 0;
    io_slave1_wvalid = 0;
    io_slave1_wdata = 0;
    io_slave1_wstrb = 0;
    io_slave1_wlast = 0;
    io_slave1_bready = 0;
    io_slave1_arvalid = 0;
    io_slave1_araddr = 0;
    io_slave1_arid = 0;
    io_slave1_arlen = 0;
    io_slave1_arsize = 0;
    io_slave1_arburst = 0;
    io_slave1_rready = 0;
    if(en_slave0) begin
        // master -> slave0
        io_slave0_awvalid = io_master_awvalid;
        io_slave0_awaddr  = io_master_awaddr;
        io_slave0_awid    = io_master_awid;
        io_slave0_awlen   = io_master_awlen;
        io_slave0_awsize  = io_master_awsize;
        io_slave0_awburst = io_master_awburst;
        io_slave0_wvalid  = io_master_wvalid;
        io_slave0_wdata   = io_master_wdata;
        io_slave0_wstrb   = io_master_wstrb;
        io_slave0_wlast   = io_master_wlast;
        io_slave0_bready  = io_master_bready;
        io_slave0_arvalid = io_master_arvalid;
        io_slave0_araddr  = io_master_araddr;
        io_slave0_arid    = io_master_arid;
        io_slave0_arlen   = io_master_arlen;
        io_slave0_arsize  = io_master_arsize;
        io_slave0_arburst = io_master_arburst;
        io_slave0_rready  = io_master_rready;

        // slave0 -> master
        io_master_awready = io_slave0_awready;
        io_master_wready  = io_slave0_wready;
        io_master_bvalid  = io_slave0_bvalid;
        io_master_bresp   = io_slave0_bresp;
        io_master_bid     = io_slave0_bid;
        io_master_arready = io_slave0_arready;
        io_master_rvalid  = io_slave0_rvalid;
        io_master_rresp   = io_slave0_rresp;
        io_master_rdata   = io_slave0_rdata;
        io_master_rlast   = io_slave0_rlast;
        io_master_rid     = io_slave0_rid;
    end
    else if(en_slave1) begin
        // master -> slave1
        io_slave1_awvalid = io_master_awvalid;
        io_slave1_awaddr  = io_master_awaddr;
        io_slave1_awid    = io_master_awid;
        io_slave1_awlen   = io_master_awlen;
        io_slave1_awsize  = io_master_awsize;
        io_slave1_awburst = io_master_awburst;
        io_slave1_wvalid  = io_master_wvalid;
        io_slave1_wdata   = io_master_wdata;
        io_slave1_wstrb   = io_master_wstrb;
        io_slave1_wlast   = io_master_wlast;
        io_slave1_bready  = io_master_bready;
        io_slave1_arvalid = io_master_arvalid;
        io_slave1_araddr  = io_master_araddr;
        io_slave1_arid    = io_master_arid;
        io_slave1_arlen   = io_master_arlen;
        io_slave1_arsize  = io_master_arsize;
        io_slave1_arburst = io_master_arburst;
        io_slave1_rready  = io_master_rready;

        // slave1 -> master
        io_master_awready = io_slave1_awready;
        io_master_wready  = io_slave1_wready;
        io_master_bvalid  = io_slave1_bvalid;
        io_master_bresp   = io_slave1_bresp;
        io_master_bid     = io_slave1_bid;
        io_master_arready = io_slave1_arready;
        io_master_rvalid  = io_slave1_rvalid;
        io_master_rresp   = io_slave1_rresp;
        io_master_rdata   = io_slave1_rdata;
        io_master_rlast   = io_slave1_rlast;
        io_master_rid     = io_slave1_rid;
    end
end

endmodule
