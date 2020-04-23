// Top warpper
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module Top_wrapper #(
  parameter integer C_M00_AXI_ID_WIDTH   = 1  ,
  parameter integer C_M00_AXI_ADDR_WIDTH = 64 ,
  parameter integer C_M00_AXI_DATA_WIDTH = 512 ,
  parameter integer C_M01_AXI_ID_WIDTH   = 1  ,
  parameter integer C_M01_AXI_ADDR_WIDTH = 64 ,
  parameter integer C_M01_AXI_DATA_WIDTH = 512
)
(
  // System Signals
  input  wire                              ap_clk         ,
  input  wire                              ap_rst_n       ,
  // AXI4 master interface m00_axi
  output wire                              m00_axi_awvalid,
  input  wire                              m00_axi_awready,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_awaddr ,
  output wire [8-1:0]                      m00_axi_awlen  ,
  output wire                              m00_axi_wvalid ,
  input  wire                              m00_axi_wready ,
  output wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_wdata  ,
  output wire [C_M00_AXI_DATA_WIDTH/8-1:0] m00_axi_wstrb  ,
  output wire                              m00_axi_wlast  ,
  input  wire                              m00_axi_bvalid ,
  output wire                              m00_axi_bready ,
  output wire                              m00_axi_arvalid,
  input  wire                              m00_axi_arready,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_araddr ,
  output wire [8-1:0]                      m00_axi_arlen  ,
  output wire [3-1:0]                      m00_axi_arsize ,
  output wire [C_M00_AXI_ID_WIDTH-1:0]     m00_axi_arid   ,
  input  wire                              m00_axi_rvalid ,
  output wire                              m00_axi_rready ,
  input  wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_rdata  ,
  input  wire                              m00_axi_rlast  ,
  input  wire [C_M00_AXI_ID_WIDTH-1:0]     m00_axi_rid    ,
  // AXI4 master interface m01_axi
  output wire                              m01_axi_awvalid,
  input  wire                              m01_axi_awready,
  output wire [C_M01_AXI_ADDR_WIDTH-1:0]   m01_axi_awaddr ,
  output wire [8-1:0]                      m01_axi_awlen  ,
  output wire                              m01_axi_wvalid ,
  input  wire                              m01_axi_wready ,
  output wire [C_M01_AXI_DATA_WIDTH-1:0]   m01_axi_wdata  ,
  output wire [C_M01_AXI_DATA_WIDTH/8-1:0] m01_axi_wstrb  ,
  output wire                              m01_axi_wlast  ,
  input  wire                              m01_axi_bvalid ,
  output wire                              m01_axi_bready ,
  output wire                              m01_axi_arvalid,
  input  wire                              m01_axi_arready,
  output wire [C_M01_AXI_ADDR_WIDTH-1:0]   m01_axi_araddr ,
  output wire [8-1:0]                      m01_axi_arlen  ,
  output wire [3-1:0]                      m01_axi_arsize ,
  output wire [C_M01_AXI_ID_WIDTH-1:0]     m01_axi_arid   ,
  input  wire                              m01_axi_rvalid ,
  output wire                              m01_axi_rready ,
  input  wire [C_M01_AXI_DATA_WIDTH-1:0]   m01_axi_rdata  ,
  input  wire                              m01_axi_rlast  ,
  input  wire [C_M01_AXI_ID_WIDTH-1:0]     m01_axi_rid    ,
  // SDx Control Signals
  input  wire                              ap_start       ,
  output wire                              ap_idle        ,
  output wire                              ap_done        ,
  input  wire                              kernel_rst     ,
  input  wire [64-1:0]                     size           ,
  input  wire [8-1:0]                      num_pass       ,
  input  wire [64-1:0]                     in_ptr         ,
  input  wire [64-1:0]                     out_ptr              
);


timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 16384;
localparam integer  LP_NUM_EXAMPLES    = 1;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic                                areset                         = 1'b0;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b1;
logic                                ap_start_pulse                ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_i                     ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_r                      = {LP_NUM_EXAMPLES{1'b0}};
logic [32-1:0]                       ctrl_xfer_size_in_bytes        = LP_DEFAULT_LENGTH_IN_BYTES;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

// create pulse when ap_start transitions to 1
always @(posedge ap_clk) begin
  begin
    ap_start_r <= ap_start;
  end
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge ap_clk) begin
  if (areset) begin
    ap_idle_r <= 1'b1;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 :
      ap_start_pulse ? 1'b0 : ap_idle;
  end
end

assign ap_idle = ap_idle_r;

// Done logic
always @(posedge ap_clk) begin
  if (areset) begin
    ap_done_r <= '0;
  end
  else begin
    ap_done_r <= (ap_start_pulse | ap_done) ? '0 : ap_done_r | ap_done_i;
  end
end

assign ap_done = &ap_done_r;



MERGER_TREE_P16_L32_I64_MB_TOP #(
  .C_M00_AXI_ID_WIDTH   ( C_M00_AXI_ID_WIDTH   ),
  .C_M00_AXI_ADDR_WIDTH ( C_M00_AXI_ADDR_WIDTH ),
  .C_M00_AXI_DATA_WIDTH ( C_M00_AXI_DATA_WIDTH ),
  .C_M01_AXI_ID_WIDTH   ( C_M01_AXI_ID_WIDTH   ),
  .C_M01_AXI_ADDR_WIDTH ( C_M01_AXI_ADDR_WIDTH ),
  .C_M01_AXI_DATA_WIDTH ( C_M01_AXI_DATA_WIDTH ),
  .C_SORTER_BIT_WIDTH   ( 32                   ),
  .C_XFER_SIZE_WIDTH    ( 64                   )
)
MERGER_TREE_P16_L32_I64_MB_TOP_inst0 (
  .aclk                      ( ap_clk                  ),
  .areset                    ( areset                  ),
  .kernel_clk                ( ap_clk                  ),
  .kernel_rst                ( kernel_rst              ),
  .ap_start                  ( ap_start_pulse          ),
  .ap_done                   ( ap_done_i               ),
  .num_pass                  ( num_pass                ),
  .in_addr_offset            ( in_ptr                  ),
  .in_xfer_size_in_bytes     ( size                    ),
  .out_addr_offset           ( out_ptr                 ),
  .out_xfer_size_in_bytes    ( size                    ),
  .m00_axi_awvalid           ( m00_axi_awvalid         ),
  .m00_axi_awready           ( m00_axi_awready         ),
  .m00_axi_awaddr            ( m00_axi_awaddr          ),
  .m00_axi_awlen             ( m00_axi_awlen           ),
  .m00_axi_wvalid            ( m00_axi_wvalid          ),
  .m00_axi_wready            ( m00_axi_wready          ),
  .m00_axi_wdata             ( m00_axi_wdata           ),
  .m00_axi_wstrb             ( m00_axi_wstrb           ),
  .m00_axi_wlast             ( m00_axi_wlast           ),
  .m00_axi_bvalid            ( m00_axi_bvalid          ),
  .m00_axi_bready            ( m00_axi_bready          ),
  .m00_axi_arvalid           ( m00_axi_arvalid         ),
  .m00_axi_arready           ( m00_axi_arready         ),
  .m00_axi_araddr            ( m00_axi_araddr          ),
  .m00_axi_arlen             ( m00_axi_arlen           ),
  .m00_axi_arsize            ( m00_axi_arsize          ),
  .m00_axi_arid              ( m00_axi_arid            ),
  .m00_axi_rvalid            ( m00_axi_rvalid          ),
  .m00_axi_rready            ( m00_axi_rready          ),
  .m00_axi_rdata             ( m00_axi_rdata           ),
  .m00_axi_rlast             ( m00_axi_rlast           ),
  .m00_axi_rid               ( m00_axi_rid             ),
  .m01_axi_awvalid           ( m01_axi_awvalid         ),
  .m01_axi_awready           ( m01_axi_awready         ),
  .m01_axi_awaddr            ( m01_axi_awaddr          ),
  .m01_axi_awlen             ( m01_axi_awlen           ),
  .m01_axi_wvalid            ( m01_axi_wvalid          ),
  .m01_axi_wready            ( m01_axi_wready          ),
  .m01_axi_wdata             ( m01_axi_wdata           ),
  .m01_axi_wstrb             ( m01_axi_wstrb           ),
  .m01_axi_wlast             ( m01_axi_wlast           ),
  .m01_axi_bvalid            ( m01_axi_bvalid          ),
  .m01_axi_bready            ( m01_axi_bready          ),
  .m01_axi_arvalid           ( m01_axi_arvalid         ),
  .m01_axi_arready           ( m01_axi_arready         ),
  .m01_axi_araddr            ( m01_axi_araddr          ),
  .m01_axi_arlen             ( m01_axi_arlen           ),
  .m01_axi_arsize            ( m01_axi_arsize          ),
  .m01_axi_arid              ( m01_axi_arid            ),
  .m01_axi_rvalid            ( m01_axi_rvalid          ),
  .m01_axi_rready            ( m01_axi_rready          ),
  .m01_axi_rdata             ( m01_axi_rdata           ),
  .m01_axi_rlast             ( m01_axi_rlast           ),
  .m01_axi_rid               ( m01_axi_rid             )
);

endmodule : Top_wrapper
`default_nettype wire
