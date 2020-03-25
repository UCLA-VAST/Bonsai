// note
// 

// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1ps / 1ps

module MERGER_INTEGRATION #(
  parameter integer C_AXIS00_TDATA_WIDTH = 512, 
  parameter integer C_AXIS01_TDATA_WIDTH = 512, 
  parameter integer C_AXIS02_TDATA_WIDTH = 512, 
  parameter integer C_AXIS03_TDATA_WIDTH = 512, 
  parameter integer C_AXIS04_TDATA_WIDTH = 512, 
  parameter integer C_AXIS05_TDATA_WIDTH = 512, 
  parameter integer C_AXIS06_TDATA_WIDTH = 512, 
  parameter integer C_AXIS07_TDATA_WIDTH = 512, 
  parameter integer C_AXIS08_TDATA_WIDTH = 512, 
  parameter integer C_SORTER_BIT_WIDTH  = 32,
  parameter integer C_NUM_CLOCKS       = 1
)
(

  input wire                                s_axis_aclk,
  input wire                                s_axis_areset,

  input wire                                s00_axis_tvalid,
  output wire                               s00_axis_tready,
  input wire  [C_AXIS00_TDATA_WIDTH-1:0]    s00_axis_tdata,
  input wire  [C_AXIS00_TDATA_WIDTH/8-1:0]  s00_axis_tkeep,
  input wire                                s00_axis_tlast,

  input wire                                s01_axis_tvalid,
  output wire                               s01_axis_tready,
  input wire  [C_AXIS01_TDATA_WIDTH-1:0]    s01_axis_tdata,
  input wire  [C_AXIS01_TDATA_WIDTH/8-1:0]  s01_axis_tkeep,
  input wire                                s01_axis_tlast,

  input wire                                s02_axis_tvalid,
  output wire                               s02_axis_tready,
  input wire  [C_AXIS02_TDATA_WIDTH-1:0]    s02_axis_tdata,
  input wire  [C_AXIS02_TDATA_WIDTH/8-1:0]  s02_axis_tkeep,
  input wire                                s02_axis_tlast,

  input wire                                s03_axis_tvalid,
  output wire                               s03_axis_tready,
  input wire  [C_AXIS03_TDATA_WIDTH-1:0]    s03_axis_tdata,
  input wire  [C_AXIS03_TDATA_WIDTH/8-1:0]  s03_axis_tkeep,
  input wire                                s03_axis_tlast,

  input wire                                s04_axis_tvalid,
  output wire                               s04_axis_tready,
  input wire  [C_AXIS04_TDATA_WIDTH-1:0]    s04_axis_tdata,
  input wire  [C_AXIS04_TDATA_WIDTH/8-1:0]  s04_axis_tkeep,
  input wire                                s04_axis_tlast,

  input wire                                s05_axis_tvalid,
  output wire                               s05_axis_tready,
  input wire  [C_AXIS05_TDATA_WIDTH-1:0]    s05_axis_tdata,
  input wire  [C_AXIS05_TDATA_WIDTH/8-1:0]  s05_axis_tkeep,
  input wire                                s05_axis_tlast,

  input wire                                s06_axis_tvalid,
  output wire                               s06_axis_tready,
  input wire  [C_AXIS06_TDATA_WIDTH-1:0]    s06_axis_tdata,
  input wire  [C_AXIS06_TDATA_WIDTH/8-1:0]  s06_axis_tkeep,
  input wire                                s06_axis_tlast,

  input wire                                s07_axis_tvalid,
  output wire                               s07_axis_tready,
  input wire  [C_AXIS07_TDATA_WIDTH-1:0]    s07_axis_tdata,
  input wire  [C_AXIS07_TDATA_WIDTH/8-1:0]  s07_axis_tkeep,
  input wire                                s07_axis_tlast,

  input wire                                m_axis_aclk,
  input wire                                m_axis_areset,

  output wire                               m_axis_tvalid,
  input  wire                               m_axis_tready,
  output wire [C_AXIS08_TDATA_WIDTH-1:0]    m_axis_tdata,
  output wire [C_AXIS08_TDATA_WIDTH/8-1:0]  m_axis_tkeep,
  output wire                               m_axis_tlast

);

localparam integer LP_NUM_LOOPS = C_AXIS00_TDATA_WIDTH/C_SORTER_BIT_WIDTH;
/////////////////////////////////////////////////////////////////////////////
// Variables
/////////////////////////////////////////////////////////////////////////////
localparam L = 4;
localparam P = 4;
localparam LP_KEY_WIDTH = 32;

