module ysyx_25080209_IFU #(DATA_WID = 32)(
    input clk,rst,
    input [DATA_WID-1:0]pc,
    output reg [DATA_WID-1:0]ins,snpc,

    input IDU_ready,
    output IFU_valid
);
//0 idle
//1 wait_ready
reg IFU_state,nIFU_state;
always @(posedge clk) begin
    if(rst) IFU_state <= 0;
    else IFU_state <= nIFU_state;
end
always @(*) begin
    case (IFU_state)
        0:begin 
            nIFU_state = 1;
        end 
        1:begin
            if(IDU_ready) nIFU_state = 0;
            else nIFU_state = 1;
        end
        default;
    endcase
end
always @(*) begin
    case (IFU_state)
        0:begin
            IFU_valid = 1;
        end
        1:begin
            IFU_valid = 1;
        end
        default;
    endcase
end

import "DPI-C" function void itrace(int ins);
import "DPI-C" function int pmem_read(input int raddr);

always @(*) begin
    ins = pmem_read(pc);
end

always @(posedge clk) begin
    itrace(ins);
end

assign snpc = pc + 32'h4;

endmodule
