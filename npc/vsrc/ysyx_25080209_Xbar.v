module ysyx_25080209_Xbar #(ADDR_WID = 32,DATA_WID = 32) (
    input arbiter_valid,
    output reg xbar_valid,

    // Master接口
    input ACLK,
    input ARESETn,
    // Write Address
    input [ADDR_WID-1:0] AWADDR,
    input AWVALID,
    output reg AWREADY,
    // Write Data
    input [DATA_WID-1:0] WDATA,
    input [3:0] WSTRB,
    input WVALID,
    output reg WREADY,
    // Write Response
    input BREADY,
    output reg [1:0] BRESP,
    output reg BVALID,
    // Read Address
    input [ADDR_WID-1:0] ARADDR,
    input ARVALID,
    output reg ARREADY,
    // Read Data
    output reg [DATA_WID-1:0] RDATA,
    output reg [1:0] RRESP,
    input RREADY,
    output reg RVALID,
    
    // Slave 0接口
    output S0_ACLK,
    output S0_ARESETn,
    // Write Address
    output reg [ADDR_WID-1:0] S0_AWADDR,
    output reg S0_AWVALID,
    input S0_AWREADY,
    // Write Data
    output reg [DATA_WID-1:0] S0_WDATA,
    output reg [3:0] S0_WSTRB,
    output reg S0_WVALID,
    input S0_WREADY,
    // Write Response
    output S0_BREADY,
    input [1:0] S0_BRESP,
    input S0_BVALID,
    // Read Address
    output reg [ADDR_WID-1:0] S0_ARADDR,
    output reg S0_ARVALID,
    input S0_ARREADY,
    // Read Data
    input [DATA_WID-1:0] S0_RDATA,
    input [1:0] S0_RRESP,
    output S0_RREADY,
    input S0_RVALID,
    
    // Slave 1接口
    output S1_ACLK,
    output S1_ARESETn,
    // Write Address
    output reg [ADDR_WID-1:0] S1_AWADDR,
    output reg S1_AWVALID,
    input S1_AWREADY,
    // Write Data
    output reg [DATA_WID-1:0] S1_WDATA,
    output reg [3:0] S1_WSTRB,
    output reg S1_WVALID,
    input S1_WREADY,
    // Write Response
    output S1_BREADY,
    input [1:0] S1_BRESP,
    input S1_BVALID,
    // Read Address
    output reg [ADDR_WID-1:0] S1_ARADDR,
    output reg S1_ARVALID,
    input S1_ARREADY,
    // Read Data
    input [DATA_WID-1:0] S1_RDATA,
    input [1:0] S1_RRESP,
    output S1_RREADY,
    input S1_RVALID,

    // Slave 2接口
    output S2_ACLK,
    output S2_ARESETn,
    // Write Address
    output reg [ADDR_WID-1:0] S2_AWADDR,
    output reg S2_AWVALID,
    input S2_AWREADY,
    // Write Data
    output reg [DATA_WID-1:0] S2_WDATA,
    output reg [3:0] S2_WSTRB,
    output reg S2_WVALID,
    input S2_WREADY,
    // Write Response
    output S2_BREADY,
    input [1:0] S2_BRESP,
    input S2_BVALID,
    // Read Address
    output reg [ADDR_WID-1:0] S2_ARADDR,
    output reg S2_ARVALID,
    input S2_ARREADY,
    // Read Data
    input [DATA_WID-1:0] S2_RDATA,
    input [1:0] S2_RRESP,
    output S2_RREADY,
    input S2_RVALID
);

parameter UART_BASE = 32'ha000_0008;    // UART地址范围
parameter UART_END  = 32'ha000_0008;
parameter SRAM_BASE = 32'h8000_0000;    // SRAM地址范围
parameter SRAM_END  = 32'h8FFF_FFFC;
parameter SLAVE2_BASE = 32'ha000_0000;  // Slave2地址范围
parameter SLAVE2_END  = 32'ha000_0004;

always @(posedge ACLK) begin
    xbar_valid <= 0;
    en_uart <= 0;
    en_sram <= 0;
    en_slave2 <= 0;
    if(arbiter_valid) begin
        if(access_uart) begin
            en_uart <= 1;
            xbar_valid <= 1;
        end 
        else if(access_sram) begin
            en_sram <= 1;
            xbar_valid <= 1;
        end
        else if(access_slave2) begin
            en_slave2 <= 1;
            xbar_valid <= 1;
        end
    end
end

