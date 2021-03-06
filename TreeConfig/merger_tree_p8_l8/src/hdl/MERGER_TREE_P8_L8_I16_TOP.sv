// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module MERGER_TREE_P8_L8_I16_TOP #(
  parameter integer C_M00_AXI_ID_WIDTH         = 1 ,
  parameter integer C_M00_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M00_AXI_DATA_WIDTH       = 512,
  parameter integer C_XFER_SIZE_WIDTH        = 32,
  parameter integer C_SORTER_BIT_WIDTH        = 32
)
(
  // System Signals
  input wire                                    aclk                 ,
  input wire                                    areset               ,
  // Engine signal
  input wire                                    ap_start             ,
  output wire                                   ap_done              ,
  // AXI4 master interface 00
  input wire [8-1:0]                            num_pass             ,
  input wire [C_M00_AXI_ADDR_WIDTH-1:0]         in_addr_offset       ,
  input wire [C_XFER_SIZE_WIDTH-1:0]            in_xfer_size_in_bytes, // total input size in bytes
  input wire [C_M00_AXI_ADDR_WIDTH-1:0]         out_addr_offset      ,
  input wire [C_XFER_SIZE_WIDTH-1:0]            out_xfer_size_in_bytes,
  output wire                                   m00_axi_awvalid      ,
  input wire                                    m00_axi_awready      ,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]        m00_axi_awaddr       ,
  output wire [8-1:0]                           m00_axi_awlen        ,
  output wire                                   m00_axi_wvalid       ,
  input wire                                    m00_axi_wready       ,
  output wire [C_M00_AXI_DATA_WIDTH-1:0]        m00_axi_wdata        ,
  output wire [C_M00_AXI_DATA_WIDTH/8-1:0]      m00_axi_wstrb        ,
  output wire                                   m00_axi_wlast        ,
  output wire                                   m00_axi_arvalid      ,
  input wire                                    m00_axi_arready      ,
  output wire [C_M00_AXI_ADDR_WIDTH-1:0]        m00_axi_araddr       ,
  output wire [8-1:0]                           m00_axi_arlen        ,
  output wire [3-1:0]                           m00_axi_arsize       ,
  output wire [C_M00_AXI_ID_WIDTH-1:0]          m00_axi_arid         ,
  input wire                                    m00_axi_rvalid       ,
  output wire                                   m00_axi_rready       ,
  input wire [C_M00_AXI_DATA_WIDTH-1:0]         m00_axi_rdata        ,
  input wire                                    m00_axi_rlast        ,
  input wire [C_M00_AXI_ID_WIDTH-1:0]           m00_axi_rid          ,
  input wire                                    m00_axi_bvalid       ,
  output wire                                   m00_axi_bready       
);

timeunit 1ps;
timeprecision 1ps;


///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_BURST_SIZE_BYTES        = 1024;
localparam integer LP_NUM_READ_CHANNELS_00    = 16;
localparam integer LP_DW_BYTES_00             = C_M00_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN_00        = LP_BURST_SIZE_BYTES/LP_DW_BYTES_00 < 256 ? LP_BURST_SIZE_BYTES/LP_DW_BYTES_00 : 256;
localparam integer LP_LOG_BURST_LEN_00        = $clog2(LP_AXI_BURST_LEN_00);
localparam integer LP_BRAM_DEPTH_00           = 32;
localparam integer LP_RD_MAX_OUTSTANDING_00   = LP_BRAM_DEPTH_00 / LP_AXI_BURST_LEN_00;

localparam integer LP_WR_MAX_OUTSTANDING_00   = 32;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
// Control logic
logic                                                         done = 1'b0;
// AXI read master 00 stage
logic                                                         read_done_00;  // read_done is used to change to another run

logic [LP_NUM_READ_CHANNELS_00-1:0]                           rd_tvalid_00;
logic [LP_NUM_READ_CHANNELS_00-1:0]                           rd_tready_00;
logic [LP_NUM_READ_CHANNELS_00-1:0]                           rd_tlast_00;
logic [LP_NUM_READ_CHANNELS_00-1:0][C_M00_AXI_DATA_WIDTH-1:0] rd_tdata_00;

