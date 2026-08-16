// LSU_test.v
// 顶层测试模块，包含 ysyx_25080209_LSU，输入和输出均插入触发器
module LSU_test #(
    parameter ADDR_WID = 32,
    parameter DATA_WID = 32
)(
    input  wire clock,
    input  wire rst,

    // ---- 所有输入信号（加 _in 后缀） ----
    input  wire                 IDU_mem_ren_in,
    input  wire                 IDU_mem_wen_in,
    input  wire [3:0]           IDU_mem_wmask_in,
    input  wire [2:0]           IDU_mem_rmask_in,
    input  wire [ADDR_WID-1:0]  EXU_raddr_in,
    input  wire [ADDR_WID-1:0]  EXU_waddr_in,
    input  wire [DATA_WID-1:0]  EXU_wdata_in,
    input  wire [ADDR_WID-1:0]  EXU_npc_in,
    input  wire                 EXU_reg_wen_in,
    input  wire                 EXU_csr_wen_in,
    input  wire                 EXU_csr_ren_in,
    input  wire                 EXU_valid_in,
    input  wire                 WBU_ready_in,

    // AXI4 从设备输入
    input  wire                 io_master_awready_in,
    input  wire                 io_master_wready_in,
    input  wire                 io_master_bvalid_in,
    input  wire [1:0]           io_master_bresp_in,
    input  wire [3:0]           io_master_bid_in,
    input  wire                 io_master_arready_in,
    input  wire                 io_master_rvalid_in,
    input  wire [1:0]           io_master_rresp_in,
    input  wire [DATA_WID-1:0]  io_master_rdata_in,
    input  wire                 io_master_rlast_in,
    input  wire [3:0]           io_master_rid_in,

    // ---- 采样后的输出（加 _sampled 后缀） ----
    output wire [ADDR_WID-1:0]  LSU_npc_sampled,
    output wire [DATA_WID-1:0]  LSU_rdata_sampled,
    output wire                 LSU_reg_wen_sampled,
    output wire                 LSU_csr_wen_sampled,
    output wire                 LSU_csr_ren_sampled,
    output wire                 LSU_ready_sampled,
    output wire                 LSU_valid_sampled,

    // AXI4 主输出
    output wire                 io_master_awvalid_sampled,
    output wire [31:0]          io_master_awaddr_sampled,
    output wire [3:0]           io_master_awid_sampled,
    output wire [7:0]           io_master_awlen_sampled,
    output wire [2:0]           io_master_awsize_sampled,
    output wire [1:0]           io_master_awburst_sampled,

    output wire                 io_master_wvalid_sampled,
    output wire [DATA_WID-1:0]  io_master_wdata_sampled,
    output wire [3:0]           io_master_wstrb_sampled,
    output wire                 io_master_wlast_sampled,

    output wire                 io_master_bready_sampled,

    output wire                 io_master_arvalid_sampled,
    output wire [31:0]          io_master_araddr_sampled,
    output wire [3:0]           io_master_arid_sampled,
    output wire [7:0]           io_master_arlen_sampled,
    output wire [2:0]           io_master_arsize_sampled,
    output wire [1:0]           io_master_arburst_sampled,

    output wire                 io_master_rready_sampled
);

    // ---- 输入采样寄存器 ----
    reg                 IDU_mem_ren;
    reg                 IDU_mem_wen;
    reg [3:0]           IDU_mem_wmask;
    reg [2:0]           IDU_mem_rmask;
    reg [ADDR_WID-1:0]  EXU_raddr;
    reg [ADDR_WID-1:0]  EXU_waddr;
    reg [DATA_WID-1:0]  EXU_wdata;
    reg [ADDR_WID-1:0]  EXU_npc;
    reg                 EXU_reg_wen;
    reg                 EXU_csr_wen;
    reg                 EXU_csr_ren;
    reg                 EXU_valid;
    reg                 WBU_ready;
    reg                 io_master_awready;
    reg                 io_master_wready;
    reg                 io_master_bvalid;
    reg [1:0]           io_master_bresp;
    reg [3:0]           io_master_bid;
    reg                 io_master_arready;
    reg                 io_master_rvalid;
    reg [1:0]           io_master_rresp;
    reg [DATA_WID-1:0]  io_master_rdata;
    reg                 io_master_rlast;
    reg [3:0]           io_master_rid;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            IDU_mem_ren      <= 0;
            IDU_mem_wen      <= 0;
            IDU_mem_wmask    <= 0;
            IDU_mem_rmask    <= 0;
            EXU_raddr        <= 0;
            EXU_waddr        <= 0;
            EXU_wdata        <= 0;
            EXU_npc          <= 0;
            EXU_reg_wen      <= 0;
            EXU_csr_wen      <= 0;
            EXU_csr_ren      <= 0;
            EXU_valid        <= 0;
            WBU_ready        <= 0;
            io_master_awready <= 0;
            io_master_wready  <= 0;
            io_master_bvalid  <= 0;
            io_master_bresp   <= 0;
            io_master_bid     <= 0;
            io_master_arready <= 0;
            io_master_rvalid  <= 0;
            io_master_rresp   <= 0;
            io_master_rdata   <= 0;
            io_master_rlast   <= 0;
            io_master_rid     <= 0;
        end else begin
            IDU_mem_ren      <= IDU_mem_ren_in;
            IDU_mem_wen      <= IDU_mem_wen_in;
            IDU_mem_wmask    <= IDU_mem_wmask_in;
            IDU_mem_rmask    <= IDU_mem_rmask_in;
            EXU_raddr        <= EXU_raddr_in;
            EXU_waddr        <= EXU_waddr_in;
            EXU_wdata        <= EXU_wdata_in;
            EXU_npc          <= EXU_npc_in;
            EXU_reg_wen      <= EXU_reg_wen_in;
            EXU_csr_wen      <= EXU_csr_wen_in;
            EXU_csr_ren      <= EXU_csr_ren_in;
            EXU_valid        <= EXU_valid_in;
            WBU_ready        <= WBU_ready_in;
            io_master_awready <= io_master_awready_in;
            io_master_wready  <= io_master_wready_in;
            io_master_bvalid  <= io_master_bvalid_in;
            io_master_bresp   <= io_master_bresp_in;
            io_master_bid     <= io_master_bid_in;
            io_master_arready <= io_master_arready_in;
            io_master_rvalid  <= io_master_rvalid_in;
            io_master_rresp   <= io_master_rresp_in;
            io_master_rdata   <= io_master_rdata_in;
            io_master_rlast   <= io_master_rlast_in;
            io_master_rid     <= io_master_rid_in;
        end
    end

    // ---- 子模块实例化 ----
    wire [ADDR_WID-1:0] LSU_npc;
    wire [DATA_WID-1:0] LSU_rdata;
    wire                LSU_reg_wen;
    wire                LSU_csr_wen;
    wire                LSU_csr_ren;
    wire                LSU_ready;
    wire                LSU_valid;
    wire                io_master_awvalid;
    wire [31:0]         io_master_awaddr;
    wire [3:0]          io_master_awid;
    wire [7:0]          io_master_awlen;
    wire [2:0]          io_master_awsize;
    wire [1:0]          io_master_awburst;
    wire                io_master_wvalid;
    wire [DATA_WID-1:0] io_master_wdata;
    wire [3:0]          io_master_wstrb;
    wire                io_master_wlast;
    wire                io_master_bready;
    wire                io_master_arvalid;
    wire [31:0]         io_master_araddr;
    wire [3:0]          io_master_arid;
    wire [7:0]          io_master_arlen;
    wire [2:0]          io_master_arsize;
    wire [1:0]          io_master_arburst;
    wire                io_master_rready;

    ysyx_25080209_LSU #(
        .ADDR_WID(ADDR_WID),
        .DATA_WID(DATA_WID)
    ) u_LSU (
        .clk                    (clock),
        .rst                    (rst),
        .IDU_mem_ren            (IDU_mem_ren),
        .IDU_mem_wen            (IDU_mem_wen),
        .IDU_mem_wmask          (IDU_mem_wmask),
        .IDU_mem_rmask          (IDU_mem_rmask),
        .EXU_raddr              (EXU_raddr),
        .EXU_waddr              (EXU_waddr),
        .EXU_wdata              (EXU_wdata),
        .EXU_npc                (EXU_npc),
        .EXU_reg_wen            (EXU_reg_wen),
        .EXU_csr_wen            (EXU_csr_wen),
        .EXU_csr_ren            (EXU_csr_ren),
        .EXU_valid              (EXU_valid),
        .WBU_ready              (WBU_ready),
        .LSU_npc                (LSU_npc),
        .LSU_rdata              (LSU_rdata),
        .LSU_reg_wen            (LSU_reg_wen),
        .LSU_csr_wen            (LSU_csr_wen),
        .LSU_csr_ren            (LSU_csr_ren),
        .LSU_ready              (LSU_ready),
        .LSU_valid              (LSU_valid),
        .io_master_awready      (io_master_awready),
        .io_master_awvalid      (io_master_awvalid),
        .io_master_awaddr       (io_master_awaddr),
        .io_master_awid         (io_master_awid),
        .io_master_awlen        (io_master_awlen),
        .io_master_awsize       (io_master_awsize),
        .io_master_awburst      (io_master_awburst),
        .io_master_wready       (io_master_wready),
        .io_master_wvalid       (io_master_wvalid),
        .io_master_wdata        (io_master_wdata),
        .io_master_wstrb        (io_master_wstrb),
        .io_master_wlast        (io_master_wlast),
        .io_master_bready       (io_master_bready),
        .io_master_bvalid       (io_master_bvalid),
        .io_master_bresp        (io_master_bresp),
        .io_master_bid          (io_master_bid),
        .io_master_arready      (io_master_arready),
        .io_master_arvalid      (io_master_arvalid),
        .io_master_araddr       (io_master_araddr),
        .io_master_arid         (io_master_arid),
        .io_master_arlen        (io_master_arlen),
        .io_master_arsize       (io_master_arsize),
        .io_master_arburst      (io_master_arburst),
        .io_master_rready       (io_master_rready),
        .io_master_rvalid       (io_master_rvalid),
        .io_master_rresp        (io_master_rresp),
        .io_master_rdata        (io_master_rdata),
        .io_master_rlast        (io_master_rlast),
        .io_master_rid          (io_master_rid)
    );

    // ---- 输出采样寄存器 ----
    reg [ADDR_WID-1:0] LSU_npc_reg;
    reg [DATA_WID-1:0] LSU_rdata_reg;
    reg                LSU_reg_wen_reg;
    reg                LSU_csr_wen_reg;
    reg                LSU_csr_ren_reg;
    reg                LSU_ready_reg;
    reg                LSU_valid_reg;
    reg                io_master_awvalid_reg;
    reg [31:0]         io_master_awaddr_reg;
    reg [3:0]          io_master_awid_reg;
    reg [7:0]          io_master_awlen_reg;
    reg [2:0]          io_master_awsize_reg;
    reg [1:0]          io_master_awburst_reg;
    reg                io_master_wvalid_reg;
    reg [DATA_WID-1:0] io_master_wdata_reg;
    reg [3:0]          io_master_wstrb_reg;
    reg                io_master_wlast_reg;
    reg                io_master_bready_reg;
    reg                io_master_arvalid_reg;
    reg [31:0]         io_master_araddr_reg;
    reg [3:0]          io_master_arid_reg;
    reg [7:0]          io_master_arlen_reg;
    reg [2:0]          io_master_arsize_reg;
    reg [1:0]          io_master_arburst_reg;
    reg                io_master_rready_reg;

    always @(posedge clock or posedge rst) begin
        if (rst) begin
            LSU_npc_reg          <= 0;
            LSU_rdata_reg        <= 0;
            LSU_reg_wen_reg      <= 0;
            LSU_csr_wen_reg      <= 0;
            LSU_csr_ren_reg      <= 0;
            LSU_ready_reg        <= 0;
            LSU_valid_reg        <= 0;
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
            LSU_npc_reg          <= LSU_npc;
            LSU_rdata_reg        <= LSU_rdata;
            LSU_reg_wen_reg      <= LSU_reg_wen;
            LSU_csr_wen_reg      <= LSU_csr_wen;
            LSU_csr_ren_reg      <= LSU_csr_ren;
            LSU_ready_reg        <= LSU_ready;
            LSU_valid_reg        <= LSU_valid;
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

    // ---- 采样输出赋值 ----
    assign LSU_npc_sampled          = LSU_npc_reg;
    assign LSU_rdata_sampled        = LSU_rdata_reg;
    assign LSU_reg_wen_sampled      = LSU_reg_wen_reg;
    assign LSU_csr_wen_sampled      = LSU_csr_wen_reg;
    assign LSU_csr_ren_sampled      = LSU_csr_ren_reg;
    assign LSU_ready_sampled        = LSU_ready_reg;
    assign LSU_valid_sampled        = LSU_valid_reg;

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
