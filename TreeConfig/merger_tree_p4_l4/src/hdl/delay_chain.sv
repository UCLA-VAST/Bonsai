`default_nettype none
`timescale 1ps / 1ps

module delay_chain #(
    parameter WIDTH=8, 
    parameter STAGES=1
) 
(
   input wire                 clk,

   input wire [WIDTH-1:0]     in_bus,

   output wire [WIDTH-1:0]    out_bus
);

//Note the shreg_extract=no directs Xilinx to not infer shift registers which
// defeats using this as a pipeline

   (*shreg_extract="no"*) logic [WIDTH-1:0] pipe[STAGES-1:0] = '{default:'0};
   
   integer i;

   always @(posedge clk)
      begin
         pipe[0] <= in_bus;
   
         if (STAGES>1)
         begin
            for (i=1; i<STAGES; i=i+1)
               pipe[i] <= pipe[i-1];
         end
      end
   
   assign out_bus = pipe[STAGES-1];

endmodule

`default_nettype wire