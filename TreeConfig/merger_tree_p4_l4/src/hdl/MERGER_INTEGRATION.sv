// note
// 

// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module MERGER_INTEGRATION #(
  parameter integer C_AXIS_TDATA_WIDTH = 512, 
  parameter integer C_SORTER_BIT_WIDTH  = 32,
  parameter integer NUM_READ_CHANNELS = 16,
  parameter integer C_NUM_CLOCKS       = 1
)
(

  input wire                                                     s_axis_aclk,
  input wire                                                     s_axis_areset,

  input wire [NUM_READ_CHANNELS-1:0]                             s_axis_tvalid,
  output wire [NUM_READ_CHANNELS-1:0]                            s_axis_tready,
  input wire [NUM_READ_CHANNELS-1:0] [C_AXIS_TDATA_WIDTH-1:0]    s_axis_tdata,
  input wire [NUM_READ_CHANNELS-1:0]                             s_axis_tlast,

  input wire                                                     m_axis_aclk,
  input wire                                                     m_axis_areset,

  output wire                                                    m_axis_tvalid,
  input  wire                                                    m_axis_tready,
  output wire [C_AXIS_TDATA_WIDTH-1:0]                           m_axis_tdata,
  output wire [C_AXIS_TDATA_WIDTH/8-1:0]                         m_axis_tkeep,
  output wire                                                    m_axis_tlast

);

timeunit 1ps;
timeprecision 1ps;

localparam integer LP_NUM_LOOPS = C_AXIS_TDATA_WIDTH/C_SORTER_BIT_WIDTH;
/////////////////////////////////////////////////////////////////////////////
// Variables
/////////////////////////////////////////////////////////////////////////////
localparam L = NUM_READ_CHANNELS/2;
localparam P = 4;
localparam LP_KEY_WIDTH = 32;

// signals for merger kernel
// input signals
wire [C_SORTER_BIT_WIDTH-1:0] 	    in_fifo [0:2*L-1];
wire [2*L-1:0]                      write_fifo;
wire [2*L-1:0]                      fifo_read;
// output signals
wire [C_SORTER_BIT_WIDTH-1:0]       out_fifo [0:2*L-1];
wire [2*L-1:0]                      fifo_full;
wire [2*L-1:0]                      fifo_empty;

// IFIFO16 signals
wire                                o_out_fifo_write;
wire                                fifo_out_full;
wire                                fifo_out_empty;
wire [P*C_SORTER_BIT_WIDTH-1:0]     o_data;
wire [P*C_SORTER_BIT_WIDTH-1:0]     out_fifo_item;

wire                                read_fifo_out;
wire                                fifo_out_i_deq;

/////////////////////////////////////////////////////////////////////////////
// Merger Logic
/////////////////////////////////////////////////////////////////////////////
assign read_fifo_out = ~fifo_out_empty;

// prepare data for leaf nodes
genvar k;
generate
  for (k = 0; k < NUM_READ_CHANNELS; k++) begin: fifo_read_ctrl
  axi_read_controller #(
    .C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
    .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
  )
  axi_read_controller_inst(
    .s_axis_aclk(s_axis_aclk),
    .s_axis_areset(s_axis_areset),

    .s_axis_tvalid(s_axis_tvalid[k]),
    .s_axis_tready(s_axis_tready[k]),
    .s_axis_tdata(s_axis_tdata[k]),
    .s_axis_tlast(s_axis_tlast[k]),

    .fifo_full(fifo_full[k]),
    .in_fifo_data(in_fifo[k]),
    .in_fifo_en(write_fifo[k])
  );
  end
  
  endgenerate

// Merger tree function
genvar 		   fifo_index;
generate
    for (fifo_index = 0; fifo_index < 2*L; fifo_index = fifo_index + 1) begin : IN
    IFIFO16 #(C_SORTER_BIT_WIDTH) fifo(
                        .i_clk(s_axis_aclk),
                        .i_data(in_fifo[fifo_index]),
                        .i_enq(write_fifo[fifo_index]),
                        .o_data(out_fifo[fifo_index]),
                        .i_deq(fifo_read[fifo_index]),
                        .o_empty(fifo_empty[fifo_index]),
                        .o_full(fifo_full[fifo_index])
                        ); 
    end // block: IN
endgenerate

IFIFO16 #(P*C_SORTER_BIT_WIDTH) fifo_out(
        .i_clk(s_axis_aclk),
		    .i_data(o_data),
		    .i_enq(o_out_fifo_write),
		    .o_data(out_fifo_item),
		    .i_deq(fifo_out_i_deq),
		    .o_empty(fifo_out_empty),
		    .o_full(fifo_out_full)
);

MERGER_TREE_P4_L4 #(
  .L(L),
  .DATA_WIDTH(C_SORTER_BIT_WIDTH),
  .KEY_WIDTH(LP_KEY_WIDTH)
)
dut (
  .i_clk(s_axis_aclk),
  .i_fifo({out_fifo[7], out_fifo[6], out_fifo[5], out_fifo[4], 
      out_fifo[3], out_fifo[2], out_fifo[1], out_fifo[0]}),
  .i_fifo_empty(fifo_empty),			  
  .i_fifo_out_ready(~fifo_out_full | fifo_out_i_deq),
  .o_fifo_read(fifo_read),		  
  .o_out_fifo_write(o_out_fifo_write),
  .o_data(o_data)
);


axi_write_controller #(
	.C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
	.C_SORTER_BIT_WIDTH(P*C_SORTER_BIT_WIDTH)
)
axi_write_controller_inst_0(
	.m_axis_aclk(m_axis_aclk),
  .m_axis_areset(m_axis_areset),

  .m_axis_tvalid(m_axis_tvalid),
  .m_axis_tready(m_axis_tready),
  .m_axis_tdata(m_axis_tdata),
  .m_axis_tkeep(m_axis_tkeep),
  .m_axis_tlast(m_axis_tlast),

  .read_fifo_out(read_fifo_out),
  .out_fifo_item(out_fifo_item),
  .fifo_out_i_deq(fifo_out_i_deq)
);


endmodule : MERGER_INTEGRATION

`default_nettype wire