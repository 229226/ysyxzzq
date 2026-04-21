module ysyx_25080209_AXI4_lite_Arbiter_Xbar #(DATA_WID = 32, ADDR_WID = 32) (
    input ACLK,
    input ARESETn,

    // Master 0 接口
    input  [ADDR_WID-1:0] AWADDR_m0,
    input                 AWVALID_m0,
    output                AWREADY_m0,
    input  [DATA_WID-1:0] WDATA_m0,
    input  [3:0]          WSTRB_m0,
    input                 WVALID_m0,
    output                WREADY_m0,
    input                 BREADY_m0,
    output [1:0]          BRESP_m0,
    output                BVALID_m0,
    input  [ADDR_WID-1:0] ARADDR_m0,
    input                 ARVALID_m0,
    output                ARREADY_m0,
    output [DATA_WID-1:0] RDATA_m0,
    output [1:0]          RRESP_m0,
    input                 RREADY_m0,
    output                RVALID_m0,

    // Master 1 接口
    input  [ADDR_WID-1:0] AWADDR_m1,
    input                 AWVALID_m1,
    output                AWREADY_m1,
    input  [DATA_WID-1:0] WDATA_m1,
    input  [3:0]          WSTRB_m1,
    input                 WVALID_m1,
    output                WREADY_m1,
    input                 BREADY_m1,
    output [1:0]          BRESP_m1,
    output                BVALID_m1,
    input  [ADDR_WID-1:0] ARADDR_m1,
    input                 ARVALID_m1,
    output                ARREADY_m1,
    output [DATA_WID-1:0] RDATA_m1,
    output [1:0]          RRESP_m1,
    input                 RREADY_m1,
    output                RVALID_m1,

    // Slave 0 接口
    output                S0_ACLK,
    output                S0_ARESETn,
    output [ADDR_WID-1:0] S0_AWADDR,
    output                S0_AWVALID,
    input                 S0_AWREADY,
    output [DATA_WID-1:0] S0_WDATA,
    output [3:0]          S0_WSTRB,
    output                S0_WVALID,
    input                 S0_WREADY,
    output                S0_BREADY,
    input  [1:0]          S0_BRESP,
    input                 S0_BVALID,
    output [ADDR_WID-1:0] S0_ARADDR,
    output                S0_ARVALID,
    input                 S0_ARREADY,
    input  [DATA_WID-1:0] S0_RDATA,
    input  [1:0]          S0_RRESP,
    output                S0_RREADY,
    input                 S0_RVALID,

    // Slave 1 接口
    output                S1_ACLK,
    output                S1_ARESETn,
    output [ADDR_WID-1:0] S1_AWADDR,
    output                S1_AWVALID,
    input                 S1_AWREADY,
    output [DATA_WID-1:0] S1_WDATA,
    output [3:0]          S1_WSTRB,
    output                S1_WVALID,
    input                 S1_WREADY,
    output                S1_BREADY,
    input  [1:0]          S1_BRESP,
    input                 S1_BVALID,
    output [ADDR_WID-1:0] S1_ARADDR,
    output                S1_ARVALID,
    input                 S1_ARREADY,
    input  [DATA_WID-1:0] S1_RDATA,
    input  [1:0]          S1_RRESP,
    output                S1_RREADY,
    input                 S1_RVALID
);

wire [ADDR_WID-1:0] AWADDR_s;
wire                 AWVALID_s;
wire                 AWREADY_s;
wire [DATA_WID-1:0] WDATA_s;
wire [3:0]          WSTRB_s;
wire                 WVALID_s;
wire                 WREADY_s;
wire                 BREADY_s;
wire [1:0]          BRESP_s;
wire                 BVALID_s;
wire [ADDR_WID-1:0] ARADDR_s;
wire                 ARVALID_s;
wire                 ARREADY_s;
wire [DATA_WID-1:0] RDATA_s;
wire [1:0]          RRESP_s;
wire                 RREADY_s;
wire                 RVALID_s;

