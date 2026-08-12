module ysyx_25080209 #(DATA_WID=32,ADDR_WID=32)(
    input clock,reset,
    input io_interrupt,
//AXI4接口 master
    input                   io_master_awready,
    output                  io_master_awvalid,
    output  [ADDR_WID-1:0]  io_master_awaddr,
    output  [3:0]           io_master_awid,
    output  [7:0]           io_master_awlen,
    output  [2:0]           io_master_awsize,
    output  [1:0]           io_master_awburst,
    input                   io_master_wready,
    output                  io_master_wvalid,
    output  [DATA_WID-1:0]  io_master_wdata,
    output  [3:0]           io_master_wstrb,
    output                  io_master_wlast,
    output                  io_master_bready,
    input                   io_master_bvalid,
    input [1:0]             io_master_bresp,
    input [3:0]             io_master_bid,
    input                   io_master_arready,
    output                  io_master_arvalid,
    output  [ADDR_WID-1:0]  io_master_araddr,
    output  [3:0]           io_master_arid,
    output  [7:0]           io_master_arlen,
    output  [2:0]           io_master_arsize,
    output  [1:0]           io_master_arburst,
    output                  io_master_rready,
    input                   io_master_rvalid,
    input [1:0]             io_master_rresp,
    input [DATA_WID-1:0]    io_master_rdata,
    input                   io_master_rlast,
    input [3:0]             io_master_rid,
