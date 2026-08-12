module ysyx_25080209_IFU #(ADDR_WID = 32, DATA_WID = 32)(
    input clk, rst,
    // 来自 EXU 的下一跳 PC
    input [DATA_WID-1:0] EXU_npc,
    // 输出指令、顺序 PC 和当前 PC
    output reg [DATA_WID-1:0] IFU_ins,
    output      [DATA_WID-1:0] IFU_snpc,   // 组合逻辑输出
    output reg [DATA_WID-1:0] IFU_pc,
    // Handshake with IDU
    output IFU_valid,
    input  IDU_ready,

    // ========== AXI4 接口 ==========
    input 		io_master_awready,
    output 		io_master_awvalid,
    output 	[31:0] 	io_master_awaddr,
    output 	[3:0] 	io_master_awid,
    output 	[7:0] 	io_master_awlen,
    output 	[2:0] 	io_master_awsize,
    output 	[1:0] 	io_master_awburst,
    input 		io_master_wready,
    output 		io_master_wvalid,
    output 	[31:0] 	io_master_wdata,
    output 	[3:0] 	io_master_wstrb,
    output 		io_master_wlast,
    output 		io_master_bready,
    input 		io_master_bvalid,
    input 	[1:0] 	io_master_bresp,
    input 	[3:0] 	io_master_bid,
    input 		io_master_arready,
    output 		io_master_arvalid,
    output 	[31:0] 	io_master_araddr,
    output 	[3:0] 	io_master_arid,
    output 	[7:0] 	io_master_arlen,
    output 	[2:0] 	io_master_arsize,
    output 	[1:0] 	io_master_arburst,
    output 		io_master_rready,
    input 		io_master_rvalid,
    input 	[1:0] 	io_master_rresp,
    input 	[31:0] 	io_master_rdata,
    input 		io_master_rlast,
    input 	[3:0] 	io_master_rid
);

    // ========== IFU 状态机 ==========
    // 0 idle, 1 wait sram and IDU, 2 wait IDU
    reg [1:0] IFU_state, nIFU_state;
    always @(posedge clk) begin
        if(rst) IFU_state <= 0;
        else    IFU_state <= nIFU_state;
    end

    always @(*) begin
        case (IFU_state)
            0: nIFU_state = 1;
            1: if(R_fin) begin
                    if(IDU_ready) nIFU_state = 0;
                    else          nIFU_state = 2;
                end
                else nIFU_state = 1;
            2: if(IDU_ready) nIFU_state = 0;
                else         nIFU_state = 2;
            default: nIFU_state = 0;
        endcase
    end

    always @(*) begin
        case (IFU_state)
            0: begin
                IFU_valid = 0;
                IFU_ins   = ins_old;
            end
            1: if(R_fin) begin
                    IFU_valid = 1;
                    IFU_ins   = ins_new;
                end
                else begin
                    IFU_valid = 0;
                    IFU_ins   = ins_old;
                end
            2: begin
                IFU_valid = 1;
                IFU_ins   = ins_old;
            end
            default: begin
                IFU_valid = 0;
                IFU_ins   = ins_old;
            end
        endcase
    end

    // ========== 指令缓存 ==========
    wire [DATA_WID-1:0] ins_new;
    reg  [DATA_WID-1:0] ins_old;
    always @(posedge clk) begin
        if(rst) ins_old <= 0;
        else if(R_fin) ins_old <= ins_new;
        else ins_old <= ins_old;
    end

    // ========== AXI4 读控制 ==========
    wire AR_work, R_fin, R_res;
    assign AR_work = (IFU_state == 0) || ((IFU_state == 1) && (nIFU_state == 0)) ||
                     ((IFU_state == 2) && (nIFU_state == 0));
    assign R_res   = (R_rtime == 0);
    assign R_fin   = io_master_rvalid && io_master_rready;

    // ========== PC 写使能 ==========
    wire PC_wen;
    assign PC_wen = ((IFU_state == 1) && (nIFU_state == 0)) ||
                    ((IFU_state == 2) && (nIFU_state == 0));

    // ========== 延时计数器（LSFR 测试） ==========
    wire [4:0] AR_wt_init, AW_wt_init, W_wt_init, R_rt_init, B_rt_init;
    assign AR_wt_init = 0;
    assign AW_wt_init = 0;
    assign W_wt_init  = 0;
    assign R_rt_init  = 0;
    assign B_rt_init  = 0;

    reg [4:0] AR_wtime, AW_wtime, W_wtime, R_rtime, B_rtime;
    always @(posedge clk) begin
        if(rst) begin
            AR_wtime <= AR_wt_init;
            AW_wtime <= AW_wt_init;
            W_wtime  <= W_wt_init;
            R_rtime  <= R_rt_init;
            B_rtime  <= B_rt_init;
        end else begin
            AR_wtime <= (AR_wtime != 5'b0) ? AR_wtime - 1 : AR_wt_init;
            AW_wtime <= (AW_wtime != 5'b0) ? AW_wtime - 1 : AW_wt_init;
            W_wtime  <= (W_wtime  != 5'b0) ? W_wtime  - 1 : W_wt_init;
            R_rtime  <= (R_rtime  != 5'b0) ? R_rtime  - 1 : R_rt_init;
            B_rtime  <= (B_rtime  != 5'b0) ? B_rtime  - 1 : B_rt_init;
        end
    end

    // ========== AXI4 地址通道状态机 ==========
    reg AR_state, nAR_state;
    always @(posedge clk) begin
        if(rst) AR_state <= 1'b0;
        else    AR_state <= nAR_state;
    end

    always @(*) begin
        case (AR_state)
            1'b0: nAR_state = AR_work ? 1'b1 : 1'b0;
            1'b1: nAR_state = io_master_arready ? 1'b0 : 1'b1;
            default: nAR_state = 1'b0;
        endcase
    end

    always @(*) begin
        case (AR_state)
            1'b0: io_master_arvalid = 0;
            1'b1: io_master_arvalid = 1;
        endcase
        io_master_rready = R_res ? 1'b1 : 1'b0;
    end

    // ========== AXI4 输出信号（读通道） ==========
    assign io_master_araddr  = IFU_pc;
    assign io_master_arsize  = 3'b010;
    assign io_master_arburst = 2'b01;
    // 其他读通道固定值
    assign io_master_arid    = 0;
    assign io_master_arlen   = 0;

    assign ins_new = io_master_rdata;

    // ========== AXI4 写通道全部置零 ==========
    assign io_master_awvalid = 0;
    assign io_master_awaddr  = 0;
    assign io_master_awid    = 0;
    assign io_master_awlen   = 0;
    assign io_master_awsize  = 0;
    assign io_master_awburst = 0;
    assign io_master_wvalid  = 0;
    assign io_master_wdata   = 0;
    assign io_master_wstrb   = 0;
    assign io_master_wlast   = 0;
    assign io_master_bready  = 0;

    // ========== 响应反馈 ==========
    reg [1:0] bresp, rresp;
    always @(posedge clk) begin
        if(rst) begin
            bresp <= 0;
            rresp <= 0;
        end else begin
            if(io_master_bvalid) bresp <= io_master_bresp;
            if(io_master_rvalid) rresp <= io_master_rresp;
        end
    end

    // ========== 下一跳 PC 选择（组合逻辑） ==========
    reg [ADDR_WID-1:0] dnpc;
    always @(*) begin
        if((bresp != 0) || (rresp != 0))
            dnpc = 0;
        else
            dnpc = EXU_npc;      // 来自 EXU 的目标 PC
    end

    // ========== 指令追踪（DPI-C） ==========
    import "DPI-C" function void itrace(int ins);
    always @(posedge clk) begin
        itrace(IFU_ins);
    end

    // ========== PC 寄存器 ==========
    always @(posedge clk) begin
        if(rst) IFU_pc <= 32'h3000_0000;
        else begin
            if(PC_wen) IFU_pc <= dnpc;
        end
    end

    // 顺序 PC
    assign IFU_snpc = IFU_pc + 32'h4;

    // ========== 寄存器读取监控（DPI-C） ==========
    import "DPI-C" function void read_reg(int val, int num);
    always @(*) begin
        read_reg(IFU_pc, 32);
    end

    // ========== 指令状态通知（DPI-C） ==========
    import "DPI-C" function void ins_state(int state);
    always @(posedge clk) begin
        if(PC_wen) ins_state(1);   // 取指完成
        else       ins_state(0);   // 运行中
    end

    // ========== 性能计数器 ==========
    import "DPI-C" function void IFU_fetch();

    import "DPI-C" function void IDU_U_cyc();
    import "DPI-C" function void IDU_J_cyc();
    import "DPI-C" function void IDU_I_cyc();
    import "DPI-C" function void IDU_Ical_cyc();
    import "DPI-C" function void IDU_B_cyc();
    import "DPI-C" function void IDU_Rcal_cyc();

    import "DPI-C" function void IDU_LOAD_cyc();
    import "DPI-C" function void IDU_STORE_cyc();

    import "DPI-C" function void IDU_CSR_cyc();

    wire [6:0] opcode = IFU_ins[6:0];
    wire [2:0] func3  = IFU_ins[14:12];

    always @(posedge clk) begin
        if(R_fin) IFU_fetch();

        case(opcode)
        7'b0110111:IDU_U_cyc();
        7'b0010111:IDU_U_cyc();
        7'b1101111:IDU_J_cyc();
        7'b1100111:IDU_I_cyc();
        7'b1100011:IDU_B_cyc();
        7'b0000011:IDU_LOAD_cyc();
        7'b0100011:IDU_STORE_cyc();
        7'b0010011:IDU_Ical_cyc();
        7'b0110011:IDU_Rcal_cyc();
        7'b1110011:begin
            if(func3 == 3'b000) IDU_I_cyc();
            else IDU_CSR_cyc();
        end
        default;
        endcase
    end

endmodule