// signals for merger kernel
// input signals
wire [C_SORTER_BIT_WIDTH-1:0] 	    in_fifo [0:2*L-1];
wire [2*L-1:0]                      write_fifo;
wire [2*L-1:0]                      fifo_read;
// output signals
wire [C_SORTER_BIT_WIDTH-1:0]         out_fifo [0:2*L-1];
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

// prepare data for leaf 00
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS00_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst00(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s00_axis_tvalid),
  .s_axis_tready(s00_axis_tready),
  .s_axis_tdata(s00_axis_tdata),
  .s_axis_tkeep(s00_axis_tkeep),
  .s_axis_tlast(s00_axis_tlast),

  .fifo_full(fifo_full[0]),
  .in_fifo_data(in_fifo[0]),
  .in_fifo_en(write_fifo[0])
);
// prepare data for leaf 01
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS01_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst01(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s01_axis_tvalid),
  .s_axis_tready(s01_axis_tready),
  .s_axis_tdata(s01_axis_tdata),
  .s_axis_tkeep(s01_axis_tkeep),
  .s_axis_tlast(s01_axis_tlast),

  .fifo_full(fifo_full[1]),
  .in_fifo_data(in_fifo[1]),
  .in_fifo_en(write_fifo[1])
);
// prepare data for leaf 02
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS02_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst02(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s02_axis_tvalid),
  .s_axis_tready(s02_axis_tready),
  .s_axis_tdata(s02_axis_tdata),
  .s_axis_tkeep(s02_axis_tkeep),
  .s_axis_tlast(s02_axis_tlast),

  .fifo_full(fifo_full[2]),
  .in_fifo_data(in_fifo[2]),
  .in_fifo_en(write_fifo[2])
);
// prepare data for leaf 03
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS03_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst03(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s03_axis_tvalid),
  .s_axis_tready(s03_axis_tready),
  .s_axis_tdata(s03_axis_tdata),
  .s_axis_tkeep(s03_axis_tkeep),
  .s_axis_tlast(s03_axis_tlast),

  .fifo_full(fifo_full[3]),
  .in_fifo_data(in_fifo[3]),
  .in_fifo_en(write_fifo[3])
);
// prepare data for leaf 04
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS04_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst04(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s04_axis_tvalid),
  .s_axis_tready(s04_axis_tready),
  .s_axis_tdata(s04_axis_tdata),
  .s_axis_tkeep(s04_axis_tkeep),
  .s_axis_tlast(s04_axis_tlast),

  .fifo_full(fifo_full[4]),
  .in_fifo_data(in_fifo[4]),
  .in_fifo_en(write_fifo[4])
);
// prepare data for leaf 05
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS05_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst05(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s05_axis_tvalid),
  .s_axis_tready(s05_axis_tready),
  .s_axis_tdata(s05_axis_tdata),
  .s_axis_tkeep(s05_axis_tkeep),
  .s_axis_tlast(s05_axis_tlast),

  .fifo_full(fifo_full[5]),
  .in_fifo_data(in_fifo[5]),
  .in_fifo_en(write_fifo[5])
);
// prepare data for leaf 06
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS06_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst06(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s06_axis_tvalid),
  .s_axis_tready(s06_axis_tready),
  .s_axis_tdata(s06_axis_tdata),
  .s_axis_tkeep(s06_axis_tkeep),
  .s_axis_tlast(s06_axis_tlast),

  .fifo_full(fifo_full[6]),
  .in_fifo_data(in_fifo[6]),
  .in_fifo_en(write_fifo[6])
);
// prepare data for leaf 07
axi_read_controller #(
  .C_AXIS_TDATA_WIDTH(C_AXIS07_TDATA_WIDTH),
  .C_SORTER_BIT_WIDTH(C_SORTER_BIT_WIDTH)
)
axi_read_controller_inst07(
  .s_axis_aclk(s_axis_aclk),
  .s_axis_areset(s_axis_areset),

  .s_axis_tvalid(s07_axis_tvalid),
  .s_axis_tready(s07_axis_tready),
  .s_axis_tdata(s07_axis_tdata),
  .s_axis_tkeep(s07_axis_tkeep),
  .s_axis_tlast(s07_axis_tlast),

  .fifo_full(fifo_full[7]),
  .in_fifo_data(in_fifo[7]),
  .in_fifo_en(write_fifo[7])
);

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
  //.i_fifo_out_ready(~fifo_out_full | read_fifo_out),
  .i_fifo_out_ready(~fifo_out_full | fifo_out_i_deq),
  .o_fifo_read(fifo_read),		  
  .o_out_fifo_write(o_out_fifo_write),
  .o_data(o_data)
);


axi_write_controller #(
	.C_AXIS_TDATA_WIDTH(C_AXIS08_TDATA_WIDTH),
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


endmodule

`default_nettype wire