//AXI4接口 slave
    output                  io_slave_awready,
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
    wire clk = clock;
    wire rst = reset;

    // 关闭未使用的 slave 接口（实际由仲裁器提供）
    assign io_slave_awready = 0;
    assign io_slave_wready  = 0;
    assign io_slave_bvalid  = 0;
    assign io_slave_bresp   = 0;
    assign io_slave_bid     = 0;
    assign io_slave_arready = 0;
    assign io_slave_rvalid  = 0;
    assign io_slave_rresp   = 0;
    assign io_slave_rdata   = 0;
    assign io_slave_rlast   = 0;
    assign io_slave_rid     = 0;

    // ---- IFU 输出 ----
    wire        IFU_valid;
    wire [31:0] IFU_ins;
    wire [31:0] IFU_pc, IFU_snpc;

    // ---- IDU 输出 ----
    wire [31:0] IDU_imm;
    wire [3:0]  IDU_ALU_opcode;
    wire        IDU_ALU_op1;
    wire        IDU_ALU_op2;
    wire [1:0]  IDU_pc_sw;
    wire [2:0]  IDU_wreg_sw;
    wire        IDU_reg_wen;
    wire        IDU_csr_wen, IDU_csr_ren;
    wire        IDU_csr_w_sw;
    wire [31:0] IDU_csr_zimm;
    wire        IDU_ecall;
    wire        IDU_mret;
    wire        IDU_ready, IDU_valid;
    wire [3:0]  IDU_reg_raddr1, IDU_reg_raddr2, IDU_reg_waddr;
    wire        IDU_mem_ren, IDU_mem_wen;
    wire [3:0]  IDU_mem_wmask;
    wire [2:0]  IDU_mem_rmask;

    // ---- EXU 输出 ----
    wire [31:0] EXU_out;
    wire [31:0] EXU_pc_next;
    wire        EXU_reg_wen, EXU_csr_wen, EXU_csr_ren;
    wire        EXU_ready, EXU_valid;

    // ---- LSU 输出 ----
    wire [31:0] LSU_npc;
    wire [31:0] LSU_rdata;
    wire        LSU_reg_wen, LSU_csr_wen, LSU_csr_ren;
    wire        LSU_ready, LSU_valid;

    // ---- WBU 输出 ----
    wire [31:0] WBU_reg_wdata;
    wire [31:0] WBU_csr_wdata;
    wire        WBU_reg_wen, WBU_csr_wen, WBU_csr_ren;
    wire        WBU_ready;

    // ---- CSR 输出 ----
    wire [31:0] CSR_rdata;
    wire [31:0] CSR_mtvec, CSR_mepc;

    // ---- 寄存器文件输出 ----
    wire [31:0] RF_rdata1, RF_rdata2;

    // ---- 内部中间地址 ----
    wire [11:0] CSR_raddr, CSR_waddr;

    // ==================== 子模块实例化 ====================

    // ---------- IFU ----------
    ysyx_25080209_IFU IFU (
        .clk           (clk),
        .rst           (rst),
        .EXU_npc       (LSU_npc),          
        .IFU_pc        (IFU_pc),
        .IFU_snpc      (IFU_snpc),
        .IFU_ins       (IFU_ins),
        .IDU_ready     (IDU_ready),
        .IFU_valid     (IFU_valid),
        // AXI4 master 0
        .io_master_awready (io_master0_awready),
        .io_master_awvalid (io_master0_awvalid),
        .io_master_awaddr  (io_master0_awaddr),
        .io_master_awid    (io_master0_awid),
        .io_master_awlen   (io_master0_awlen),
        .io_master_awsize  (io_master0_awsize),
        .io_master_awburst (io_master0_awburst),
        .io_master_wready  (io_master0_wready),
        .io_master_wvalid  (io_master0_wvalid),
        .io_master_wdata   (io_master0_wdata),
        .io_master_wstrb   (io_master0_wstrb),
        .io_master_wlast   (io_master0_wlast),
        .io_master_bready  (io_master0_bready),
        .io_master_bvalid  (io_master0_bvalid),
        .io_master_bresp   (io_master0_bresp),
        .io_master_bid     (io_master0_bid),
        .io_master_arready (io_master0_arready),
        .io_master_arvalid (io_master0_arvalid),
        .io_master_araddr  (io_master0_araddr),
        .io_master_arid    (io_master0_arid),
        .io_master_arlen   (io_master0_arlen),
        .io_master_arsize  (io_master0_arsize),
        .io_master_arburst (io_master0_arburst),
        .io_master_rready  (io_master0_rready),
        .io_master_rvalid  (io_master0_rvalid),
        .io_master_rresp   (io_master0_rresp),
        .io_master_rdata   (io_master0_rdata),
        .io_master_rlast   (io_master0_rlast),
        .io_master_rid     (io_master0_rid)
    );

    // ---------- IDU ----------
    ysyx_25080209_IDU #(32,4) IDU (
        .clk            (clk),
        .rst            (rst),
        .IFU_valid      (IFU_valid),
        .IFU_instr      (IFU_ins),
        .IDU_imm        (IDU_imm),
        .IDU_ALU_op1    (IDU_ALU_op1),
        .IDU_ALU_op2    (IDU_ALU_op2),
        .IDU_ALU_opcode (IDU_ALU_opcode),
        .IDU_pc_sw      (IDU_pc_sw),
        .IDU_reg_wen    (IDU_reg_wen),
        .IDU_wreg_sw    (IDU_wreg_sw),
        .IDU_reg_raddr1 (IDU_reg_raddr1),
        .IDU_reg_raddr2 (IDU_reg_raddr2),
        .IDU_reg_waddr  (IDU_reg_waddr),
        .IDU_mem_ren    (IDU_mem_ren),
        .IDU_mem_wen    (IDU_mem_wen),
        .IDU_mem_wmask  (IDU_mem_wmask),
        .IDU_mem_rmask  (IDU_mem_rmask),
        .IDU_csr_wen    (IDU_csr_wen),
        .IDU_csr_ren    (IDU_csr_ren),
        .IDU_csr_w_sw   (IDU_csr_w_sw),
        .IDU_csr_zimm   (IDU_csr_zimm),
        .IDU_ecall      (IDU_ecall),
        .IDU_mret       (IDU_mret),
        .EXU_ready      (EXU_ready),
        .IDU_ready      (IDU_ready),
        .IDU_valid      (IDU_valid)
    );

    // ---------- EXU ----------
    ysyx_25080209_EXU EXU (
        .clk            (clk),
        .rst            (rst),
        .IDU_rs1        (RF_rdata1),
        .IDU_rs2        (RF_rdata2),
        .IDU_imm        (IDU_imm),
        .IDU_ALU_op1    (IDU_ALU_op1),
        .IDU_ALU_op2    (IDU_ALU_op2),
        .IDU_ALU_opcode (IDU_ALU_opcode),
        .IDU_pc_sw      (IDU_pc_sw),
        .IDU_ecall      (IDU_ecall),
        .IDU_mret       (IDU_mret),
        .IDU_reg_wen    (IDU_reg_wen),
        .IDU_csr_wen    (IDU_csr_wen),
        .IDU_csr_ren    (IDU_csr_ren),
        .IFU_pc         (IFU_pc),
        .IFU_snpc       (IFU_snpc),
        .CSR_mtvec      (CSR_mtvec),
        .CSR_mepc       (CSR_mepc),
        .LSU_ready      (LSU_ready),
        .IDU_valid      (IDU_valid),
        .EXU_out        (EXU_out),
        .EXU_pc_next    (EXU_pc_next),
        .EXU_reg_wen    (EXU_reg_wen),
        .EXU_csr_wen    (EXU_csr_wen),
        .EXU_csr_ren    (EXU_csr_ren),
        .EXU_ready      (EXU_ready),
        .EXU_valid      (EXU_valid)
    );

    // ---------- LSU ----------
    ysyx_25080209_LSU LSU (
        .clk            (clk),
        .rst            (rst),
        .IDU_mem_ren    (IDU_mem_ren),
        .IDU_mem_wen    (IDU_mem_wen),
        .IDU_mem_wmask  (IDU_mem_wmask),
        .IDU_mem_rmask  (IDU_mem_rmask),
        .EXU_raddr      (EXU_out),
        .EXU_waddr      (EXU_out),
        .EXU_wdata      (RF_rdata2),
        .EXU_npc        (EXU_pc_next),
        .EXU_reg_wen    (EXU_reg_wen),
        .EXU_csr_wen    (EXU_csr_wen),
        .EXU_csr_ren    (EXU_csr_ren),
        .EXU_valid      (EXU_valid),
        .WBU_ready      (WBU_ready),
        .LSU_npc        (LSU_npc),
        .LSU_rdata      (LSU_rdata),
        .LSU_reg_wen    (LSU_reg_wen),
        .LSU_csr_wen    (LSU_csr_wen),
        .LSU_csr_ren    (LSU_csr_ren),
        .LSU_ready      (LSU_ready),
        .LSU_valid      (LSU_valid),
        // AXI4 master 1
        .io_master_awready (io_master1_awready),
        .io_master_awvalid (io_master1_awvalid),
        .io_master_awaddr  (io_master1_awaddr),
        .io_master_awid    (io_master1_awid),
        .io_master_awlen   (io_master1_awlen),
        .io_master_awsize  (io_master1_awsize),
        .io_master_awburst (io_master1_awburst),
        .io_master_wready  (io_master1_wready),
        .io_master_wvalid  (io_master1_wvalid),
        .io_master_wdata   (io_master1_wdata),
        .io_master_wstrb   (io_master1_wstrb),
        .io_master_wlast   (io_master1_wlast),
        .io_master_bready  (io_master1_bready),
        .io_master_bvalid  (io_master1_bvalid),
        .io_master_bresp   (io_master1_bresp),
        .io_master_bid     (io_master1_bid),
        .io_master_arready (io_master1_arready),
        .io_master_arvalid (io_master1_arvalid),
        .io_master_araddr  (io_master1_araddr),
        .io_master_arid    (io_master1_arid),
        .io_master_arlen   (io_master1_arlen),
        .io_master_arsize  (io_master1_arsize),
        .io_master_arburst (io_master1_arburst),
        .io_master_rready  (io_master1_rready),
        .io_master_rvalid  (io_master1_rvalid),
        .io_master_rresp   (io_master1_rresp),
        .io_master_rdata   (io_master1_rdata),
        .io_master_rlast   (io_master1_rlast),
        .io_master_rid     (io_master1_rid)
    );

    // ---------- WBU ----------
    ysyx_25080209_WBU WBU (
        .clk            (clk),
        .rst            (rst),
        .IDU_wreg_sw    (IDU_wreg_sw),
        .IDU_csr_w_sw   (IDU_csr_w_sw),
        .IDU_imm        (IDU_imm),
        .EXU_out        (EXU_out),
        .IFU_snpc       (IFU_snpc),
        .LSU_rdata      (LSU_rdata),
        .LSU_reg_wen    (LSU_reg_wen),
        .LSU_csr_wen    (LSU_csr_wen),
        .LSU_csr_ren    (LSU_csr_ren),
        .CSR_wreg       (CSR_rdata),
        .CSR_wrs1       (RF_rdata1),
        .CSR_wzimm      (IDU_csr_zimm),
        .LSU_valid      (LSU_valid),
        .WBU_reg_wdata  (WBU_reg_wdata),
        .WBU_csr_wdata  (WBU_csr_wdata),
        .WBU_reg_wen    (WBU_reg_wen),
        .WBU_csr_wen    (WBU_csr_wen),
        .WBU_csr_ren    (WBU_csr_ren),
        .WBU_ready      (WBU_ready)
    );

    // ---------- Register File ----------
    RegisterFile #(4,32) Regs (
        .clk    (clk),
        .raddr1 (IDU_reg_raddr1),
        .raddr2 (IDU_reg_raddr2),
        .rdata1 (RF_rdata1),
        .rdata2 (RF_rdata2),
        .waddr  (IDU_reg_waddr),
        .wdata  (WBU_reg_wdata),
        .wen    (WBU_reg_wen)
    );

    // ---------- CSR ----------
    assign CSR_raddr = IDU_imm[11:0];
    assign CSR_waddr = IDU_imm[11:0];

    ysyx_25080209_CSR u_ysyx_25080209_CSR (
        .clk           (clk),
        .rst           (rst),
        .IDU_csr_wen   (WBU_csr_wen),
        .IDU_csr_ren   (WBU_csr_ren),
        .IDU_csr_waddr (CSR_waddr),
        .IDU_csr_raddr (CSR_raddr),
        .WBU_csr_wdata (WBU_csr_wdata),
        .IFU_pc        (IFU_pc),
        .IDU_ecall     (IDU_ecall),
        .CSR_rdata     (CSR_rdata),
        .CSR_mtvec     (CSR_mtvec),
        .CSR_mepc      (CSR_mepc)
    );

