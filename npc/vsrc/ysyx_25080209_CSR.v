module ysyx_25080209_CSR #(DATA_WID = 32,ADDR_WID = 12)(
    input clk,rst,

    input wen,ren,
    input [DATA_WID-1:0]wdata,
    input [ADDR_WID-1:0]waddr,raddr,
    output reg [DATA_WID-1:0]rdata,

    input [DATA_WID-1:0]pc,
    input ecall,
    
    output [DATA_WID-1:0]mtvec_out,mepc_out
);
//0x300 mstatus.
//0x305 mtvec
//0x341 mepc
//0x342 mcause
reg [DATA_WID-1:0] mstatus,mcause,mtvec,mepc;
always @(posedge clk) begin
    if(rst) begin
        mstatus <= 0;
        mtvec <= 0;
        mepc <= 0;
        mcause <= 0;
    end
    else begin
        if(wen) begin
            case (waddr)
                12'h300:mstatus <= wdata;
                12'h305:mtvec <= wdata;
                12'h341:mepc <= wdata;
                12'h342:mcause <= wdata;
                default;
            endcase
        end
        else begin
            if(ecall) begin
                mepc <= pc;
                mcause <= 32'hb;
            end 
        end
    end
end

always @(*) begin
    if(ren) begin
        case (raddr)
            12'h300:rdata = mstatus;
            12'h305:rdata = mtvec;
            12'h341:rdata = mepc;
            12'h342:rdata = mcause;
            default rdata = 0;
        endcase
    end
end

assign mtvec_out = mtvec;
assign mepc_out = mepc;

endmodule
