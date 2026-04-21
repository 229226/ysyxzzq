module ysyx_25080209_Xbar #(ADDR_WID = 32,DATA_WID = 32) (
    input work,

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
    input S1_RVALID
);
parameter UART_MASK = 20'h1000_0;
parameter SRAM_MASK = 8'h80;

//0 idle
//1 uart
//2 sram
reg [1:0] state,nstate;
always @(posedge ACLK) begin
    if(!ARESETn) state <= 0;
    else state <= nstate;
end
always @(*) begin
    case (state)
    0:begin
        if(work) begin
            if(access_uart) nstate = 1;
            else if(access_sram) nstate = 2;
            else nstate = 0;
        end
        else nstate = 0;
    end 
    1:begin
        if(work) nstate = 1;
        else nstate = 0;
    end
    2:begin
        if(work) nstate = 2;
        else nstate = 0;
    end
    endcase
end
always @(*) begin
    en_uart = 0;
    en_sram = 0;
    case (state)
    1:en_uart = 1;
    2:en_sram = 1;
    endcase
end

wire access_uart,access_sram;
reg en_uart,en_sram;
assign access_uart = (AWADDR[31:12] == UART_MASK) ||
                    (ARADDR[31:12] == UART_MASK);
assign access_sram = (AWADDR[31:24] == SRAM_MASK) ||
                    (ARADDR[31:24] == SRAM_MASK);

always @(*) begin
    S0_ACLK = ACLK;
    S1_ACLK = ACLK;
    S0_ARESETn = ARESETn;
    S1_ARESETn = ARESETn;
    S0_AWADDR   =   AWADDR;
    S1_AWADDR   =   AWADDR;
    S0_WDATA    =   WDATA;
    S1_WDATA    =   WDATA;
    S0_WSTRB    =   WSTRB;
    S1_WSTRB    =   WSTRB;
    
    AWREADY     =   0;
    WREADY      =   0;
    BVALID      =   0;
    ARREADY     =   0;
    RVALID      =   0;
    RRESP       =   0;
    RDATA       =   0;
    BRESP       =   0;

    S0_AWVALID  =   0;
    S0_WVALID   =   0;
    S0_BREADY   =   0;
    S0_ARADDR   =   0;
    S0_ARVALID  =   0;
    S0_RREADY   =   0;

    S1_AWVALID  =   0;
    S1_WVALID   =   0;
    S1_BREADY   =   0;
    S1_ARADDR   =   0;
    S1_ARVALID  =   0;
    S1_RREADY   =   0;

    if(en_uart)begin
        S0_AWVALID  =   AWVALID;
        AWREADY     =   S0_AWREADY;
        S0_WVALID   =   WVALID;
        WREADY      =   S0_WREADY;
        S0_BREADY   =   BREADY;
        BRESP       =   S0_BRESP;
        BVALID      =   S0_BVALID;
        S0_ARADDR   =   ARADDR;
        S0_ARVALID  =   ARVALID;
        ARREADY     =   S0_ARREADY;
        S0_RREADY   =   RREADY;
        RDATA       =   S0_RDATA;
        RRESP       =   S0_RRESP;
        RVALID      =   S0_RVALID;
    end
    else if(en_sram)begin
        S1_AWVALID  =   AWVALID;
        AWREADY     =   S1_AWREADY;
        S1_WVALID   =   WVALID;
        WREADY      =   S1_WREADY;
        S1_BREADY   =   BREADY;
        BVALID      =   S1_BVALID;
        BRESP       =   S1_BRESP;
        S1_ARADDR   =   ARADDR;
        S1_ARVALID  =   ARVALID;
        ARREADY     =   S1_ARREADY;
        S1_RREADY   =   RREADY;
        RDATA       =   S1_RDATA;
        RRESP       =   S1_RRESP;
        RVALID      =   S1_RVALID;
    end
    else begin

    end
end

endmodule
