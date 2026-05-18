module ysyx_25080209_npc #(DATA_WID=32,ADDR_WID=32)(
    input clk,rst,
    output [DATA_WID-1:0]ins,pc,snpc
);
//IFU
    //IFUstate
    wire IFU_valid;
ysyx_25080209_IFU IFU (
    .clk(clk),.rst(rst),
    .pc_next(pc_next),.pc(pc),.snpc(snpc),
    .ins( ins),
    
    .AWADDR(AWADDR_m1),.ARADDR(ARADDR_m1),
    .AWVALID(AWVALID_m1),.WVALID(WVALID_m1),
    .BREADY(BREADY_m1),.ARVALID(ARVALID_m1),.RREADY(RREADY_m1),
    .AWREADY(AWREADY_m1),.WREADY(WREADY_m1),.BVALID(BVALID_m1),
    .ARREADY(ARREADY_m1),.RVALID(RVALID_m1),
    .WDATA(WDATA_m1),.RDATA(RDATA_m1),
    .WSTRB(WSTRB_m1),
    .BRESP(BRESP_m1),.RRESP(RRESP_m1),

    .IDU_ready(IDU_ready),.IFU_valid(IFU_valid)
);
//IDU
    wire [DATA_WID-1:0]imm;
    wire [3:0]alu_op;
    wire rs2_imm,IDU_reg_wen,pc_rs1;
    wire [1:0]pc_sw;
    wire [2:0]wreg_sw;
    //IDU_csr
    wire IDU_csr_wen,IDU_csr_ren,csr_w_sw;
    wire [DATA_WID-1:0] csr_zimm;
    //IDU_ecall
    wire ecall;
    //IDU_mret
    wire mret;
    //IDUstate
    wire IDU_ready,IDU_valid;
ysyx_25080209_IDU #(32,4) IDU (
    .clk(clk),.rst(rst),
    .IDU_ins    (ins),
    .imm    (imm),
    .rs2_imm(rs2_imm),
    .alu_op(alu_op),
    .IDU_reg_wen(IDU_reg_wen),
    .wreg_sw(wreg_sw),
    .pc_rs1 (pc_rs1 ),
    .pc_sw  (pc_sw  ),
    .reg_raddr1 (reg_raddr1),.reg_raddr2 (reg_raddr2),.reg_waddr  (reg_waddr),
    .mem_ren  (mem_ren),.mem_wen    (mem_wen),
    .mem_wmask  (mem_wmask),.mem_rmask  (mem_rmask),
    
    .IDU_csr_wen    (IDU_csr_wen ),.IDU_csr_ren    (IDU_csr_ren),
    .csr_w_sw   (csr_w_sw),.csr_zimm   (csr_zimm),

    .ecall      (ecall),

    .mret       (mret),

    .EXU_ready(EXU_ready),.IFU_valid(IFU_valid),.IDU_ready(IDU_ready),.IDU_valid(IDU_valid)
);
//EXU
    wire [DATA_WID-1:0] exu_out,pc_next;
    //中转信号
    wire EXU_reg_wen,EXU_csr_wen,EXU_csr_ren;
    //EXUstate
    wire EXU_ready,EXU_valid;