ysyx_25080209_AXI4_lite_Arbiter #(
    .DATA_WID(DATA_WID),
    .ADDR_WID(ADDR_WID)
) u_arbiter (
    .xbar_work(xbar_work),

    .ACLK        (ACLK),
    .ARESETn     (ARESETn),
    // Master 0
    .AWADDR_m1   (AWADDR_m0),
    .AWVALID_m1  (AWVALID_m0),
    .AWREADY_m1  (AWREADY_m0),
    .WDATA_m1    (WDATA_m0),
    .WSTRB_m1    (WSTRB_m0),
    .WVALID_m1   (WVALID_m0),
    .WREADY_m1   (WREADY_m0),
    .BREADY_m1   (BREADY_m0),
    .BRESP_m1    (BRESP_m0),
    .BVALID_m1   (BVALID_m0),
    .ARADDR_m1   (ARADDR_m0),
    .ARVALID_m1  (ARVALID_m0),
    .ARREADY_m1  (ARREADY_m0),
    .RDATA_m1    (RDATA_m0),
    .RRESP_m1    (RRESP_m0),
    .RREADY_m1   (RREADY_m0),
    .RVALID_m1   (RVALID_m0),
    // Master 1
    .AWADDR_m2   (AWADDR_m1),
    .AWVALID_m2  (AWVALID_m1),
    .AWREADY_m2  (AWREADY_m1),
    .WDATA_m2    (WDATA_m1),
    .WSTRB_m2    (WSTRB_m1),
    .WVALID_m2   (WVALID_m1),
    .WREADY_m2   (WREADY_m1),
    .BREADY_m2   (BREADY_m1),
    .BRESP_m2    (BRESP_m1),
    .BVALID_m2   (BVALID_m1),
    .ARADDR_m2   (ARADDR_m1),
    .ARVALID_m2  (ARVALID_m1),
    .ARREADY_m2  (ARREADY_m1),
    .RDATA_m2    (RDATA_m1),
    .RRESP_m2    (RRESP_m1),
    .RREADY_m2   (RREADY_m1),
    .RVALID_m2   (RVALID_m1),
    // Slave 接口
    .AWADDR_s    (AWADDR_s),
    .AWVALID_s   (AWVALID_s),
    .AWREADY_s   (AWREADY_s),
    .WDATA_s     (WDATA_s),
    .WSTRB_s     (WSTRB_s),
    .WVALID_s    (WVALID_s),
    .WREADY_s    (WREADY_s),
    .BREADY_s    (BREADY_s),
    .BRESP_s     (BRESP_s),
    .BVALID_s    (BVALID_s),
    .ARADDR_s    (ARADDR_s),
    .ARVALID_s   (ARVALID_s),
    .ARREADY_s   (ARREADY_s),
    .RDATA_s     (RDATA_s),
    .RRESP_s     (RRESP_s),
    .RREADY_s    (RREADY_s),
    .RVALID_s    (RVALID_s)
);

wire xbar_work;

ysyx_25080209_Xbar #(
    .ADDR_WID(ADDR_WID),
    .DATA_WID(DATA_WID)
) u_xbar (
    .work(xbar_work),

    .ACLK        (ACLK),
    .ARESETn     (ARESETn),
    // Master 接口
    .AWADDR      (AWADDR_s),
    .AWVALID     (AWVALID_s),
    .AWREADY     (AWREADY_s),
    .WDATA       (WDATA_s),
    .WSTRB       (WSTRB_s),
    .WVALID      (WVALID_s),
    .WREADY      (WREADY_s),
    .BREADY      (BREADY_s),
    .BRESP       (BRESP_s),
    .BVALID      (BVALID_s),
    .ARADDR      (ARADDR_s),
    .ARVALID     (ARVALID_s),
    .ARREADY     (ARREADY_s),
    .RDATA       (RDATA_s),
    .RRESP       (RRESP_s),
    .RREADY      (RREADY_s),
    .RVALID      (RVALID_s),
    // Slave 0
    .S0_ACLK     (S0_ACLK),
    .S0_ARESETn  (S0_ARESETn),
    .S0_AWADDR   (S0_AWADDR),
    .S0_AWVALID  (S0_AWVALID),
    .S0_AWREADY  (S0_AWREADY),
    .S0_WDATA    (S0_WDATA),
    .S0_WSTRB    (S0_WSTRB),
    .S0_WVALID   (S0_WVALID),
    .S0_WREADY   (S0_WREADY),
    .S0_BREADY   (S0_BREADY),
    .S0_BRESP    (S0_BRESP),
    .S0_BVALID   (S0_BVALID),
    .S0_ARADDR   (S0_ARADDR),
    .S0_ARVALID  (S0_ARVALID),
    .S0_ARREADY  (S0_ARREADY),
    .S0_RDATA    (S0_RDATA),
    .S0_RRESP    (S0_RRESP),
    .S0_RREADY   (S0_RREADY),
    .S0_RVALID   (S0_RVALID),
    // Slave 1
    .S1_ACLK     (S1_ACLK),
    .S1_ARESETn  (S1_ARESETn),
    .S1_AWADDR   (S1_AWADDR),
    .S1_AWVALID  (S1_AWVALID),
    .S1_AWREADY  (S1_AWREADY),
    .S1_WDATA    (S1_WDATA),
    .S1_WSTRB    (S1_WSTRB),
    .S1_WVALID   (S1_WVALID),
    .S1_WREADY   (S1_WREADY),
    .S1_BREADY   (S1_BREADY),
    .S1_BRESP    (S1_BRESP),
    .S1_BVALID   (S1_BVALID),
    .S1_ARADDR   (S1_ARADDR),
    .S1_ARVALID  (S1_ARVALID),
    .S1_ARREADY  (S1_ARREADY),
    .S1_RDATA    (S1_RDATA),
    .S1_RRESP    (S1_RRESP),
    .S1_RREADY   (S1_RREADY),
    .S1_RVALID   (S1_RVALID)
);

endmodule
