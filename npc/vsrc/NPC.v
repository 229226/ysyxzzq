module NPC (
    input clock,
    input reset
);

    // -------------------------------------------------------------
    // 连接 ysyx_25080209 的 AXI master 到 SRAM_AXI slave 的信号
    // -------------------------------------------------------------
    wire [31:0] awaddr, wdata, araddr;
    wire        awvalid, wvalid, bready, arvalid, rready;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [3:0]  wstrb;
    wire [31:0] rdata;

    // AXI 固定值（单次传输，32 位，FIXED burst）
    wire [3:0]  awid   = 4'b0;
    wire [7:0]  awlen  = 8'b0;
    wire [2:0]  awsize = 3'b010;   // 4 字节
    wire [1:0]  awburst= 2'b00;
    wire        wlast  = 1'b1;     // 单次写，最后一拍即当前拍

    wire [3:0]  arid   = 4'b0;
    wire [7:0]  arlen  = 8'b0;
    wire [2:0]  arsize = 3'b010;
    wire [1:0]  arburst= 2'b00;

    // 来自 master 的输入，SRAM 没有对应的 ID，固定为 0
    wire [3:0]  bid, rid;
    wire        rlast;

    // -------------------------------------------------------------
    // 实例化 CPU 核 (ysyx_25080209)
    // -------------------------------------------------------------
    ysyx_25080209 u_core (
        .clock            (clock),
        .reset            (reset),
        .io_interrupt     (1'b0),               // 无中断

        // ----- master 接口连接到 SRAM_AXI -----
        .io_master_awready(awready),
        .io_master_awvalid(awvalid),
        .io_master_awaddr (awaddr),
        .io_master_awid   (awid),               // 固定值
        .io_master_awlen  (awlen),
        .io_master_awsize (awsize),
        .io_master_awburst(awburst),

        .io_master_wready (wready),
        .io_master_wvalid (wvalid),
        .io_master_wdata  (wdata),
        .io_master_wstrb  (wstrb),
        .io_master_wlast  (wlast),              // 固定为 1

        .io_master_bready (bready),
        .io_master_bvalid (bvalid),
        .io_master_bresp  (bresp),
        .io_master_bid    (bid),                // 固定 0

        .io_master_arready(arready),
        .io_master_arvalid(arvalid),
        .io_master_araddr (araddr),
        .io_master_arid   (arid),
        .io_master_arlen  (arlen),
        .io_master_arsize (arsize),
        .io_master_arburst(arburst),

        .io_master_rready (rready),
        .io_master_rvalid (rvalid),
        .io_master_rresp  (rresp),
        .io_master_rdata  (rdata),
        .io_master_rlast  (rlast),              // 由 rvalid 产生
        .io_master_rid    (rid),                // 固定 0

        // ----- slave 接口不用，全部置 0 -----
        .io_slave_awready (),
        .io_slave_awvalid (1'b0),
        .io_slave_awaddr  (32'b0),
        .io_slave_awid    (4'b0),
        .io_slave_awlen   (8'b0),
        .io_slave_awsize  (3'b0),
        .io_slave_awburst (2'b0),

        .io_slave_wready  (),
        .io_slave_wvalid  (1'b0),
        .io_slave_wdata   (32'b0),
        .io_slave_wstrb   (4'b0),
        .io_slave_wlast   (1'b0),

        .io_slave_bready  (1'b0),
        .io_slave_bvalid  (),
        .io_slave_bresp   (),
        .io_slave_bid     (),

        .io_slave_arready (),
        .io_slave_arvalid (1'b0),
        .io_slave_araddr  (32'b0),
        .io_slave_arid    (4'b0),
        .io_slave_arlen   (8'b0),
        .io_slave_arsize  (3'b0),
        .io_slave_arburst (2'b0),

        .io_slave_rready  (1'b0),
        .io_slave_rvalid  (),
        .io_slave_rresp   (),
        .io_slave_rdata   (),
        .io_slave_rlast   (),
        .io_slave_rid     ()
    );

    // -------------------------------------------------------------
    // 实例化 SRAM_AXI 从设备
    // -------------------------------------------------------------
    ysyx_25080209_MEM_AXI #(
        .ADDR_WID(32),
        .DATA_WID(32)
    ) u_mem (
        .clk    (clock),
        .rst    (reset),

        .AWADDR (awaddr),
        .AWVALID(awvalid),
        .AWREADY(awready),

        .WDATA  (wdata),
        .WSTRB  (wstrb),
        .WVALID (wvalid),
        .WREADY (wready),

        .BREADY (bready),
        .BRESP  (bresp),
        .BVALID (bvalid),

        .ARADDR (araddr),
        .ARVALID(arvalid),
        .ARREADY(arready),

        .RDATA  (rdata),
        .RRESP  (rresp),
        .RREADY (rready),
        .RVALID (rvalid)
    );

    // -------------------------------------------------------------
    // 补全 AXI 信号（ID / RLAST）
    // -------------------------------------------------------------
    assign rlast = rvalid;          // 单次传输，有效数据即最后一拍
    assign bid   = 4'b0;
    assign rid   = 4'b0;

endmodule