ysyx_25080209_EXU EXU(
    .clk(clk),.rst(rst),
    .rs1     	(reg_rdata1 ),
    .rs2     	(reg_rdata2 ),
    .imm     	(imm        ),
    .pc         (pc         ),
    .alu_op 	(alu_op     ),
    .rs2_imm 	(rs2_imm    ),
    .pc_rs1     (pc_rs1     ),
    .exu_out    (exu_out    ),

    .snpc       (snpc),
    .pc_sw      (pc_sw),
    .ecall      (ecall),
    .mret       (mret),
    .mtvec      (mtvec_out),
    .mepc       (mepc_out),
    .pc_next    (pc_next),

    .IDU_reg_wen(IDU_reg_wen),.IDU_csr_wen(IDU_csr_wen),.IDU_csr_ren(IDU_csr_ren),
    .EXU_reg_wen(EXU_reg_wen),.EXU_csr_wen(EXU_csr_wen),.EXU_csr_ren(EXU_csr_ren),

    .IDU_valid(IDU_valid),.LSU_ready(LSU_ready),.EXU_ready(EXU_ready),.EXU_valid(EXU_valid)
);
//LSU
    wire mem_ren,mem_wen;
    wire [3:0]mem_wmask;
    wire [DATA_WID-1:0]mem_rdata;
    wire [2:0]mem_rmask;
    //中转信号
    wire LSU_reg_wen,LSU_csr_wen,LSU_csr_ren;
    //LSUstate
    wire LSU_ready,LSU_valid;
ysyx_25080209_LSU LSU(
    .clk(clk),.rst(rst),
    .LSU_ren(mem_ren),.LSU_wen(mem_wen),
    .wmask(mem_wmask),.rmask (mem_rmask),
    .raddr(exu_out),.rdata_out(mem_rdata),
    .waddr(exu_out),.wdata(reg_rdata2),
    
    .AWADDR(AWADDR_m2),.ARADDR(ARADDR_m2),
    .AWVALID(AWVALID_m2),.WVALID(WVALID_m2),
    .BREADY(BREADY_m2),.ARVALID(ARVALID_m2),.RREADY(RREADY_m2),
    .AWREADY(AWREADY_m2),.WREADY(WREADY_m2),.BVALID(BVALID_m2),
    .ARREADY(ARREADY_m2),.RVALID(RVALID_m2),
    .WDATA(WDATA_m2),.RDATA(RDATA_m2),
    .WSTRB(WSTRB_m2),
    .BRESP(BRESP_m2),.RRESP(RRESP_m2),

    .EXU_reg_wen(EXU_reg_wen),.EXU_csr_wen(EXU_csr_wen),.EXU_csr_ren(EXU_csr_ren),
    .LSU_reg_wen(LSU_reg_wen),.LSU_csr_wen(LSU_csr_wen),.LSU_csr_ren(LSU_csr_ren),

    .EXU_valid(EXU_valid),.WBU_ready(WBU_ready),.LSU_ready(LSU_ready),.LSU_valid(LSU_valid)
);
//WBU
    wire WBU_reg_wen,WBU_csr_wen,WBU_csr_ren;
    //WBUstate
    wire WBU_ready;
ysyx_25080209_WBU WBU(
    .clk(clk),.rst(rst),
    .wreg_sw    (wreg_sw),
    .exu_out    (exu_out),
    .imm        (imm    ),
    .mem_wreg  (mem_rdata),
    .csr_wreg   (csr_rdata),

    .csr_w_sw   (csr_w_sw),
    .csr_wrs1   (reg_rdata1),
    .csr_wzimm  (csr_zimm),

    .snpc 	    (snpc  ),
    .reg_wdata  (reg_wdata),
    .csr_wdata  (csr_wdata),

    .LSU_reg_wen(LSU_reg_wen),.LSU_csr_wen(LSU_csr_wen),.LSU_csr_ren(LSU_csr_ren),
    .WBU_reg_wen(WBU_reg_wen),.WBU_csr_wen(WBU_csr_wen),.WBU_csr_ren(WBU_csr_ren),

    .LSU_valid(LSU_valid),.WBU_ready(WBU_ready)
);
//regs
    wire [3:0]reg_raddr1,reg_raddr2,reg_waddr;
    wire [DATA_WID-1:0] reg_wdata,reg_rdata1,reg_rdata2;