// AXI write master 00 stage
logic                                                         merger_out_tvalid;
logic                                                         merger_out_tready;
logic [C_M00_AXI_DATA_WIDTH-1:0]                              merger_out_tdata;

// AXI read control information
logic                                                         single_run_read_done;
logic                                                         read_start_00;
logic [C_XFER_SIZE_WIDTH-1:0]                                 read_size_in_bytes_00; 
logic [LP_NUM_READ_CHANNELS_00-1:0][C_M00_AXI_ADDR_WIDTH-1:0] rd_addr_00;
logic                                                         read_divide;
logic [C_XFER_SIZE_WIDTH-1:0]                                 read_run_count; 
// AXI write control information
logic                                                         write_done;
logic                                                         write_start;
logic [C_M00_AXI_ADDR_WIDTH-1:0]                              write_addr_00;
logic                                                         all_done;

// for debug
logic 	time_out;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////
// The following is for calculating addresses 
addr_cal #(
  .NUM_READ_CHANNELS(LP_NUM_READ_CHANNELS_00), 
  .C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
  .C_XFER_SIZE_WIDTH(C_XFER_SIZE_WIDTH),
  .C_BURST_SIZE_BYTES(LP_BURST_SIZE_BYTES)
)
addr_cal_inst00(
  .aclk                    ( aclk                       ) ,

  .ap_start                ( ap_start                   ) ,
  .ap_done                 ( all_done                   ) ,  

  .num_pass                ( num_pass                   ) ,
  .in_addr_offset          ( in_addr_offset             ) ,
  .in_xfer_size_in_bytes   ( in_xfer_size_in_bytes      ) , // total input size in bytes
  .out_addr_offset         ( out_addr_offset            ) ,  
  .single_run_read_done    ( single_run_read_done       ) ,
  .write_done              ( write_done                 ) , // write done means one pass is done
  .read_start              ( read_start_00              ) ,
  .read_addr               ( rd_addr_00                 ) ,
  .read_size_in_bytes      ( read_size_in_bytes_00      ) ,
  .read_divide             ( read_divide                ) , // asserted when an axi burst consists of multiple runs
  .read_run_count          ( read_run_count             ) , // indicate how many 512-bit axi transfers for the current run
  .write_start             ( write_start                ) ,
  .write_addr              ( write_addr_00              )           
);

// AXI4 Read Master00, output format is an AXI4-Stream master, two stream per thread.
axi_read_master #(
  .C_ID_WIDTH          ( C_M00_AXI_ID_WIDTH         ) ,
  .C_M_AXI_ADDR_WIDTH  ( C_M00_AXI_ADDR_WIDTH       ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M00_AXI_DATA_WIDTH       ) ,
  .C_NUM_CHANNELS      ( LP_NUM_READ_CHANNELS_00    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH          ) ,
  .C_BURST_SIZE_BYTES  ( LP_BURST_SIZE_BYTES        ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING_00   ) ,
  .C_INCLUDE_DATA_FIFO ( 1                          )
)
AXI_Read_inst00 (
  .aclk                    ( aclk                       ) ,
  .areset                  ( areset                     ) ,
  .ctrl_start              ( read_start_00              ) ,
  .pass_start              ( write_done                 ) ,
  .ctrl_done               ( single_run_read_done       ) ,
  .ctrl_addr_offset        ( rd_addr_00                 ) ,
  .ctrl_xfer_size_in_bytes ( read_size_in_bytes_00      ) ,
  .ctrl_read_divide        ( read_divide                ) , 
  .ctrl_read_run_count     ( read_run_count             ) ,

  .m_axi_arvalid           ( m00_axi_arvalid            ) ,
  .m_axi_arready           ( m00_axi_arready            ) ,
  .m_axi_araddr            ( m00_axi_araddr             ) ,
  .m_axi_arid              ( m00_axi_arid               ) ,
  .m_axi_arlen             ( m00_axi_arlen              ) ,
  .m_axi_arsize            ( m00_axi_arsize             ) ,

  .m_axi_rvalid            ( m00_axi_rvalid             ) ,
  .m_axi_rready            ( m00_axi_rready             ) ,
  .m_axi_rdata             ( m00_axi_rdata              ) ,
  .m_axi_rlast             ( m00_axi_rlast              ) ,
  .m_axi_rid               ( m00_axi_rid                ) ,

  .m_axis_tvalid           ( rd_tvalid_00               ) ,
  .m_axis_tready           ( rd_tready_00               ) ,
  .m_axis_tlast            ( rd_tlast_00                ) ,
  .m_axis_tdata            ( rd_tdata_00                ) 
);

