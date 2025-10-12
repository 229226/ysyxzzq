module ysyx_25080209_CSR #(DATA_WID = 32,ADDR_WID = 12)(
    input clk,wen,ren,
    input [DATA_WID-1:0]wdata,
    input [ADDR_WID-1:0]waddr,raddr,
    output [DATA_WID-1:0]rdata,

    input [DATA_WID-1:0]pc,
    input ecall,
    
    output reg [DATA_WID-1:0]mtvec,mepc
);

reg [DATA_WID-1:0] rf [2**ADDR_WID-1:0];

always @(posedge clk) begin
    if(wen) rf[waddr] <= wdata;
end 

//0x300 mstatus
//0x305 mtvec
//0x341 mepc
//0x342 mcause
always @(posedge clk) begin
    if(ecall) begin
        rf[12'h341] <= pc;
        rf[12'h342] <= 32'hb;
    end 
end

assign mtvec = rf[12'h305];
assign mepc = rf[12'h341];

assign rdata = ren ? rf[raddr] : 32'b0;

endmodule
