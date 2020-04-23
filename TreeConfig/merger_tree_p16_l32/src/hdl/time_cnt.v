`timescale 1 ns/10 ps

module time_cnt
(
    input wire   aclk,
    input wire  ap_start, 
    output wire  time_out
);

localparam [32-1:0]     LP_TIME_VALUE = 32'h7735_9400; // around 8s for 250MHz

reg [32-1:0]        time_cnt = 32'd0;

assign time_out = (time_cnt == 32'd1);

always @(posedge aclk)
begin
    if (ap_start) begin
        time_cnt <= LP_TIME_VALUE;
    end
    else if (time_cnt != 32'd0) begin
        time_cnt <= time_cnt -1;
    end
end

endmodule