//AXI4_Arbiter_Xbar
    //AXI4接口 master0
    wire                  io_master0_awready;
    wire                   io_master0_awvalid;
    wire  [ADDR_WID-1:0]   io_master0_awaddr;
    wire  [3:0]            io_master0_awid;
    wire  [7:0]            io_master0_awlen;
    wire  [2:0]            io_master0_awsize;
    wire  [1:0]            io_master0_awburst;
    wire                  io_master0_wready;
    wire                   io_master0_wvalid;
    wire  [DATA_WID-1:0]   io_master0_wdata;
    wire  [3:0]            io_master0_wstrb;
    wire                   io_master0_wlast;
    wire                   io_master0_bready;
    wire                  io_master0_bvalid;
    wire [1:0]            io_master0_bresp;
    wire [3:0]            io_master0_bid;
    wire                  io_master0_arready;
    wire                   io_master0_arvalid;
    wire  [ADDR_WID-1:0]   io_master0_araddr;
    wire  [3:0]            io_master0_arid;
    wire  [7:0]            io_master0_arlen;
    wire  [2:0]            io_master0_arsize;
    wire  [1:0]            io_master0_arburst;
    wire                   io_master0_rready;
    wire                  io_master0_rvalid;
    wire [1:0]            io_master0_rresp;
    wire [DATA_WID-1:0]   io_master0_rdata;
    wire                  io_master0_rlast;
    wire [3:0]            io_master0_rid;
    //AXI4接口 master1
    wire                  io_master1_awready;
    wire                   io_master1_awvalid;
    wire  [ADDR_WID-1:0]   io_master1_awaddr;
    wire  [3:0]            io_master1_awid;
    wire  [7:0]            io_master1_awlen;
    wire  [2:0]            io_master1_awsize;
    wire  [1:0]            io_master1_awburst;
    wire                  io_master1_wready;
    wire                   io_master1_wvalid;
    wire  [DATA_WID-1:0]   io_master1_wdata;
    wire  [3:0]            io_master1_wstrb;
    wire                   io_master1_wlast;
    wire                   io_master1_bready;
    wire                  io_master1_bvalid;
    wire [1:0]            io_master1_bresp;
    wire [3:0]            io_master1_bid;
    wire                  io_master1_arready;
    wire                   io_master1_arvalid;
    wire  [ADDR_WID-1:0]   io_master1_araddr;
    wire  [3:0]            io_master1_arid;
    wire  [7:0]            io_master1_arlen;
    wire  [2:0]            io_master1_arsize;
    wire  [1:0]            io_master1_arburst;
    wire                   io_master1_rready;
    wire                  io_master1_rvalid;
    wire [1:0]            io_master1_rresp;
    wire [DATA_WID-1:0]   io_master1_rdata;
    wire                  io_master1_rlast;
    wire [3:0]            io_master1_rid;
    //AXI4接口 slave1
    wire                   io_slave1_awready;
    wire                  io_slave1_awvalid;
    wire [31:0]           io_slave1_awaddr;
    wire [3:0]            io_slave1_awid;
    wire [7:0]            io_slave1_awlen;
    wire [2:0]            io_slave1_awsize;
    wire [1:0]            io_slave1_awburst;
    wire                   io_slave1_wready;
    wire                  io_slave1_wvalid;
    wire [31:0]           io_slave1_wdata;
    wire [3:0]            io_slave1_wstrb;
    wire                  io_slave1_wlast;
    wire                  io_slave1_bready;
    wire                   io_slave1_bvalid;
    wire [1:0]             io_slave1_bresp;
    wire [3:0]             io_slave1_bid;
    wire                   io_slave1_arready;
    wire                  io_slave1_arvalid;
    wire [31:0]           io_slave1_araddr;
    wire [3:0]            io_slave1_arid;
    wire [7:0]            io_slave1_arlen;
    wire [2:0]            io_slave1_arsize;
    wire [1:0]            io_slave1_arburst;
    wire                  io_slave1_rready;
    wire                   io_slave1_rvalid;
    wire [1:0]             io_slave1_rresp;
    wire [31:0]            io_slave1_rdata;
    wire                   io_slave1_rlast;
    wire [3:0]             io_slave1_rid;
