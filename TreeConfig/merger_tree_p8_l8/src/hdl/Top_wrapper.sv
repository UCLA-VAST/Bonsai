// Top warpper
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1 ns / 1 ps 

module Top_wrapper #(
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32,
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 6,
  parameter integer C_M00_AXI_ID_WIDTH   = 1  ,
  parameter integer C_M00_AXI_ADDR_WIDTH = 64 ,
  parameter integer C_M00_AXI_DATA_WIDTH = 512
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
  // AXI4-Lite slave interface
  input  wire                                    s_axi_control_awvalid  ,
  output wire                                    s_axi_control_awready  ,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr   ,
  input  wire                                    s_axi_control_wvalid   ,
  output wire                                    s_axi_control_wready   ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata    ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb    ,
  input  wire                                    s_axi_control_arvalid  ,
  output wire                                    s_axi_control_arready  ,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr   ,
  output wire                                    s_axi_control_rvalid   ,
  input  wire                                    s_axi_control_rready   ,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata    ,
  output wire [2-1:0]                            s_axi_control_rresp    ,
  output wire                                    s_axi_control_bvalid   ,
  input  wire                                    s_axi_control_bready   ,
  output wire [2-1:0]                            s_axi_control_bresp    
);

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic                                areset                  = 1'b0;
logic                                ap_start                      ;
logic                                ap_start_r              = 1'b0;
logic                                ap_start_pulse                ;
logic                                ap_ready                      ;
logic                                ap_idle                 = 1'b1;
logic                                ap_done                       ;

wire [64-1:0]                        size                          ;
wire [8-1:0]                         num_pass                      ;
wire [64-1:0]                        in_ptr                        ;
wire [64-1:0]                        out_ptr                       ;

///////////////////////////////////////////////////////////////////////////////
// RTL Logic
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
    ap_idle <= 1'b1;
  end
  else begin
    ap_idle <= ap_done        ? 1'b1 :
               ap_start_pulse ? 1'b0 : 
                                ap_idle;
  end
end

assign ap_ready = ap_done;

// AXI4-Lite slave interface
merger_tree_p8_l8_i16_control_s_axi #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .awvalid   ( s_axi_control_awvalid ),
  .awready   ( s_axi_control_awready ),
  .awaddr    ( s_axi_control_awaddr  ),
  .wvalid    ( s_axi_control_wvalid  ),
  .wready    ( s_axi_control_wready  ),
  .wdata     ( s_axi_control_wdata   ),
  .wstrb     ( s_axi_control_wstrb   ),
  .arvalid   ( s_axi_control_arvalid ),
  .arready   ( s_axi_control_arready ),
  .araddr    ( s_axi_control_araddr  ),
  .rvalid    ( s_axi_control_rvalid  ),
  .rready    ( s_axi_control_rready  ),
  .rdata     ( s_axi_control_rdata   ),
  .rresp     ( s_axi_control_rresp   ),
  .bvalid    ( s_axi_control_bvalid  ),
  .bready    ( s_axi_control_bready  ),
  .bresp     ( s_axi_control_bresp   ),
  .aclk      ( ap_clk                ),
  .areset    ( areset                ),
  .aclk_en   ( 1'b1                  ),
  .ap_start  ( ap_start              ),
  .interrupt (                       ), // not used
  .ap_ready  ( ap_ready              ) ,
  .ap_done   ( ap_done               ),
  .ap_idle   ( ap_idle               ),
  .size      ( size                  ),
  .num_pass  ( num_pass              ),
  .in_ptr    ( in_ptr                ),
  .out_ptr   ( out_ptr               )
);


// bitonic_sorter_top
MERGER_TREE_P8_L8_I16_TOP #(
  .C_M00_AXI_ID_WIDTH   ( C_M00_AXI_ID_WIDTH   ),
  .C_M00_AXI_ADDR_WIDTH ( C_M00_AXI_ADDR_WIDTH ),
  .C_M00_AXI_DATA_WIDTH ( C_M00_AXI_DATA_WIDTH ),
  .C_SORTER_BIT_WIDTH   ( 32                   ),
  .C_XFER_SIZE_WIDTH    ( 64                   )
)
MERGER_TREE_P8_L8_I16_TOP_inst0 (
  .aclk                      ( ap_clk                  ),
  .areset                    ( areset                  ),
  .ap_start                  ( ap_start_pulse          ),
  .ap_done                   ( ap_done                 ),
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
  .m00_axi_rid               ( m00_axi_rid             )
);

endmodule : Top_wrapper
`default_nettype wire
