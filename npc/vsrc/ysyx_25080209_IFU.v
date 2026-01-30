module ysyx_25080209_IFU #(DATA_WID = 32)(
    input clk,rst,
    input [DATA_WID-1:0]pc_next,
    output reg [DATA_WID-1:0]ins,snpc,pc,

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
            IFU_valid = 0;
        end
        1:begin
            IFU_valid = 1;
        end
        default;
    endcase
end

SRAM u_SRAM(
    .clk  	(clk   ),
    .addr 	(pc  ),
    .data 	(ins  )
);

import "DPI-C" function void itrace(int ins);
always @(posedge clk) begin
    itrace(ins);
end
//PC
always @(posedge clk) begin
    if(rst) pc <= 32'h80000000;
    else begin
        if(nIFU_state == 0)  pc <= pc_next;
    end
end

import "DPI-C" function void read_reg(int val,int num);
always @(*) begin
    read_reg(pc,32);
end

assign snpc = pc + 32'h4;

// Mem #(8,32) u_Mem (
//     .clk   	(clk    ),
//     .wdata 	(0  ),
//     .waddr 	(0  ),
//     .raddr 	(pc[7:0]  ),
//     .wen   	(1    ),
//     .rdata 	(ins  )
// );
endmodule
