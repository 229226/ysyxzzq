module LSFR(
    input clk,rst,
    output reg [4:0]data
);

wire feedback;

always @(posedge clk) begin
    if(rst) data <= 5'b00001;
    else begin
        data <= {data[3:0],feedback};
    end
end

assign feedback = data[4]^data[1];
endmodule