ysyx_25080209_AXI4_Arbiter_Xbar u_ysyx_25080209_AXI4_Arbiter_Xbar(
    .clk                	(clk                 ),
    .rst                	(rst                 ),
    .io_master0_awready 	(io_master0_awready  ),
    .io_master0_awvalid 	(io_master0_awvalid  ),
    .io_master0_awaddr  	(io_master0_awaddr   ),
    .io_master0_awid    	(io_master0_awid     ),
    .io_master0_awlen   	(io_master0_awlen    ),
    .io_master0_awsize  	(io_master0_awsize   ),
    .io_master0_awburst 	(io_master0_awburst  ),
    .io_master0_wready  	(io_master0_wready   ),
    .io_master0_wvalid  	(io_master0_wvalid   ),
    .io_master0_wdata   	(io_master0_wdata    ),
    .io_master0_wstrb   	(io_master0_wstrb    ),
    .io_master0_wlast   	(io_master0_wlast    ),
    .io_master0_bready  	(io_master0_bready   ),
    .io_master0_bvalid  	(io_master0_bvalid   ),
    .io_master0_bresp   	(io_master0_bresp    ),
    .io_master0_bid     	(io_master0_bid      ),
    .io_master0_arready 	(io_master0_arready  ),
    .io_master0_arvalid 	(io_master0_arvalid  ),
    .io_master0_araddr  	(io_master0_araddr   ),
    .io_master0_arid    	(io_master0_arid     ),
    .io_master0_arlen   	(io_master0_arlen    ),
    .io_master0_arsize  	(io_master0_arsize   ),
    .io_master0_arburst 	(io_master0_arburst  ),
    .io_master0_rready  	(io_master0_rready   ),
    .io_master0_rvalid  	(io_master0_rvalid   ),
    .io_master0_rresp   	(io_master0_rresp    ),
    .io_master0_rdata   	(io_master0_rdata    ),
    .io_master0_rlast   	(io_master0_rlast    ),
    .io_master0_rid     	(io_master0_rid      ),
    .io_master1_awready 	(io_master1_awready  ),
    .io_master1_awvalid 	(io_master1_awvalid  ),
    .io_master1_awaddr  	(io_master1_awaddr   ),
    .io_master1_awid    	(io_master1_awid     ),
    .io_master1_awlen   	(io_master1_awlen    ),
    .io_master1_awsize  	(io_master1_awsize   ),
    .io_master1_awburst 	(io_master1_awburst  ),
    .io_master1_wready  	(io_master1_wready   ),
    .io_master1_wvalid  	(io_master1_wvalid   ),
    .io_master1_wdata   	(io_master1_wdata    ),
    .io_master1_wstrb   	(io_master1_wstrb    ),
    .io_master1_wlast   	(io_master1_wlast    ),
    .io_master1_bready  	(io_master1_bready   ),
    .io_master1_bvalid  	(io_master1_bvalid   ),
    .io_master1_bresp   	(io_master1_bresp    ),
    .io_master1_bid     	(io_master1_bid      ),
    .io_master1_arready 	(io_master1_arready  ),
    .io_master1_arvalid 	(io_master1_arvalid  ),
    .io_master1_araddr  	(io_master1_araddr   ),
    .io_master1_arid    	(io_master1_arid     ),
    .io_master1_arlen   	(io_master1_arlen    ),
    .io_master1_arsize  	(io_master1_arsize   ),
    .io_master1_arburst 	(io_master1_arburst  ),
    .io_master1_rready  	(io_master1_rready   ),
    .io_master1_rvalid  	(io_master1_rvalid   ),
    .io_master1_rresp   	(io_master1_rresp    ),
    .io_master1_rdata   	(io_master1_rdata    ),
    .io_master1_rlast   	(io_master1_rlast    ),
    .io_master1_rid     	(io_master1_rid      ),
    .io_slave0_awready  	(io_master_awready   ),
    .io_slave0_awvalid  	(io_master_awvalid   ),
    .io_slave0_awaddr   	(io_master_awaddr    ),
    .io_slave0_awid     	(io_master_awid      ),
    .io_slave0_awlen    	(io_master_awlen     ),
    .io_slave0_awsize   	(io_master_awsize    ),
    .io_slave0_awburst  	(io_master_awburst   ),
    .io_slave0_wready   	(io_master_wready    ),
    .io_slave0_wvalid   	(io_master_wvalid    ),
    .io_slave0_wdata    	(io_master_wdata     ),
    .io_slave0_wstrb    	(io_master_wstrb     ),
    .io_slave0_wlast    	(io_master_wlast     ),
    .io_slave0_bready   	(io_master_bready    ),
    .io_slave0_bvalid   	(io_master_bvalid    ),
    .io_slave0_bresp    	(io_master_bresp     ),
    .io_slave0_bid      	(io_master_bid       ),
    .io_slave0_arready  	(io_master_arready   ),
    .io_slave0_arvalid  	(io_master_arvalid   ),
    .io_slave0_araddr   	(io_master_araddr    ),
    .io_slave0_arid     	(io_master_arid      ),
    .io_slave0_arlen    	(io_master_arlen     ),
    .io_slave0_arsize   	(io_master_arsize    ),
    .io_slave0_arburst  	(io_master_arburst   ),
    .io_slave0_rready   	(io_master_rready    ),
    .io_slave0_rvalid   	(io_master_rvalid    ),
    .io_slave0_rresp    	(io_master_rresp     ),
    .io_slave0_rdata    	(io_master_rdata     ),
    .io_slave0_rlast    	(io_master_rlast     ),
    .io_slave0_rid      	(io_master_rid       ),
    .io_slave1_awready  	(io_slave1_awready   ),
    .io_slave1_awvalid  	(io_slave1_awvalid   ),
    .io_slave1_awaddr   	(io_slave1_awaddr    ),
    .io_slave1_awid     	(io_slave1_awid      ),
    .io_slave1_awlen    	(io_slave1_awlen     ),
    .io_slave1_awsize   	(io_slave1_awsize    ),
    .io_slave1_awburst  	(io_slave1_awburst   ),
    .io_slave1_wready   	(io_slave1_wready    ),
    .io_slave1_wvalid   	(io_slave1_wvalid    ),
    .io_slave1_wdata    	(io_slave1_wdata     ),
    .io_slave1_wstrb    	(io_slave1_wstrb     ),
    .io_slave1_wlast    	(io_slave1_wlast     ),
    .io_slave1_bready   	(io_slave1_bready    ),
    .io_slave1_bvalid   	(io_slave1_bvalid    ),
    .io_slave1_bresp    	(io_slave1_bresp     ),
    .io_slave1_bid      	(io_slave1_bid       ),
    .io_slave1_arready  	(io_slave1_arready   ),
    .io_slave1_arvalid  	(io_slave1_arvalid   ),
    .io_slave1_araddr   	(io_slave1_araddr    ),
    .io_slave1_arid     	(io_slave1_arid      ),
    .io_slave1_arlen    	(io_slave1_arlen     ),
    .io_slave1_arsize   	(io_slave1_arsize    ),
    .io_slave1_arburst  	(io_slave1_arburst   ),
    .io_slave1_rready   	(io_slave1_rready    ),
    .io_slave1_rvalid   	(io_slave1_rvalid    ),
    .io_slave1_rresp    	(io_slave1_rresp     ),
    .io_slave1_rdata    	(io_slave1_rdata     ),
    .io_slave1_rlast    	(io_slave1_rlast     ),
    .io_slave1_rid      	(io_slave1_rid       )
);
//CLINT
ysyx_25080209_CLINT_AXI4 u_ysyx_25080209_CLINT_AXI4(
    .clk              	(clk               ),
    .rst              	(rst               ),
    .io_slave_awready 	(io_slave1_awready  ),
    .io_slave_awvalid 	(io_slave1_awvalid  ),
    .io_slave_awaddr  	(io_slave1_awaddr   ),
    .io_slave_awid    	(io_slave1_awid     ),
    .io_slave_awlen   	(io_slave1_awlen    ),
    .io_slave_awsize  	(io_slave1_awsize   ),
    .io_slave_awburst 	(io_slave1_awburst  ),
    .io_slave_wready  	(io_slave1_wready   ),
    .io_slave_wvalid  	(io_slave1_wvalid   ),
    .io_slave_wdata   	(io_slave1_wdata    ),
    .io_slave_wstrb   	(io_slave1_wstrb    ),
    .io_slave_wlast   	(io_slave1_wlast    ),
    .io_slave_bready  	(io_slave1_bready   ),
    .io_slave_bvalid  	(io_slave1_bvalid   ),
    .io_slave_bresp   	(io_slave1_bresp    ),
    .io_slave_bid     	(io_slave1_bid      ),
    .io_slave_arready 	(io_slave1_arready  ),
    .io_slave_arvalid 	(io_slave1_arvalid  ),
    .io_slave_araddr  	(io_slave1_araddr   ),
    .io_slave_arid    	(io_slave1_arid     ),
    .io_slave_arlen   	(io_slave1_arlen    ),
    .io_slave_arsize  	(io_slave1_arsize   ),
    .io_slave_arburst 	(io_slave1_arburst  ),
    .io_slave_rready  	(io_slave1_rready   ),
    .io_slave_rvalid  	(io_slave1_rvalid   ),
    .io_slave_rresp   	(io_slave1_rresp    ),
    .io_slave_rdata   	(io_slave1_rdata    ),
    .io_slave_rlast   	(io_slave1_rlast    ),
    .io_slave_rid     	(io_slave1_rid      )
);
endmodule
