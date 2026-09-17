module ysyx_25080209_icache #(BLOCK_SIZE = 32,BLOCK_NUM = 16)(
    input clk,rst,

    input addr_valid,
    input [31:0] addr_i,
    output reg icache_ready,
    output reg [31:0] data_o,

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
    output 	reg	io_master_arvalid,
    output  reg	[31:0] 	io_master_araddr,
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
localparam OFFSET_LEN = $clog2(BLOCK_SIZE/8);
localparam INDEX_LEN = $clog2(BLOCK_NUM);
localparam TAG_LEN = 32 - OFFSET_LEN - INDEX_LEN;
//{valid[1] tag[TAG_LEN] data[BLOCK_SIZE]}
reg [BLOCK_NUM-1:0][1+TAG_LEN+BLOCK_SIZE-1:0] icache;

localparam ST_WAIT_IFU = 2'd0;
localparam ST_SEARCH   = 2'd1;
localparam ST_WAIT_MEM = 2'd2;
localparam ST_OUTPUT   = 2'd3;
reg [1:0] icache_state, icache_nstate;

reg [31:0] input_addr;

wire [INDEX_LEN-1:0] addr_index = input_addr[INDEX_LEN+OFFSET_LEN-1:OFFSET_LEN];
wire [TAG_LEN-1:0] addr_tag = input_addr[31:INDEX_LEN+OFFSET_LEN];
wire icache_valid = icache[addr_index][1+TAG_LEN+BLOCK_SIZE-1];
wire [TAG_LEN-1:0] icache_tag = icache[addr_index][TAG_LEN+BLOCK_SIZE-1:BLOCK_SIZE];
wire [BLOCK_SIZE-1:0] icache_data = icache[addr_index][BLOCK_SIZE-1:0];
wire hit = icache_valid && (addr_tag == icache_tag);

wire rmem_fin = io_master_rvalid && io_master_rready;

// 取指地址所属的存储器类型由 C++ 侧的 mem_type_of() 判断（见 csrc/io/mem.cpp），
// 这里只把原始物理地址上报，不再自己维护一份地址表。

always @(posedge clk) begin
    if(rst) icache_state <= ST_WAIT_IFU;
    else icache_state <= icache_nstate;
end
always @(*) begin
    case(icache_state)
    ST_WAIT_IFU:begin
        if(addr_valid) icache_nstate = ST_SEARCH;
        else icache_nstate = ST_WAIT_IFU;
    end
    ST_SEARCH:begin
        if(hit) icache_nstate = ST_OUTPUT;
        else icache_nstate = ST_WAIT_MEM;
    end
    ST_WAIT_MEM:begin
        if(rmem_fin) icache_nstate = ST_OUTPUT;
        else icache_nstate = ST_WAIT_MEM;
    end
    ST_OUTPUT:begin
        icache_nstate = ST_WAIT_IFU;
    end
    endcase
end
always @(posedge clk) begin
    if(rst) begin
        input_addr <= 0;

        icache_ready <= 0;
        data_o <= 0;

        io_master_araddr <= 0;
        io_master_arvalid <= 0;
    end
    else begin
        case(icache_state)
        ST_WAIT_IFU:begin
            if(addr_valid) input_addr <= addr_i;
        end
        ST_SEARCH:begin
            if(hit) begin
                icache_ready <= 1;
                data_o <= icache_data;
            end 
            else begin
                io_master_araddr <= input_addr;
                io_master_arvalid <= 1;
            end
        end
        ST_WAIT_MEM:begin
            if(io_master_arready) begin
                io_master_arvalid <= 0;
            end

            if(rmem_fin) begin
                icache[addr_index][1+TAG_LEN+BLOCK_SIZE-1] <= 1;
                icache[addr_index][TAG_LEN+BLOCK_SIZE-1:BLOCK_SIZE] <= addr_tag;
                icache[addr_index][BLOCK_SIZE-1:0] <= io_master_rdata;

                icache_ready <= 1;
                data_o <= io_master_rdata;
            end
        end
        ST_OUTPUT:begin
            input_addr <= 0;
            icache_ready <= 0;
        end
        endcase
    end
end

assign io_master_rready = 1;

`ifndef YOSYS

    // ========== 性能计数器 ==========
    // 每次访问上报原始地址，由 C++ 侧 mem_type_of() 分类后分别统计 hit/miss
    // DPI-C 的 int 形参为 32 位，这里补齐位宽避免 WIDTHEXPAND 警告
    import "DPI-C" function void icache_access(int addr, int is_hit);

    always @(posedge clk) begin
        if(!rst) begin
            case(icache_state)
            ST_SEARCH: icache_access(input_addr, {31'b0, hit});
            default;
            endcase
        end
    end

    // ========== 访问时间与缺失代价 ==========
    // 一次访问的时间按 IFU 拉高 addr_valid 的持续周期算：从拉高那拍数到拉低那拍，
    // 再减 1。减掉的是拉高那一拍——那只是 IFU 把请求递过来，cache 还没开始干活。
    // 命中/缺失分别累加，软件端据此算平均访问时间和平均缺失代价。
    import "DPI-C" function void icache_hit_cycle(int cycles);
    import "DPI-C" function void icache_miss_cycle(int cycles);

    reg [31:0] valid_cycle;     // 这一轮 addr_valid 已经拉高了几拍
    reg        addr_valid_d;    // 上一拍的 addr_valid，用来找下降沿
    reg        curr_hit;        // 本次是否命中（命中与否只在 ST_SEARCH 有效，锁存下来）

    always @(posedge clk) begin
        if(rst) begin
            valid_cycle  <= 0;
            addr_valid_d <= 0;
            curr_hit     <= 0;
        end
        else begin
            addr_valid_d <= addr_valid;

            if(addr_valid) valid_cycle <= valid_cycle + 1;

            // 命中与否只在 ST_SEARCH 那拍有效，先锁存，等上报时状态早变了
            if(icache_state == ST_SEARCH) curr_hit <= hit;

            // addr_valid 拉低，本次取指结束，这时候 valid_cycle 就是总拍数
            if(addr_valid_d && !addr_valid) begin
                if(curr_hit) icache_hit_cycle(valid_cycle);
                else         icache_miss_cycle(valid_cycle);
                valid_cycle <= 0;
            end
        end
    end

`endif

endmodule