wire access_uart, access_sram, access_slave2;
reg en_uart, en_sram, en_slave2;

assign access_uart = ((AWADDR >= UART_BASE) && (AWADDR <= UART_END)) ||
                     ((ARADDR >= UART_BASE) && (ARADDR <= UART_END));
assign access_sram = ((AWADDR >= SRAM_BASE) && (AWADDR <= SRAM_END)) ||
                     ((ARADDR >= SRAM_BASE) && (ARADDR <= SRAM_END));
assign access_slave2 = ((AWADDR >= SLAVE2_BASE) && (AWADDR <= SLAVE2_END)) ||
                     ((ARADDR >= SLAVE2_BASE) && (ARADDR <= SLAVE2_END));

always @(*) begin
    S0_ACLK = ACLK;
    S1_ACLK = ACLK;
    S2_ACLK = ACLK;
    S0_ARESETn = ARESETn;
    S1_ARESETn = ARESETn;
    S2_ARESETn = ARESETn;
   
    S0_AWADDR = 0;
    S0_WDATA  = 0;
    S0_WSTRB  = 0;
    S1_AWADDR = 0;
    S1_WDATA  = 0;
    S1_WSTRB  = 0;
    S2_AWADDR = 0;
    S2_WDATA  = 0;
    S2_WSTRB  = 0;

    AWREADY = 0;
    WREADY  = 0;
    BVALID  = 0;
    ARREADY = 0;
    RVALID  = 0;
    RRESP   = 0;
    RDATA   = 0;
    BRESP   = 0;

    S0_AWVALID = 0;
    S0_WVALID  = 0;
    S0_BREADY  = 0;
    S0_ARADDR  = 0;
    S0_ARVALID = 0;
    S0_RREADY  = 0;

    S1_AWVALID = 0;
    S1_WVALID  = 0;
    S1_BREADY  = 0;
    S1_ARADDR  = 0;
    S1_ARVALID = 0;
    S1_RREADY  = 0;

    S2_AWVALID = 0;
    S2_WVALID  = 0;
    S2_BREADY  = 0;
    S2_ARADDR  = 0;
    S2_ARVALID = 0;
    S2_RREADY  = 0;

    if(en_uart) begin
        S0_AWVALID = AWVALID;
        S0_AWADDR  = AWADDR;
        AWREADY    = S0_AWREADY;

        S0_WVALID  = WVALID;
        S0_WDATA   = WDATA;
        WREADY     = S0_WREADY;

        S0_BREADY  = BREADY;
        S0_WSTRB   = WSTRB;
        BRESP      = S0_BRESP;

        BVALID     = S0_BVALID;
        S0_ARADDR  = ARADDR;
        S0_ARVALID = ARVALID;
        ARREADY    = S0_ARREADY;
        S0_RREADY  = RREADY;
        RDATA      = S0_RDATA;
        RRESP      = S0_RRESP;
        RVALID     = S0_RVALID;
    end
    else if(en_sram) begin
        S1_AWVALID = AWVALID;
        S1_AWADDR  = AWADDR;
        AWREADY    = S1_AWREADY;

        S1_WVALID  = WVALID;
        S1_WDATA   = WDATA;
        WREADY     = S1_WREADY;

        S1_BREADY  = BREADY;
        S1_WSTRB   = WSTRB;
        BVALID     = S1_BVALID;

        BRESP      = S1_BRESP;
        S1_ARADDR  = ARADDR;
        S1_ARVALID = ARVALID;
        ARREADY    = S1_ARREADY;
        S1_RREADY  = RREADY;
        RDATA      = S1_RDATA;
        RRESP      = S1_RRESP;
        RVALID     = S1_RVALID;
    end
    else if(en_slave2) begin
        S2_AWVALID = AWVALID;
        S2_AWADDR  = AWADDR;
        AWREADY    = S2_AWREADY;

        S2_WVALID  = WVALID;
        S2_WDATA   = WDATA;
        WREADY     = S2_WREADY;

        S2_BREADY  = BREADY;
        S2_WSTRB   = WSTRB;
        BVALID     = S2_BVALID;

        BRESP      = S2_BRESP;
        S2_ARADDR  = ARADDR;
        S2_ARVALID = ARVALID;
        ARREADY    = S2_ARREADY;
        S2_RREADY  = RREADY;
        RDATA      = S2_RDATA;
        RRESP      = S2_RRESP;
        RVALID     = S2_RVALID;
    end
end

endmodule
