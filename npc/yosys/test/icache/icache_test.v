// icache_test.v
// 顶层测试模块，包含 ysyx_25080209_icache，输入和输出均插入触发器
module icache_test #(
    DATA_WID  = 32,
    BLOCK_WID = 128,
    BLOCK_NUM = 4
)(
    input  wire        clock,
    input  wire        rst,            // 复位信号

    // ---- 用户侧输入信号（加 _in 后缀以区分） ----
    input  wire        addr_valid_in,
    input  wire [DATA_WID-1:0] addr_i_in,

    // ---- AXI4 输入信号（从内存到 icache） ----
    input  wire        io_master_awready_in,
    input  wire        io_master_wready_in,
    input  wire        io_master_bvalid_in,
    input  wire [1:0]  io_master_bresp_in,
    input  wire [3:0]  io_master_bid_in,
    input  wire        io_master_arready_in,
    input  wire        io_master_rvalid_in,
    input  wire [1:0]  io_master_rresp_in,
    input  wire [31:0] io_master_rdata_in,
    input  wire        io_master_rlast_in,
    input  wire [3:0]  io_master_rid_in,

    // ---- 用户侧采样后的输出 ----
    output wire        icache_ready_sampled,
    output wire [DATA_WID-1:0] data_o_sampled,

    // ---- AXI4 采样后的输出（从 icache 到内存） ----
    output wire        io_master_awvalid_sampled,
    output wire [31:0] io_master_awaddr_sampled,
    output wire [3:0]  io_master_awid_sampled,
    output wire [7:0]  io_master_awlen_sampled,
    output wire [2:0]  io_master_awsize_sampled,
    output wire [1:0]  io_master_awburst_sampled,

    output wire        io_master_wvalid_sampled,
    output wire [31:0] io_master_wdata_sampled,
    output wire [3:0]  io_master_wstrb_sampled,
    output wire        io_master_wlast_sampled,

    output wire        io_master_bready_sampled,

    output wire        io_master_arvalid_sampled,
    output wire [31:0] io_master_araddr_sampled,
    output wire [3:0]  io_master_arid_sampled,
    output wire [7:0]  io_master_arlen_sampled,
    output wire [2:0]  io_master_arsize_sampled,
    output wire [1:0]  io_master_arburst_sampled,

    output wire        io_master_rready_sampled
);

    // ---- 输入采样寄存器 ----
    reg        addr_valid;
    reg [DATA_WID-1:0] addr_i;

    reg        io_master_awready;
    reg        io_master_wready;
    reg        io_master_bvalid;
    reg [1:0]  io_master_bresp;
    reg [3:0]  io_master_bid;
    reg        io_master_arready;
    reg        io_master_rvalid;
    reg [1:0]  io_master_rresp;
    reg [31:0] io_master_rdata;
    reg        io_master_rlast;
    reg [3:0]  io_master_rid;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            addr_valid         <= 0;
            addr_i             <= 0;
            io_master_awready  <= 0;
            io_master_wready   <= 0;
            io_master_bvalid   <= 0;
            io_master_bresp    <= 0;
            io_master_bid      <= 0;
            io_master_arready  <= 0;
            io_master_rvalid   <= 0;
            io_master_rresp    <= 0;
            io_master_rdata    <= 0;
            io_master_rlast    <= 0;
            io_master_rid      <= 0;
        end else begin
            addr_valid         <= addr_valid_in;
            addr_i             <= addr_i_in;
            io_master_awready  <= io_master_awready_in;
            io_master_wready   <= io_master_wready_in;
            io_master_bvalid   <= io_master_bvalid_in;
            io_master_bresp    <= io_master_bresp_in;
            io_master_bid      <= io_master_bid_in;
            io_master_arready  <= io_master_arready_in;
            io_master_rvalid   <= io_master_rvalid_in;
            io_master_rresp    <= io_master_rresp_in;
            io_master_rdata    <= io_master_rdata_in;
            io_master_rlast    <= io_master_rlast_in;
            io_master_rid      <= io_master_rid_in;
        end
    end

    // ---- 子模块实例化 ----
    wire        icache_ready;
    wire [DATA_WID-1:0] data_o;

    wire        io_master_awvalid;
    wire [31:0] io_master_awaddr;
    wire [3:0]  io_master_awid;
    wire [7:0]  io_master_awlen;
    wire [2:0]  io_master_awsize;
    wire [1:0]  io_master_awburst;

    wire        io_master_wvalid;
    wire [31:0] io_master_wdata;
    wire [3:0]  io_master_wstrb;
    wire        io_master_wlast;

    wire        io_master_bready;

    wire        io_master_arvalid;
    wire [31:0] io_master_araddr;
    wire [3:0]  io_master_arid;
    wire [7:0]  io_master_arlen;
    wire [2:0]  io_master_arsize;
    wire [1:0]  io_master_arburst;

    wire        io_master_rready;

    ysyx_25080209_icache #(
        .DATA_WID  (DATA_WID),
        .BLOCK_WID (BLOCK_WID),
        .BLOCK_NUM (BLOCK_NUM)
    ) u_icache (
        .clk (clock),
        .rst (rst),

        // 用户侧
        .addr_valid   (addr_valid),
        .addr_i       (addr_i),
        .icache_ready (icache_ready),
        .data_o       (data_o),

        // AXI4 - AW
        .io_master_awready (io_master_awready),
        .io_master_awvalid (io_master_awvalid),
        .io_master_awaddr  (io_master_awaddr),
        .io_master_awid    (io_master_awid),
        .io_master_awlen   (io_master_awlen),
        .io_master_awsize  (io_master_awsize),
        .io_master_awburst (io_master_awburst),

        // AXI4 - W
        .io_master_wready (io_master_wready),
        .io_master_wvalid (io_master_wvalid),
        .io_master_wdata  (io_master_wdata),
        .io_master_wstrb  (io_master_wstrb),
        .io_master_wlast  (io_master_wlast),

        // AXI4 - B
        .io_master_bready (io_master_bready),
        .io_master_bvalid (io_master_bvalid),
        .io_master_bresp  (io_master_bresp),
        .io_master_bid    (io_master_bid),

        // AXI4 - AR
        .io_master_arready (io_master_arready),
        .io_master_arvalid (io_master_arvalid),
        .io_master_araddr  (io_master_araddr),
        .io_master_arid    (io_master_arid),
        .io_master_arlen   (io_master_arlen),
        .io_master_arsize  (io_master_arsize),
        .io_master_arburst (io_master_arburst),

        // AXI4 - R
        .io_master_rready (io_master_rready),
        .io_master_rvalid (io_master_rvalid),
        .io_master_rresp  (io_master_rresp),
        .io_master_rdata  (io_master_rdata),
        .io_master_rlast  (io_master_rlast),
        .io_master_rid    (io_master_rid)
    );

    // ---- 输出采样寄存器 ----
    reg        icache_ready_reg;
    reg [DATA_WID-1:0] data_o_reg;

    reg        io_master_awvalid_reg;
    reg [31:0] io_master_awaddr_reg;
    reg [3:0]  io_master_awid_reg;
    reg [7:0]  io_master_awlen_reg;
    reg [2:0]  io_master_awsize_reg;
    reg [1:0]  io_master_awburst_reg;

    reg        io_master_wvalid_reg;
    reg [31:0] io_master_wdata_reg;
    reg [3:0]  io_master_wstrb_reg;
    reg        io_master_wlast_reg;

    reg        io_master_bready_reg;

    reg        io_master_arvalid_reg;
    reg [31:0] io_master_araddr_reg;
    reg [3:0]  io_master_arid_reg;
    reg [7:0]  io_master_arlen_reg;
    reg [2:0]  io_master_arsize_reg;
    reg [1:0]  io_master_arburst_reg;

    reg        io_master_rready_reg;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            icache_ready_reg <= 0;
            data_o_reg       <= 0;

            io_master_awvalid_reg <= 0;
            io_master_awaddr_reg  <= 0;
            io_master_awid_reg    <= 0;
            io_master_awlen_reg   <= 0;
            io_master_awsize_reg  <= 0;
            io_master_awburst_reg <= 0;

            io_master_wvalid_reg  <= 0;
            io_master_wdata_reg   <= 0;
            io_master_wstrb_reg   <= 0;
            io_master_wlast_reg   <= 0;

            io_master_bready_reg  <= 0;

            io_master_arvalid_reg <= 0;
            io_master_araddr_reg  <= 0;
            io_master_arid_reg    <= 0;
            io_master_arlen_reg   <= 0;
            io_master_arsize_reg  <= 0;
            io_master_arburst_reg <= 0;

            io_master_rready_reg  <= 0;
        end else begin
            icache_ready_reg <= icache_ready;
            data_o_reg       <= data_o;

            io_master_awvalid_reg <= io_master_awvalid;
            io_master_awaddr_reg  <= io_master_awaddr;
            io_master_awid_reg    <= io_master_awid;
            io_master_awlen_reg   <= io_master_awlen;
            io_master_awsize_reg  <= io_master_awsize;
            io_master_awburst_reg <= io_master_awburst;

            io_master_wvalid_reg  <= io_master_wvalid;
            io_master_wdata_reg   <= io_master_wdata;
            io_master_wstrb_reg   <= io_master_wstrb;
            io_master_wlast_reg   <= io_master_wlast;

            io_master_bready_reg  <= io_master_bready;

            io_master_arvalid_reg <= io_master_arvalid;
            io_master_araddr_reg  <= io_master_araddr;
            io_master_arid_reg    <= io_master_arid;
            io_master_arlen_reg   <= io_master_arlen;
            io_master_arsize_reg  <= io_master_arsize;
            io_master_arburst_reg <= io_master_arburst;

            io_master_rready_reg  <= io_master_rready;
        end
    end

    assign icache_ready_sampled = icache_ready_reg;
    assign data_o_sampled       = data_o_reg;

    assign io_master_awvalid_sampled = io_master_awvalid_reg;
    assign io_master_awaddr_sampled  = io_master_awaddr_reg;
    assign io_master_awid_sampled    = io_master_awid_reg;
    assign io_master_awlen_sampled   = io_master_awlen_reg;
    assign io_master_awsize_sampled  = io_master_awsize_reg;
    assign io_master_awburst_sampled = io_master_awburst_reg;

    assign io_master_wvalid_sampled  = io_master_wvalid_reg;
    assign io_master_wdata_sampled   = io_master_wdata_reg;
    assign io_master_wstrb_sampled   = io_master_wstrb_reg;
    assign io_master_wlast_sampled   = io_master_wlast_reg;

    assign io_master_bready_sampled  = io_master_bready_reg;

    assign io_master_arvalid_sampled = io_master_arvalid_reg;
    assign io_master_araddr_sampled  = io_master_araddr_reg;
    assign io_master_arid_sampled    = io_master_arid_reg;
    assign io_master_arlen_sampled   = io_master_arlen_reg;
    assign io_master_arsize_sampled  = io_master_arsize_reg;
    assign io_master_arburst_sampled = io_master_arburst_reg;

    assign io_master_rready_sampled  = io_master_rready_reg;

endmodule
