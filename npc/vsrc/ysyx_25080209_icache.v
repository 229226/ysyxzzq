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

endmodule
