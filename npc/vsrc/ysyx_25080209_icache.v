module ysyx_25080209_icache #(DATA_WID = 32,BLOCK_WID = 128,BLOCK_NUM = 4)(
    input clk,rst,

    input addr_valid,
    input [DATA_WID-1:0] addr_i,
    output reg icache_ready,
    output reg [DATA_WID-1:0] data_o,

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
    output 	reg [3:0] 	io_master_arid,
    output 	reg [7:0] 	io_master_arlen,
    output 	reg [2:0] 	io_master_arsize,
    output 	reg [1:0] 	io_master_arburst,

    output 		io_master_rready,
    input 		io_master_rvalid,
    input 	[1:0] 	io_master_rresp,
    input 	[31:0] 	io_master_rdata,
    input 		io_master_rlast,
    input 	[3:0] 	io_master_rid
);
localparam BDATA_NUM = BLOCK_WID/DATA_WID;

localparam TAG_WID      = 32 - OFFSET_WID - INDEX_WID;
localparam INDEX_WID    = $clog2(BLOCK_NUM);
localparam OFFSET_WID   = $clog2(BLOCK_WID/8);

localparam DATA_ADDR_WID = $clog2(DATA_WID/8);
localparam BDATA_OFF_WID = OFFSET_WID - DATA_ADDR_WID;

localparam DATA_HEXLEN = DATA_WID/8;

reg [BLOCK_NUM-1:0]                 icache_valid;
reg [BLOCK_NUM-1:0][TAG_WID-1:0]    icache_tag;
reg [BLOCK_NUM-1:0][BLOCK_WID-1:0]  icache_data;

localparam ST_WAIT_IFU  = 3'd0;
localparam ST_SEARCH    = 3'd1;
localparam ST_WAIT_MEM  = 3'd2;
localparam ST_WAIT_BMEM = 3'd3;
localparam ST_OUTPUT    = 3'd4;
reg [2:0] icache_state, icache_nstate;

reg [BDATA_OFF_WID:0] mem_count;