RegisterFile #(4,32) Regs (
    .clk    (clk),
    .raddr1 (reg_raddr1),
    .raddr2 (reg_raddr2),
    .rdata1 (reg_rdata1),
    .rdata2 (reg_rdata2),
    .waddr  (reg_waddr),
    .wdata  (reg_wdata),
    .wen    (WBU_reg_wen)
);
//csr
    wire [DATA_WID-1:0] csr_rdata,csr_wdata;
    wire [11:0]csr_raddr,csr_waddr;
    assign csr_raddr = imm[11:0];
    assign csr_waddr = imm[11:0];
    wire [DATA_WID-1:0]mtvec_out,mepc_out;
ysyx_25080209_CSR u_ysyx_25080209_CSR(
    .clk   	(clk    ),
    .rst    (rst    ),

    .wen   	(WBU_csr_wen    ),
    .ren   	(WBU_csr_ren    ),
    .wdata 	(csr_wdata  ),
    .waddr 	(csr_waddr  ),
    .raddr 	(csr_raddr  ),
    .rdata 	(csr_rdata  ),

    .pc     (pc),
    .ecall  (ecall),
    
    .mtvec_out  (mtvec_out),
    .mepc_out   (mepc_out)
);
//diff_test
    import "DPI-C" function void ins_state(int state);
    always @(*) begin
        if(LSU_valid) ins_state(0); //finished
        else ins_state(1);          //running
    end
//AXI4_lite_Arbiter
    wire [ADDR_WID-1:0]AWADDR_m1,ARADDR_m1;
    wire AWVALID_m1,WVALID_m1,BREADY_m1,ARVALID_m1,RREADY_m1;
    wire AWREADY_m1,WREADY_m1,BVALID_m1,ARREADY_m1,RVALID_m1;
    wire [DATA_WID-1:0]WDATA_m1,RDATA_m1;
    wire [3:0]WSTRB_m1;
    wire [1:0]BRESP_m1,RRESP_m1;

    wire [ADDR_WID-1:0]AWADDR_m2,ARADDR_m2;
    wire AWVALID_m2,WVALID_m2,BREADY_m2,ARVALID_m2,RREADY_m2;
    wire AWREADY_m2,WREADY_m2,BVALID_m2,ARREADY_m2,RVALID_m2;
    wire [DATA_WID-1:0]WDATA_m2,RDATA_m2;
    wire [3:0]WSTRB_m2;
    wire [1:0]BRESP_m2,RRESP_m2;

    wire ACLK_sram,ARESETn_sram;
    wire [ADDR_WID-1:0] AWADDR_sram, ARADDR_sram;
    wire AWVALID_sram, WVALID_sram, BREADY_sram, ARVALID_sram, RREADY_sram;
    wire AWREADY_sram, WREADY_sram, BVALID_sram, ARREADY_sram, RVALID_sram;
    wire [DATA_WID-1:0] WDATA_sram, RDATA_sram;
    wire [3:0] WSTRB_sram;
    wire [1:0] BRESP_sram, RRESP_sram;

    wire ACLK_uart,ARESETn_uart;
    wire [ADDR_WID-1:0] AWADDR_uart, ARADDR_uart;
    wire AWVALID_uart, WVALID_uart, BREADY_uart, ARVALID_uart, RREADY_uart;
    wire AWREADY_uart, WREADY_uart, BVALID_uart, ARREADY_uart, RVALID_uart;
    wire [DATA_WID-1:0] WDATA_uart, RDATA_uart;
    wire [3:0] WSTRB_uart;
    wire [1:0] BRESP_uart, RRESP_uart;

    wire ACLK_s2,ARESETn_s2;
    wire [ADDR_WID-1:0] AWADDR_s2, ARADDR_s2;
    wire AWVALID_s2, WVALID_s2, BREADY_s2, ARVALID_s2, RREADY_s2;
    wire AWREADY_s2, WREADY_s2, BVALID_s2, ARREADY_s2, RVALID_s2;
    wire [DATA_WID-1:0] WDATA_s2, RDATA_s2;
    wire [3:0] WSTRB_s2;
    wire [1:0] BRESP_s2, RRESP_s2;