// merger kernel
MERGER_INTEGRATION #(
  .C_AXIS_TDATA_WIDTH   ( C_M00_AXI_DATA_WIDTH    ) ,
  .C_SORTER_BIT_WIDTH   ( C_SORTER_BIT_WIDTH      ) ,
  .NUM_READ_CHANNELS    ( LP_NUM_READ_CHANNELS_00 ) ,
  .C_NUM_CLOCKS       ( 1                  )
)
MERGER_INTEGRATION_inst0  (
  .s_axis_aclk   ( aclk                                ) ,
  .s_axis_areset ( areset                               ) ,

  .s_axis_tvalid ( rd_tvalid_00                       ) ,
  .s_axis_tready ( rd_tready_00                       ) ,
  .s_axis_tdata  ( rd_tdata_00                        ) ,
  .s_axis_tlast  ( rd_tlast_00                        ) , 
  
  .m_axis_aclk   ( aclk                                 ) ,
  .m_axis_areset ( areset                               ) ,
  
  .m_axis_tvalid ( merger_out_tvalid                    ) ,
  .m_axis_tready ( merger_out_tready                    ) ,
  .m_axis_tdata  ( merger_out_tdata                     ) ,
  .m_axis_tkeep  (                                      ) , // Not used
  .m_axis_tlast  (                                      )   // Not used
);

// AXI write master stage

// AXI4 Write Master
axi_write_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M00_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M00_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH     ) ,
  .C_MAX_OUTSTANDING   ( LP_WR_MAX_OUTSTANDING_00 ) ,
  .C_INCLUDE_DATA_FIFO ( 1                     )
)
AXI_write_inst00 (
  .aclk                    ( aclk                    ) ,
  .areset                  ( areset                  ) ,
  .ctrl_start              ( write_start             ) ,
  .ctrl_done               ( write_done              ) ,
  .ctrl_addr_offset        ( write_addr_00           ) ,
  .ctrl_xfer_size_in_bytes ( out_xfer_size_in_bytes ) ,
  .m_axi_awvalid           ( m00_axi_awvalid           ) ,
  .m_axi_awready           ( m00_axi_awready           ) ,
  .m_axi_awaddr            ( m00_axi_awaddr            ) ,
  .m_axi_awlen             ( m00_axi_awlen             ) ,
  .m_axi_wvalid            ( m00_axi_wvalid            ) ,
  .m_axi_wready            ( m00_axi_wready            ) ,
  .m_axi_wdata             ( m00_axi_wdata             ) ,
  .m_axi_wstrb             ( m00_axi_wstrb             ) ,
  .m_axi_wlast             ( m00_axi_wlast             ) ,
  .m_axi_bvalid            ( m00_axi_bvalid            ) ,
  .m_axi_bready            ( m00_axi_bready            ) ,
  .s_axis_tvalid           ( merger_out_tvalid            ) ,
  .s_axis_tready           ( merger_out_tready            ) ,
  .s_axis_tdata            ( merger_out_tdata             )
);

time_cnt time_cnt_inst_0(
    .aclk(aclk),
    .ap_start(ap_start),
    .time_out(time_out)
);

assign ap_done = all_done | time_out;

endmodule : MERGER_TREE_P8_L8_I16_TOP
`default_nettype wire