reg [31:0]  input_addr;
wire [31:0] out_faddr   = {input_addr[31:OFFSET_WID],{OFFSET_WID{1'b0}}};
wire [31:0] out_addr    = out_faddr + mem_count*DATA_HEXLEN + DATA_HEXLEN;

wire [TAG_WID-1:0]      addr_tag    = input_addr[31:INDEX_WID+OFFSET_WID];
wire [INDEX_WID-1:0]    addr_index  = input_addr[INDEX_WID+OFFSET_WID-1:OFFSET_WID];
wire [OFFSET_WID-1:0]   addr_offset = input_addr[OFFSET_WID-1:0];

localparam ADDR_FLASH_BASE = 4'h3;//31:28
localparam ADDR_SDRAM_BASE = 4'ha;//31:28
localparam ADDR_TYPE_FLASH = 0;
localparam ADDR_TYPE_SDRAM = 1;
localparam ADDR_TYPE_OTHER = 3;
reg [1:0] addr_type;
always @(*) begin
    case(input_addr[31:28])
    ADDR_FLASH_BASE:addr_type = ADDR_TYPE_FLASH;
    ADDR_SDRAM_BASE:addr_type = ADDR_TYPE_SDRAM;
    default:addr_type = ADDR_TYPE_OTHER;
    endcase
end

wire                    out_valid   = icache_valid[addr_index];
wire [TAG_WID-1:0]      out_tag     = icache_tag[addr_index];
wire [BLOCK_WID-1:0]    out_bdata   = icache_data[addr_index];

wire [BDATA_OFF_WID-1:0]    bdata_off   = addr_offset[OFFSET_WID-1:DATA_ADDR_WID];
wire [DATA_WID-1:0]         out_data    = out_bdata[bdata_off*DATA_WID+DATA_WID-1 -: DATA_WID];

wire hit = out_valid && (addr_tag == out_tag);

wire ar_fin     = io_master_arvalid && io_master_arready;
wire rmem_fin   = io_master_rvalid && io_master_rready;
wire rmem_last  = &mem_count[BDATA_OFF_WID-1:0];
wire mem_afin   = mem_count[BDATA_OFF_WID]; 

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
        else begin
            case(addr_type)
            ADDR_TYPE_FLASH:icache_nstate = ST_WAIT_MEM;
            ADDR_TYPE_SDRAM:icache_nstate = ST_WAIT_BMEM;
            ADDR_TYPE_OTHER:icache_nstate = ST_WAIT_IFU;
            default:icache_nstate = ST_WAIT_IFU;
            endcase
        end
    end
    ST_WAIT_MEM:begin
        if(mem_afin) icache_nstate = ST_OUTPUT;
        else icache_nstate = ST_WAIT_MEM;
    end
    ST_WAIT_BMEM:begin
        if(mem_afin) icache_nstate = ST_OUTPUT;
        else icache_nstate = ST_WAIT_BMEM;
    end
    ST_OUTPUT:begin
        icache_nstate = ST_WAIT_IFU;
    end
    default:icache_nstate = ST_WAIT_IFU;
    endcase
end
always @(posedge clk) begin
    if(rst) begin
        input_addr <= 0;
    end else begin
        case(icache_state)
        ST_WAIT_IFU:if(addr_valid) input_addr <= addr_i;
        ST_SEARCH:;
        ST_WAIT_MEM:;
        ST_WAIT_BMEM:;
        ST_OUTPUT:;
        default:;
        endcase
    end
end
always @(posedge clk) begin
    if(rst) begin
        icache_ready <= 0;
    end else begin
        case(icache_state)
        ST_WAIT_IFU:;
        ST_SEARCH:if(hit) icache_ready <= 1;
        ST_WAIT_MEM:if(mem_afin) icache_ready <= 1;
        ST_WAIT_BMEM:if(mem_afin) icache_ready <= 1;
        ST_OUTPUT:icache_ready <= 0;
        default:;
        endcase
    end
end
always @(posedge clk) begin
    if(rst) begin
        data_o <= 0;
    end else begin
        case(icache_state)
        ST_WAIT_IFU:;
        ST_SEARCH:if(hit) data_o <= out_data;
        ST_WAIT_MEM:if(mem_afin) data_o <= out_data;
        ST_WAIT_BMEM:if(mem_afin) data_o <= out_data;
        ST_OUTPUT:;
        default:;
        endcase
    end
end
always @(posedge clk) begin
    if(rst) begin
        io_master_araddr <= 0;
    end else begin
        case(icache_state)
        ST_WAIT_IFU:;
        ST_SEARCH:if(!hit) begin
            io_master_araddr    <= out_faddr;
            io_master_arsize    <= 3'b010;//4B
            io_master_arburst   <= 2'b01;//Incrementing burst

            case(addr_type)
            ADDR_TYPE_FLASH:begin
                io_master_arlen <= 0;
            end
            ADDR_TYPE_SDRAM:begin
                io_master_arlen <= BDATA_NUM-1;
            end
            ADDR_TYPE_OTHER:;
            default:;
            endcase
        end 
        ST_WAIT_MEM:if(rmem_fin && !rmem_last) io_master_araddr <= out_addr;
        ST_WAIT_BMEM:;
        ST_OUTPUT:;
        default:;
        endcase
    end
end
always @(posedge clk) begin
    if(rst) begin
        io_master_arvalid <= 0;
    end else begin
        case(icache_state)
        ST_WAIT_IFU:;
        ST_SEARCH:if(!hit) io_master_arvalid <= 1;
        ST_WAIT_MEM:begin
            if(rmem_fin && !rmem_last) io_master_arvalid <= 1;
            if(ar_fin) io_master_arvalid <= 0;
        end
        ST_WAIT_BMEM:if(ar_fin) io_master_arvalid <= 0;
        ST_OUTPUT:;
        default:;
        endcase
    end
end
always @(posedge clk) begin
    if(rst) begin
        mem_count <= 0;
    end else begin
        case(icache_state)
        ST_WAIT_IFU:;
        ST_SEARCH:;
        ST_WAIT_MEM:begin
            if(rmem_fin) mem_count <= mem_count + 1;
        end 
        ST_WAIT_BMEM:if(rmem_fin) mem_count <= mem_count + 1;
        ST_OUTPUT:mem_count <= 0;
        default:;
        endcase
    end
end
always @(posedge clk) begin
    if(rst) begin
    end else begin
        case(icache_state)
        ST_WAIT_IFU:;
        ST_SEARCH:;
        ST_WAIT_MEM:begin
            if(rmem_fin) icache_data[addr_index][mem_count*DATA_WID+DATA_WID-1 -: DATA_WID] <= io_master_rdata;
        end 
        ST_WAIT_BMEM:if(rmem_fin) icache_data[addr_index][mem_count*DATA_WID+DATA_WID-1 -: DATA_WID] <= io_master_rdata;
        ST_OUTPUT:;
        default:;
        endcase
    end
end
always @(posedge clk) begin
    if(rst) begin
    end else begin
        case(icache_state)
        ST_WAIT_IFU:;
        ST_SEARCH:;
        ST_WAIT_MEM:
            if(mem_afin) begin
                icache_valid[addr_index]    <= 1;
                icache_tag[addr_index]      <= addr_tag;
            end
        ST_WAIT_BMEM:
            if(mem_afin) begin
                icache_valid[addr_index]    <= 1;
                icache_tag[addr_index]      <= addr_tag;
            end
        ST_OUTPUT:;
        default:;
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
