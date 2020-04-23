`timescale 1 ns/10 ps


module MERGER_TREE_P8_L8 #(parameter L = 8, parameter DATA_WIDTH = 32, parameter KEY_WIDTH = 32) (input i_clk,
					   input [DATA_WIDTH*2*L-1:0]   i_fifo,
					   input [2*L-1:0]      i_fifo_empty,
					   input 	      i_fifo_out_ready,
					   output [2*L-1:0]     o_fifo_read, 
					   output 	      o_out_fifo_write,
					   output wire [8*DATA_WIDTH-1:0] o_data);
   parameter log_L = 3;

   wire [2*DATA_WIDTH-1:0] 						  fifo_o_item_3 [7:0];
   wire [DATA_WIDTH-1:0] 						  fifo_i_item_3 [7:0];   
   wire [7:0] 								  fifo_read_3;
   wire [7:0] 								  fifo_write_3;
   wire [7:0] 								  fifo_empty_3;
   wire [7:0] 								  fifo_full_3;      
   
   wire [4*DATA_WIDTH-1:0] 					      fifo_o_item_2 [3:0];
   wire [2*DATA_WIDTH-1:0] 					      fifo_i_item_2 [3:0];   
   wire [3:0] 							      fifo_read_2;
   wire [3:0] 							      fifo_write_2;
   wire [3:0] 							      fifo_empty_2;
   wire [3:0] 							      fifo_full_2;

   wire [8*DATA_WIDTH-1:0] 					      fifo_o_item_1 [1:0];
   wire [4*DATA_WIDTH-1:0] 					      fifo_i_item_1 [1:0];   
   wire [1:0] 							      fifo_read_1;
   wire [1:0] 							      fifo_write_1;
   wire [1:0] 							      fifo_empty_1;
   wire [1:0] 							      fifo_full_1;

   
   genvar						      level, i;   
   generate
     for (level = L; level > 1; level = level/2) begin : IN
	 for (i = 0; i < level; i=i+1) begin
	    if (level == 8) begin
	       MERGER_1 #(.DATA_WIDTH(DATA_WIDTH), .KEY_WIDTH(KEY_WIDTH)) merger(.i_clk(i_clk),
			     .i_fifo_1(i_fifo[DATA_WIDTH*2*i+DATA_WIDTH-1:DATA_WIDTH*2*i]),
			     .i_fifo_1_empty(i_fifo_empty[2*i]),
			     .i_fifo_2(i_fifo[DATA_WIDTH*2*i+DATA_WIDTH+DATA_WIDTH-1:DATA_WIDTH*2*i+DATA_WIDTH]),
			     .i_fifo_2_empty(i_fifo_empty[2*i+1]),
			     .i_fifo_out_ready(~fifo_full_3[i] | fifo_read_3[i]),
			     .o_fifo_1_read(o_fifo_read[2*i]),
			     .o_fifo_2_read(o_fifo_read[2*i+1]),
			     .o_out_fifo_write(fifo_write_3[i]),
			     .o_data(fifo_i_item_3[i]));
	       COUPLER #(DATA_WIDTH) fifo(.i_clk(i_clk),
			    .i_data(fifo_i_item_3[i]),
			    .i_enq(fifo_write_3[i]),
			    .i_deq(fifo_read_3[i]),
			    .o_data(fifo_o_item_3[i]),
			    .o_empty(fifo_empty_3[i]),
			    .o_full(fifo_full_3[i]));	       
	    end
	    else if (level == 4) begin
	       MERGER_2 #(.DATA_WIDTH(DATA_WIDTH), .KEY_WIDTH(KEY_WIDTH)) merger(.i_clk(i_clk),
			     .i_fifo_1(fifo_o_item_3[2*i]),
			     .i_fifo_1_empty(fifo_empty_3[2*i]),
			     .i_fifo_2(fifo_o_item_3[2*i+1]),
			     .i_fifo_2_empty(fifo_empty_3[2*i+1]),
			     .i_fifo_out_ready(~fifo_full_2[i] | fifo_read_2[i]),
			     .o_fifo_1_read(fifo_read_3[2*i]),
			     .o_fifo_2_read(fifo_read_3[2*i+1]),
			     .o_out_fifo_write(fifo_write_2[i]),
			     .o_data(fifo_i_item_2[i]));
	       COUPLER #(2*DATA_WIDTH) fifo(.i_clk(i_clk),
				  .i_data(fifo_i_item_2[i]),
				  .i_enq(fifo_write_2[i]),
				  .i_deq(fifo_read_2[i]),
				  .o_data(fifo_o_item_2[i]),
				  .o_empty(fifo_empty_2[i]),
				  .o_full(fifo_full_2[i]));
	    end
	    else if (level == 2) begin
	       MERGER_4 #(.DATA_WIDTH(DATA_WIDTH), .KEY_WIDTH(KEY_WIDTH)) merger(.i_clk(i_clk),
			     .i_fifo_1(fifo_o_item_2[2*i]),
			     .i_fifo_1_empty(fifo_empty_2[2*i]),
			     .i_fifo_2(fifo_o_item_2[2*i+1]),
			     .i_fifo_2_empty(fifo_empty_2[2*i+1]),
			     .i_fifo_out_ready(~fifo_full_1[i] | fifo_read_1[i]),
			     .o_fifo_1_read(fifo_read_2[2*i]),
			     .o_fifo_2_read(fifo_read_2[2*i+1]),
			     .o_out_fifo_write(fifo_write_1[i]),
			     .o_data(fifo_i_item_1[i]));
	       COUPLER #(4*DATA_WIDTH) fifo(.i_clk(i_clk),
				   .i_data(fifo_i_item_1[i]),
				   .i_enq(fifo_write_1[i]),
				   .i_deq(fifo_read_1[i]),
				   .o_data(fifo_o_item_1[i]),
				   .o_empty(fifo_empty_1[i]),
				   .o_full(fifo_full_1[i]));
	    end
	 end
      end
    endgenerate
   
   MERGER_8 #(.DATA_WIDTH(DATA_WIDTH), .KEY_WIDTH(KEY_WIDTH)) merger(.i_clk(i_clk),
		   .i_fifo_1(fifo_o_item_1[0]),
		   .i_fifo_1_empty(fifo_empty_1[0]),
		   .i_fifo_2(fifo_o_item_1[1]),
		   .i_fifo_2_empty(fifo_empty_1[1]),
		   .i_fifo_out_ready(i_fifo_out_ready),
		   .o_fifo_1_read(fifo_read_1[0]),
		   .o_fifo_2_read(fifo_read_1[1]),
		   .o_out_fifo_write(o_out_fifo_write),
		   .o_data(o_data)
		   );	       
   
endmodule