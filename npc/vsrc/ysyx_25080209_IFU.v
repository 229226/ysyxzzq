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
    parameter BOOT_PC = 32'h30000000;

    wire R_fin = addr_valid && icache_ready;

    localparam IDLE_ST = 2'd0;
    localparam WAIT_MEM_ST   = 2'd1;
    localparam WAIT_READY = 2'd2;
    reg [1:0] IFU_state, nIFU_state;
    always @(posedge clk) begin
        if(rst) IFU_state <= 0;
        else    IFU_state <= nIFU_state;
    end
    always @(*) begin
        case(IFU_state)
        IDLE_ST:begin
            nIFU_state = WAIT_MEM_ST;
        end
        WAIT_MEM_ST:begin
            if(R_fin) nIFU_state = WAIT_READY;
            else nIFU_state = WAIT_MEM_ST;
        end
        WAIT_READY:begin
            if(IDU_ready) nIFU_state = IDLE_ST;
            else nIFU_state = WAIT_READY;
        end
        default:nIFU_state = IDLE_ST;
        endcase
    end
    always @(posedge clk) begin
        if(rst) begin
            addr_valid <= 0;
            addr_i <= 0;
            IFU_valid <= 0;
        end
        else begin
            case(IFU_state)
            IDLE_ST:begin
                addr_valid <= 1;
                addr_i <= IFU_pc;
            end
            WAIT_MEM_ST:begin
                if(R_fin) begin
                    addr_valid <= 0;

                    IFU_ins <= data_o;
                    IFU_valid <= 1;
                end
            end
            WAIT_READY:begin
                if(IDU_ready) begin
                    IFU_valid <= 0;
                end
            end
            default;
            endcase
        end
    end

    // ========== icache ==========
    reg addr_valid,icache_ready;
    reg [31:0] addr_i,data_o;

    ysyx_25080209_icache #(
    .BLOCK_SIZE(32),
    .BLOCK_NUM(16)
    ) icache (
    .clk(clk),
    .rst(rst),

    .addr_valid(addr_valid),
    .addr_i(addr_i),
    .icache_ready(icache_ready),
    .data_o(data_o),

    .io_master_awready(io_master_awready),
    .io_master_awvalid(io_master_awvalid),
    .io_master_awaddr(io_master_awaddr),
    .io_master_awid(io_master_awid),
    .io_master_awlen(io_master_awlen),
    .io_master_awsize(io_master_awsize),
    .io_master_awburst(io_master_awburst),

    .io_master_wready(io_master_wready),
    .io_master_wvalid(io_master_wvalid),
    .io_master_wdata(io_master_wdata),
    .io_master_wstrb(io_master_wstrb),
    .io_master_wlast(io_master_wlast),

    .io_master_bready(io_master_bready),
    .io_master_bvalid(io_master_bvalid),
    .io_master_bresp(io_master_bresp),
    .io_master_bid(io_master_bid),

    .io_master_arready(io_master_arready),
    .io_master_arvalid(io_master_arvalid),
    .io_master_araddr(io_master_araddr),
    .io_master_arid(io_master_arid),
    .io_master_arlen(io_master_arlen),
    .io_master_arsize(io_master_arsize),
    .io_master_arburst(io_master_arburst),

    .io_master_rready(io_master_rready),
    .io_master_rvalid(io_master_rvalid),
    .io_master_rresp(io_master_rresp),
    .io_master_rdata(io_master_rdata),
    .io_master_rlast(io_master_rlast),
    .io_master_rid(io_master_rid)
    );

    // // ========== IFU_valid无延迟输出 ==========
    // reg IFU_valid_old;
    // always @(posedge clk) begin
    //     if(rst) IFU_valid_old <= 0;
    //     else if(R_fin) begin
    //         if(IDU_ready) begin
    //             IFU_valid_old <= 0;
    //         end else begin
    //             IFU_valid_old <= 1;
    //         end
    //     end else begin
    //         if(IDU_ready) begin
    //             IFU_valid_old <= 0;
    //         end
    //     end
    // end

    // // ========== 指令缓存 ==========
    // wire [DATA_WID-1:0] ins_new;
    // reg  [DATA_WID-1:0] ins_old;
    // always @(posedge clk) begin
    //     if(rst) ins_old <= 0;
    //     else if(R_fin) ins_old <= ins_new;
    //     else ins_old <= ins_old;
    // end

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

    // ========== PC 寄存器 ==========
    wire PC_wen;
    assign PC_wen = IFU_valid && IDU_ready;
    always @(posedge clk) begin
        if(rst) IFU_pc <= BOOT_PC;
        else begin
            if(PC_wen) IFU_pc <= dnpc;
        end
    end

    // 顺序 PC
    assign IFU_snpc = IFU_pc + 32'h4;

`ifndef YOSYS

    // ========== 指令追踪（DPI-C） ==========
    import "DPI-C" function void itrace(int ins);
    always @(posedge clk) begin
        itrace(IFU_ins);
    end

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
    

    import "DPI-C" function void IFU_wait_start();
    import "DPI-C" function void IFU_wait_mem();
    import "DPI-C" function void IFU_update_output();
    import "DPI-C" function void IFU_wait_IDU();

    import "DPI-C" function void INS_EXE(int ins,bit IDU_ready);
    always @(posedge clk) begin
        if(!rst) begin
            if(IFU_state == 0) IFU_wait_start();
            else if((IFU_state == 1) && (R_fin == 1)) IFU_update_output();
            else if((IFU_state == 1) && (R_fin == 0)) IFU_wait_mem();
            else if(IFU_state == 2) IFU_wait_IDU();

        INS_EXE(IFU_ins,IDU_ready);
        end
    end

`endif

endmodule