ysyx_25080209_AXI4_lite_Arbiter_Xbar u_axi_arbiter_xbar (
    .ACLK        (clk),
    .ARESETn     (!rst),
    // Master 0 (IFU)
    .AWADDR_m0   (AWADDR_m1),
    .AWVALID_m0  (AWVALID_m1),
    .AWREADY_m0  (AWREADY_m1),
    .WDATA_m0    (WDATA_m1),
    .WSTRB_m0    (WSTRB_m1),
    .WVALID_m0   (WVALID_m1),
    .WREADY_m0   (WREADY_m1),
    .BREADY_m0   (BREADY_m1),
    .BRESP_m0    (BRESP_m1),
    .BVALID_m0   (BVALID_m1),
    .ARADDR_m0   (ARADDR_m1),
    .ARVALID_m0  (ARVALID_m1),
    .ARREADY_m0  (ARREADY_m1),
    .RDATA_m0    (RDATA_m1),
    .RRESP_m0    (RRESP_m1),
    .RREADY_m0   (RREADY_m1),
    .RVALID_m0   (RVALID_m1),
    // Master 1 (LSU)
    .AWADDR_m1   (AWADDR_m2),
    .AWVALID_m1  (AWVALID_m2),
    .AWREADY_m1  (AWREADY_m2),
    .WDATA_m1    (WDATA_m2),
    .WSTRB_m1    (WSTRB_m2),
    .WVALID_m1   (WVALID_m2),
    .WREADY_m1   (WREADY_m2),
    .BREADY_m1   (BREADY_m2),
    .BRESP_m1    (BRESP_m2),
    .BVALID_m1   (BVALID_m2),
    .ARADDR_m1   (ARADDR_m2),
    .ARVALID_m1  (ARVALID_m2),
    .ARREADY_m1  (ARREADY_m2),
    .RDATA_m1    (RDATA_m2),
    .RRESP_m1    (RRESP_m2),
    .RREADY_m1   (RREADY_m2),
    .RVALID_m1   (RVALID_m2),
    // Slave 0 (UART)
    .S0_ACLK     (ACLK_uart),
    .S0_ARESETn  (ARESETn_uart),
    .S0_AWADDR   (AWADDR_uart),
    .S0_AWVALID  (AWVALID_uart),
    .S0_AWREADY  (AWREADY_uart),
    .S0_WDATA    (WDATA_uart),
    .S0_WSTRB    (WSTRB_uart),
    .S0_WVALID   (WVALID_uart),
    .S0_WREADY   (WREADY_uart),
    .S0_BREADY   (BREADY_uart),
    .S0_BRESP    (BRESP_uart),
    .S0_BVALID   (BVALID_uart),
    .S0_ARADDR   (ARADDR_uart),
    .S0_ARVALID  (ARVALID_uart),
    .S0_ARREADY  (ARREADY_uart),
    .S0_RDATA    (RDATA_uart),
    .S0_RRESP    (RRESP_uart),
    .S0_RREADY   (RREADY_uart),
    .S0_RVALID   (RVALID_uart),
    // Slave 1 (SRAM)
    .S1_ACLK     (ACLK_sram),
    .S1_ARESETn  (ARESETn_sram),
    .S1_AWADDR   (AWADDR_sram),
    .S1_AWVALID  (AWVALID_sram),
    .S1_AWREADY  (AWREADY_sram),
    .S1_WDATA    (WDATA_sram),
    .S1_WSTRB    (WSTRB_sram),
    .S1_WVALID   (WVALID_sram),
    .S1_WREADY   (WREADY_sram),
    .S1_BREADY   (BREADY_sram),
    .S1_BRESP    (BRESP_sram),
    .S1_BVALID   (BVALID_sram),
    .S1_ARADDR   (ARADDR_sram),
    .S1_ARVALID  (ARVALID_sram),
    .S1_ARREADY  (ARREADY_sram),
    .S1_RDATA    (RDATA_sram),
    .S1_RRESP    (RRESP_sram),
    .S1_RREADY   (RREADY_sram),
    .S1_RVALID   (RVALID_sram),
    // Slave 2
    .S2_ACLK     (ACLK_s2),
    .S2_ARESETn  (ARESETn_s2),
    .S2_AWADDR   (AWADDR_s2),
    .S2_AWVALID  (AWVALID_s2),
    .S2_AWREADY  (AWREADY_s2),
    .S2_WDATA    (WDATA_s2),
    .S2_WSTRB    (WSTRB_s2),
    .S2_WVALID   (WVALID_s2),
    .S2_WREADY   (WREADY_s2),
    .S2_BREADY   (BREADY_s2),
    .S2_BRESP    (BRESP_s2),
    .S2_BVALID   (BVALID_s2),
    .S2_ARADDR   (ARADDR_s2),
    .S2_ARVALID  (ARVALID_s2),
    .S2_ARREADY  (ARREADY_s2),
    .S2_RDATA    (RDATA_s2),
    .S2_RRESP    (RRESP_s2),
    .S2_RREADY   (RREADY_s2),
    .S2_RVALID   (RVALID_s2)
);
// UART
ysyx_25080209_UART u_uart (
    .ACLK    (ACLK_uart),
    .ARESETn (ARESETn_uart),
    .AWADDR  (AWADDR_uart),
    .AWVALID (AWVALID_uart),
    .AWREADY (AWREADY_uart),
    .WDATA   (WDATA_uart),
    .WSTRB   (WSTRB_uart),
    .WVALID  (WVALID_uart),
    .WREADY  (WREADY_uart),
    .BREADY  (BREADY_uart),
    .BRESP   (BRESP_uart),
    .BVALID  (BVALID_uart),
    .ARADDR  (ARADDR_uart),
    .ARVALID (ARVALID_uart),
    .ARREADY (ARREADY_uart),
    .RDATA   (RDATA_uart),
    .RRESP   (RRESP_uart),
    .RREADY  (RREADY_uart),
    .RVALID  (RVALID_uart)
);
// SRAM_AXI
ysyx_25080209_SRAM_AXI u_SRAM_AXI (
    .ACLK    (ACLK_sram),
    .ARESETn (ARESETn_sram),
    .AWADDR  (AWADDR_sram),
    .AWVALID (AWVALID_sram),
    .AWREADY (AWREADY_sram),
    .WDATA   (WDATA_sram),
    .WSTRB   (WSTRB_sram),
    .WVALID  (WVALID_sram),
    .WREADY  (WREADY_sram),
    .BREADY  (BREADY_sram),
    .BRESP   (BRESP_sram),
    .BVALID  (BVALID_sram),
    .ARADDR  (ARADDR_sram),
    .ARVALID (ARVALID_sram),
    .ARREADY (ARREADY_sram),
    .RDATA   (RDATA_sram),
    .RRESP   (RRESP_sram),
    .RREADY  (RREADY_sram),
    .RVALID  (RVALID_sram)
);
//CLINT
ysyx_25080209_CLINT_AXI4 u_ysyx_25080209_CLINT_AXI4(
    .ACLK    (ACLK_s2),
    .ARESETn (ARESETn_s2),
    .AWADDR  (AWADDR_s2),
    .AWVALID (AWVALID_s2),
    .AWREADY (AWREADY_s2),
    .WDATA   (WDATA_s2),
    .WSTRB   (WSTRB_s2),
    .WVALID  (WVALID_s2),
    .WREADY  (WREADY_s2),
    .BREADY  (BREADY_s2),
    .BRESP   (BRESP_s2),
    .BVALID  (BVALID_s2),
    .ARADDR  (ARADDR_s2),
    .ARVALID (ARVALID_s2),
    .ARREADY (ARREADY_s2),
    .RDATA   (RDATA_s2),
    .RRESP   (RRESP_s2),
    .RREADY  (RREADY_s2),
    .RVALID  (RVALID_s2)
);
endmodule
