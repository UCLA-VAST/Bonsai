// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module MERGER_TREE_P16_L32_I64_MB_TOP #(
  parameter integer C_M00_AXI_ID_WIDTH         = 1 ,
  parameter integer C_M00_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M00_AXI_DATA_WIDTH       = 512,
  parameter integer C_M01_AXI_ID_WIDTH         = 1 ,
  parameter integer C_M01_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M01_AXI_DATA_WIDTH       = 512,
  parameter integer C_XFER_SIZE_WIDTH        = 32,
  parameter integer C_SORTER_BIT_WIDTH        = 32
)
(
  // System Signals
  input wire                                    aclk                 ,
  input wire                                    areset               ,
  // Extra clocks
  input wire                                    kernel_clk           ,
  input wire                                    kernel_rst           ,
  // Engine signal
  input wire                                    ap_start             ,
  output wire                                   ap_done              ,
  // control information
  input wire [8-1:0]                            num_pass             ,
  input wire [C_M00_AXI_ADDR_WIDTH-1:0]         in_addr_offset       ,
  input wire [C_XFER_SIZE_WIDTH-1:0]            in_xfer_size_in_bytes, // total input size in bytes
  input wire [C_M00_AXI_ADDR_WIDTH-1:0]         out_addr_offset      ,
  input wire [C_XFER_SIZE_WIDTH-1:0]            out_xfer_size_in_bytes,
  // AXI4 master interface 00
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
  output wire                                   m00_axi_bready       ,
  // AXI4 master interface 01
  output wire                                   m01_axi_awvalid      ,
  input wire                                    m01_axi_awready      ,
  output wire [C_M01_AXI_ADDR_WIDTH-1:0]        m01_axi_awaddr       ,
  output wire [8-1:0]                           m01_axi_awlen        ,
  output wire                                   m01_axi_wvalid       ,
  input wire                                    m01_axi_wready       ,
  output wire [C_M01_AXI_DATA_WIDTH-1:0]        m01_axi_wdata        ,
  output wire [C_M01_AXI_DATA_WIDTH/8-1:0]      m01_axi_wstrb        ,
  output wire                                   m01_axi_wlast        ,
  output wire                                   m01_axi_arvalid      ,
  input wire                                    m01_axi_arready      ,
  output wire [C_M01_AXI_ADDR_WIDTH-1:0]        m01_axi_araddr       ,
  output wire [8-1:0]                           m01_axi_arlen        ,
  output wire [3-1:0]                           m01_axi_arsize       ,
  output wire [C_M01_AXI_ID_WIDTH-1:0]          m01_axi_arid         ,
  input wire                                    m01_axi_rvalid       ,
  output wire                                   m01_axi_rready       ,
  input wire [C_M01_AXI_DATA_WIDTH-1:0]         m01_axi_rdata        ,
  input wire                                    m01_axi_rlast        ,
  input wire [C_M01_AXI_ID_WIDTH-1:0]           m01_axi_rid          ,
  input wire                                    m01_axi_bvalid       ,
  output wire                                   m01_axi_bready     
);

timeunit 1ps;
timeprecision 1ps;


///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_BURST_SIZE_BYTES        = 1024;
localparam integer LP_NUM_READ_CHANNELS    = 64;

// AXI4 master interface 00
localparam integer LP_DW_BYTES_00             = C_M00_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN_00        = LP_BURST_SIZE_BYTES/LP_DW_BYTES_00 < 256 ? LP_BURST_SIZE_BYTES/LP_DW_BYTES_00 : 256;
localparam integer LP_LOG_BURST_LEN_00        = $clog2(LP_AXI_BURST_LEN_00);
localparam integer LP_BRAM_DEPTH_00           = 32;
localparam integer LP_RD_MAX_OUTSTANDING_00   = LP_BRAM_DEPTH_00 / LP_AXI_BURST_LEN_00;

localparam integer LP_WR_MAX_OUTSTANDING_00   = 32;

// AXI4 master interface 01
localparam integer LP_DW_BYTES_01             = C_M01_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN_01        = LP_BURST_SIZE_BYTES/LP_DW_BYTES_01 < 256 ? LP_BURST_SIZE_BYTES/LP_DW_BYTES_01 : 256;
localparam integer LP_LOG_BURST_LEN_01        = $clog2(LP_AXI_BURST_LEN_01);
localparam integer LP_BRAM_DEPTH_01           = 32;
localparam integer LP_RD_MAX_OUTSTANDING_01   = LP_BRAM_DEPTH_01 / LP_AXI_BURST_LEN_01;

localparam integer LP_WR_MAX_OUTSTANDING_01   = 32;

// FIFO Parameters
localparam integer LP_FIFO_DEPTH                 = 2**($clog2(LP_AXI_BURST_LEN_00*LP_RD_MAX_OUTSTANDING_00)); // Ensure power of 2
localparam integer LP_FIFO_READ_LATENCY          = 2; // 2: Registered output on BRAM, 1: Registered output on LUTRAM
localparam integer LP_FIFO_COUNT_WIDTH           = $clog2(LP_FIFO_DEPTH)+1;


///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////

// Control logic
logic                                                                  single_run_read_done;
logic                                                                  write_done;

logic [8-1:0]                                                          current_pass;

logic                                                                  read_start;
logic [C_XFER_SIZE_WIDTH-1:0]                                          read_size_in_bytes; 
logic [LP_NUM_READ_CHANNELS-1:0][C_M00_AXI_ADDR_WIDTH-1:0]             rd_addr;
logic                                                                  read_divide;
logic [C_XFER_SIZE_WIDTH-1:0]                                          read_run_count; 
logic                                                                  write_start;
logic [C_M00_AXI_ADDR_WIDTH-1:0]                                       write_addr;

logic                                                                  all_done;

// AXI read data channel 00
logic                                                                  rxfer_00;
logic [LP_NUM_READ_CHANNELS-1:0]                                       tvalid_00;
logic [LP_NUM_READ_CHANNELS-1:0][C_M00_AXI_DATA_WIDTH-1:0]             tdata_00;
logic [LP_NUM_READ_CHANNELS-1:0]                                       tlast_00;
// AXI write master 00 stage
logic                                                                  merger_out_tready_00;
// AXI 00 read control information
logic                                                                  read_start_00;
logic                                                                  single_run_read_done_00;
logic [LP_NUM_READ_CHANNELS-1:0]                                       r_final_transaction_00;
// AXI 00 write control information
logic                                                                  write_done_00;
// AXI00 presorted data
logic [C_M00_AXI_DATA_WIDTH-1:0]                                       m00_axi_rdata_sort;
logic                                                                  m00_axi_rvalid_sort;
logic                                                                  rxfer_sort_00;
logic                                                                  m00_axi_rlast_sort;
logic [C_M00_AXI_ID_WIDTH - 1:0]                                       m00_axi_rid_sort;
logic [LP_NUM_READ_CHANNELS-1:0]                                       r_final_transaction_sort_00;
// AXI00 multiple run info
logic [LP_NUM_READ_CHANNELS-1:0][C_XFER_SIZE_WIDTH-1:0]                axi_cnt_per_run_00;
logic [LP_NUM_READ_CHANNELS-1:0]                                       run_last_00;
logic [LP_NUM_READ_CHANNELS-1:0]                                       run_last_sort_00;
// AXI00 stream
logic [LP_NUM_READ_CHANNELS-1:0]                                       rd_tvalid_00;
logic [LP_NUM_READ_CHANNELS-1:0]                                       rd_tready_00;

// AXI read data channel 01
logic                                                                  rxfer_01;
logic [LP_NUM_READ_CHANNELS-1:0]                                       tvalid_01;
logic [LP_NUM_READ_CHANNELS-1:0][C_M01_AXI_DATA_WIDTH-1:0]             tdata_01;
logic [LP_NUM_READ_CHANNELS-1:0]                                       tlast_01;
// AXI write master 01 stage
logic                                                                  merger_out_tready_01;
// AXI 01 read control information
logic                                                                  read_start_01;
logic                                                                  single_run_read_done_01;
logic [LP_NUM_READ_CHANNELS-1:0]                                       r_final_transaction_01;
// AXI 01 write control information
logic                                                                  write_done_01;
// AXI01 presorted data
logic [C_M01_AXI_DATA_WIDTH-1:0]                                       m01_axi_rdata_sort;
logic                                                                  m01_axi_rvalid_sort;
logic                                                                  rxfer_sort_01;
logic                                                                  m01_axi_rlast_sort;
logic [C_M01_AXI_ID_WIDTH - 1:0]                                       m01_axi_rid_sort;
logic [LP_NUM_READ_CHANNELS-1:0]                                       r_final_transaction_sort_01;
// AXI01 multiple run info
logic [LP_NUM_READ_CHANNELS-1:0][C_XFER_SIZE_WIDTH-1:0]                axi_cnt_per_run_01;
logic [LP_NUM_READ_CHANNELS-1:0]                                       run_last_01;
logic [LP_NUM_READ_CHANNELS-1:0]                                       run_last_sort_01;
// AXI00 stream
logic [LP_NUM_READ_CHANNELS-1:0]                                       rd_tvalid_01;
logic [LP_NUM_READ_CHANNELS-1:0]                                       rd_tready_01;

// FIFO signals
logic [LP_NUM_READ_CHANNELS-1:0]                                       tvalid;
logic [LP_NUM_READ_CHANNELS-1:0]                                       tvalid_delay;
logic [LP_NUM_READ_CHANNELS-1:0][C_M00_AXI_DATA_WIDTH:0]               fifo_din;
logic [LP_NUM_READ_CHANNELS-1:0][C_M00_AXI_DATA_WIDTH:0]               fifo_din_delay;
logic [LP_NUM_READ_CHANNELS-1:0][C_M00_AXI_DATA_WIDTH:0]               fifo_dout;
logic [LP_NUM_READ_CHANNELS-1:0]                                       tlast_fifo_out;
logic [LP_NUM_READ_CHANNELS-1:0][C_M00_AXI_DATA_WIDTH-1:0]             tdata_fifo_out;
logic [LP_NUM_READ_CHANNELS-1:0]                                       fifo_empty; // for debug
logic [LP_NUM_READ_CHANNELS-1:0]                                       fifo_full; // for debug

// AXI read information to the merger tree kernel
logic [LP_NUM_READ_CHANNELS-1:0]                                       rd_tvalid;
logic [LP_NUM_READ_CHANNELS-1:0]                                       rd_tready;
logic [LP_NUM_READ_CHANNELS-1:0]                                       rd_tlast;
logic [LP_NUM_READ_CHANNELS-1:0][C_M00_AXI_DATA_WIDTH-1:0]             rd_tdata;

// AXI write master 00/01stage
logic                                                                  merger_out_tvalid;
logic                                                                  merger_out_tready;
logic [C_M00_AXI_DATA_WIDTH-1:0]                                       merger_out_tdata;

// for debug
logic 	time_out;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////
assign single_run_read_done = current_pass[0] ? single_run_read_done_01 : single_run_read_done_00;
assign write_done = current_pass[0] ? write_done_00 : write_done_01;

assign merger_out_tready = current_pass[0] ? merger_out_tready_00 : merger_out_tready_01;


// The following is for calculating addresses 
addr_cal #(
  .NUM_READ_CHANNELS(LP_NUM_READ_CHANNELS), 
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
  .current_pass            ( current_pass               ) ,
  .read_start              ( read_start                 ) ,
  .read_addr               ( rd_addr                    ) ,
  .read_size_in_bytes      ( read_size_in_bytes         ) ,
  .read_divide             ( read_divide                ) , // asserted when an axi burst consists of multiple runs
  .read_run_count          ( read_run_count             ) , // indicate how many 512-bit axi transfers for the current run
  .write_start             ( write_start                ) ,
  .write_addr              ( write_addr                 )           
);

// AXI4 Read Master00, output format is an AXI4-Stream master, 32 streams per thread.
axi_read_master #(
  .C_ID_WIDTH          ( C_M00_AXI_ID_WIDTH         ) ,
  .C_M_AXI_ADDR_WIDTH  ( C_M00_AXI_ADDR_WIDTH       ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M00_AXI_DATA_WIDTH       ) ,
  .C_NUM_CHANNELS      ( LP_NUM_READ_CHANNELS    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH          ) ,
  .C_BURST_SIZE_BYTES  ( LP_BURST_SIZE_BYTES        ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING_00   )
)
AXI_Read_inst00 (
  .aclk                    ( aclk                       ) ,
  .areset                  ( areset                     ) ,
  .ctrl_start              ( read_start_00              ) ,
  .pass_start              ( write_done                 ) ,
  .ctrl_done               ( single_run_read_done_00    ) ,
  .ctrl_addr_offset        ( rd_addr                    ) ,
  .ctrl_xfer_size_in_bytes ( read_size_in_bytes         ) ,

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

  .r_final_transaction     ( r_final_transaction_00     ) ,

  .m_axis_tvalid           ( rd_tvalid_00               ) ,
  .m_axis_tready           ( rd_tready_00               )
);

assign read_start_00 = read_start & (~current_pass[0]);
assign rxfer_00 = m00_axi_rvalid & m00_axi_rready;

always_comb begin 
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    rd_tvalid_00[i] = rd_tvalid[i] & (~current_pass[0]); 
    rd_tready_00[i] = rd_tready[i] & (~current_pass[0]);
  end
end

always_comb begin 
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    tvalid_00[i] = m00_axi_rvalid_sort && (m00_axi_rid_sort == i); 
    tdata_00[i] = m00_axi_rdata_sort;
    tlast_00[i] = rxfer_sort_00 && (m00_axi_rid_sort == i) && ((m00_axi_rlast_sort && r_final_transaction_sort_00[i]) || run_last_sort_00[i]); 
  end
end

presorter #(
    .DATA_WIDTH(C_M00_AXI_DATA_WIDTH/16)
)
presorter_inst_00(
    .aclk(aclk),  
    .in_data(m00_axi_rdata),
    .out_data(m00_axi_rdata_sort)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rvalid_delay_inst_00(
   .clk(aclk),
   .in_bus(m00_axi_rvalid),
   .out_bus(m00_axi_rvalid_sort)
);

delay_chain #(
    .WIDTH(C_M00_AXI_ID_WIDTH), 
    .STAGES(10)
) 
rid_delay_inst_00(
   .clk(aclk),
   .in_bus(m00_axi_rid),
   .out_bus(m00_axi_rid_sort)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rxfer_delay_inst_00(
   .clk(aclk),
   .in_bus(rxfer_00),
   .out_bus(rxfer_sort_00)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rlast_delay_inst_00(
   .clk(aclk),
   .in_bus(m00_axi_rlast),
   .out_bus(m00_axi_rlast_sort)
);

delay_chain #(
    .WIDTH(LP_NUM_READ_CHANNELS), 
    .STAGES(10)
) 
r_final_transaction_delay_inst_00(
   .clk(aclk),
   .in_bus(r_final_transaction_00),
   .out_bus(r_final_transaction_sort_00)
);

delay_chain #(
    .WIDTH(LP_NUM_READ_CHANNELS), 
    .STAGES(10)
) 
run_last_delay_inst_00(
   .clk(aclk),
   .in_bus(run_last_00),
   .out_bus(run_last_sort_00)
);

always @(posedge aclk) begin
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    if (read_start_00) begin
      axi_cnt_per_run_00[i] <= 1;
    end
    else if ((axi_cnt_per_run_00[i] == read_run_count) & rxfer_00 & (m00_axi_rid == i)) begin
      axi_cnt_per_run_00[i] <= 1;
    end
    else if (rxfer_00 & (m00_axi_rid == i)) begin
      axi_cnt_per_run_00[i] <= axi_cnt_per_run_00[i] + 1;
    end
    else begin
      axi_cnt_per_run_00[i] <= axi_cnt_per_run_00[i];
    end
  end
end

always_comb begin
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    run_last_00[i] = (axi_cnt_per_run_00[i] == read_run_count) & read_divide;
  end
end

// AXI4 Read Master01, output format is an AXI4-Stream master, 32 streams per thread.
axi_read_master #(
  .C_ID_WIDTH          ( C_M01_AXI_ID_WIDTH         ) ,
  .C_M_AXI_ADDR_WIDTH  ( C_M01_AXI_ADDR_WIDTH       ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M01_AXI_DATA_WIDTH       ) ,
  .C_NUM_CHANNELS      ( LP_NUM_READ_CHANNELS    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH          ) ,
  .C_BURST_SIZE_BYTES  ( LP_BURST_SIZE_BYTES        ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING_01   )
)
AXI_Read_inst01 (
  .aclk                    ( aclk                       ) ,
  .areset                  ( areset                     ) ,
  .ctrl_start              ( read_start_01              ) ,
  .pass_start              ( write_done                 ) ,
  .ctrl_done               ( single_run_read_done_01    ) ,
  .ctrl_addr_offset        ( rd_addr                    ) ,
  .ctrl_xfer_size_in_bytes ( read_size_in_bytes         ) ,

  .m_axi_arvalid           ( m01_axi_arvalid            ) ,
  .m_axi_arready           ( m01_axi_arready            ) ,
  .m_axi_araddr            ( m01_axi_araddr             ) ,
  .m_axi_arid              ( m01_axi_arid               ) ,
  .m_axi_arlen             ( m01_axi_arlen              ) ,
  .m_axi_arsize            ( m01_axi_arsize             ) ,

  .m_axi_rvalid            ( m01_axi_rvalid             ) ,
  .m_axi_rready            ( m01_axi_rready             ) ,
  .m_axi_rdata             ( m01_axi_rdata              ) ,
  .m_axi_rlast             ( m01_axi_rlast              ) ,
  .m_axi_rid               ( m01_axi_rid                ) ,

  .r_final_transaction     ( r_final_transaction_01     ) ,

  .m_axis_tvalid           ( rd_tvalid_01               ) ,
  .m_axis_tready           ( rd_tready_01               )
);

assign read_start_01 = read_start & current_pass[0];
assign rxfer_01 = m01_axi_rvalid & m01_axi_rready;

always_comb begin 
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    rd_tvalid_01[i] = rd_tvalid[i] & current_pass[0]; 
    rd_tready_01[i] = rd_tready[i] & current_pass[0];
  end
end

always_comb begin 
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    tvalid_01[i] = m01_axi_rvalid_sort && (m01_axi_rid_sort == i); 
    tdata_01[i] = m01_axi_rdata_sort;
    tlast_01[i] = rxfer_sort_01 && (m01_axi_rid_sort == i) && ((m01_axi_rlast_sort && r_final_transaction_sort_01[i]) || run_last_sort_01[i]); 
  end
end

presorter #(
    .DATA_WIDTH(C_M01_AXI_DATA_WIDTH/16)
)
presorter_inst_01(
    .aclk(aclk),  
    .in_data(m01_axi_rdata),
    .out_data(m01_axi_rdata_sort)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rvalid_delay_inst_01(
   .clk(aclk),
   .in_bus(m01_axi_rvalid),
   .out_bus(m01_axi_rvalid_sort)
);

delay_chain #(
    .WIDTH(C_M01_AXI_ID_WIDTH), 
    .STAGES(10)
) 
rid_delay_inst_01(
   .clk(aclk),
   .in_bus(m01_axi_rid),
   .out_bus(m01_axi_rid_sort)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rxfer_delay_inst_01(
   .clk(aclk),
   .in_bus(rxfer_01),
   .out_bus(rxfer_sort_01)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rlast_delay_inst_01(
   .clk(aclk),
   .in_bus(m01_axi_rlast),
   .out_bus(m01_axi_rlast_sort)
);

delay_chain #(
    .WIDTH(LP_NUM_READ_CHANNELS), 
    .STAGES(10)
) 
r_final_transaction_delay_inst_01(
   .clk(aclk),
   .in_bus(r_final_transaction_01),
   .out_bus(r_final_transaction_sort_01)
);

delay_chain #(
    .WIDTH(LP_NUM_READ_CHANNELS), 
    .STAGES(10)
) 
run_last_delay_inst_01(
   .clk(aclk),
   .in_bus(run_last_01),
   .out_bus(run_last_sort_01)
);

always @(posedge aclk) begin
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    if (read_start_01) begin
      axi_cnt_per_run_01[i] <= 1;
    end
    else if ((axi_cnt_per_run_01[i] == read_run_count) & rxfer_01 & (m01_axi_rid == i)) begin
      axi_cnt_per_run_01[i] <= 1;
    end
    else if (rxfer_01 & (m01_axi_rid == i)) begin
      axi_cnt_per_run_01[i] <= axi_cnt_per_run_01[i] + 1;
    end
    else begin
      axi_cnt_per_run_01[i] <= axi_cnt_per_run_01[i];
    end
  end
end

always_comb begin
  for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
    run_last_01[i] = (axi_cnt_per_run_01[i] == read_run_count) & read_divide;
  end
end

// xpm_fifo_sync: Synchronous FIFO
// Xilinx Parameterized Macro, Version 2017.4
xpm_fifo_sync # (
  .FIFO_MEMORY_TYPE    ( "auto"               ) , // string; "auto", "block", "distributed", or "ultra";
  .ECC_MODE            ( "no_ecc"             ) , // string; "no_ecc" or "en_ecc";
  .FIFO_WRITE_DEPTH    ( LP_FIFO_DEPTH        ) , // positive integer
  .WRITE_DATA_WIDTH    ( C_M00_AXI_DATA_WIDTH+1 ) , // positive integer
  .WR_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_FULL_THRESH    ( 10                   ) , // positive integer, not used
  .FULL_RESET_VALUE    ( 1                    ) , // positive integer; 0 or 1
  .USE_ADV_FEATURES    ( "1F1F"               ) , // string; "0000" to "1F1F";
  .READ_MODE           ( "fwft"               ) , // string; "std" or "fwft";
  .FIFO_READ_LATENCY   ( LP_FIFO_READ_LATENCY ) , // positive integer;
  .READ_DATA_WIDTH     ( C_M00_AXI_DATA_WIDTH+1 ) , // positive integer
  .RD_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_EMPTY_THRESH   ( 10                   ) , // positive integer, not used
  .DOUT_RESET_VALUE    ( "0"                  ) , // string, don't care
  .WAKEUP_TIME         ( 0                    ) // positive integer; 0 or 2;
)
inst_rd_xpm_fifo_sync[LP_NUM_READ_CHANNELS-1:0] (
  .sleep         ( 1'b0                        ) ,
  .rst           ( areset                      ) ,
  .wr_clk        ( aclk                        ) ,
  .wr_en         ( tvalid_delay                ) ,
  .din           ( fifo_din_delay              ) ,
  .full          ( fifo_full                   ) ,
  .overflow      (                             ) ,
  .prog_full     (                             ) ,
  .wr_data_count (                             ) ,
  .almost_full   (                             ) ,
  .wr_ack        (                             ) ,
  .wr_rst_busy   (                             ) ,
  .rd_en         ( rd_tready                   ) ,
  .dout          ( fifo_dout                   ) ,
  .empty         ( fifo_empty                  ) ,
  .prog_empty    (                             ) ,
  .rd_data_count (                             ) ,
  .almost_empty  (                             ) ,
  .data_valid    ( rd_tvalid                   ) ,
  .underflow     (                             ) ,
  .rd_rst_busy   (                             ) ,
  .injectsbiterr ( 1'b0                        ) ,
  .injectdbiterr ( 1'b0                        ) ,
  .sbiterr       (                             ) ,
  .dbiterr       (                             )
) ;

always_comb begin 
    for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
      tvalid[i] = current_pass[0] ? tvalid_01[i] : tvalid_00[i]; 
    end
end

always_comb begin 
    for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
      fifo_din[i] = current_pass[0] ? {tlast_01[i], tdata_01[i]} : {tlast_00[i], tdata_00[i]}; 
    end
end

delay_chain #(
    .WIDTH(LP_NUM_READ_CHANNELS), 
    .STAGES(1)
) 
tvalid_delay_inst(
   .clk(aclk),
   .in_bus(tvalid),
   .out_bus(tvalid_delay)
);

delay_chain #(
    .WIDTH(C_M00_AXI_DATA_WIDTH+1), 
    .STAGES(1)
) 
fifo_din_delay_inst[LP_NUM_READ_CHANNELS-1:0](
   .clk(aclk),
   .in_bus(fifo_din),
   .out_bus(fifo_din_delay)
);

always_comb begin 
    for (int i = 0; i < LP_NUM_READ_CHANNELS; i++) begin
      tlast_fifo_out[i] = fifo_dout[i][C_M00_AXI_DATA_WIDTH];
      tdata_fifo_out[i] = fifo_dout[i][C_M00_AXI_DATA_WIDTH-1:0];
    end
end

assign rd_tdata = tdata_fifo_out;
assign rd_tlast = tlast_fifo_out;

// merger kernel
MERGER_INTEGRATION #(
  .C_AXIS_TDATA_WIDTH ( C_M00_AXI_DATA_WIDTH ) ,
  .C_SORTER_BIT_WIDTH ( C_SORTER_BIT_WIDTH   ) ,
  .NUM_READ_CHANNELS  ( LP_NUM_READ_CHANNELS ) ,
  .C_NUM_CLOCKS       ( 1                    )
)
MERGER_INTEGRATION_inst0  (
  .s_axis_aclk   ( kernel_clk                           ) ,
  .s_axis_areset ( kernel_rst                           ) ,

  .s_axis_tvalid ( rd_tvalid                             ) ,
  .s_axis_tready ( rd_tready                             ) ,
  .s_axis_tdata  ( rd_tdata                              ) ,
  .s_axis_tlast  ( rd_tlast                              ) , 
  
  .m_axis_aclk   ( kernel_clk                            ) ,
  .m_axis_areset ( kernel_rst                            ) ,

  .m_axis_tvalid ( merger_out_tvalid                     ) ,
  .m_axis_tready ( merger_out_tready                     ) ,
  .m_axis_tdata  ( merger_out_tdata                      ) ,
  .m_axis_tkeep  (                                       ) , // Not used
  .m_axis_tlast  (                                       )   // Not used
);

// AXI write master stage

// AXI4 Write Master 00
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
  .ctrl_start              ( write_start & current_pass[0]),
  .ctrl_done               ( write_done_00           ) ,
  .ctrl_addr_offset        ( write_addr              ) ,
  .ctrl_xfer_size_in_bytes ( out_xfer_size_in_bytes  ) ,
  .m_axi_awvalid           ( m00_axi_awvalid         ) ,
  .m_axi_awready           ( m00_axi_awready         ) ,
  .m_axi_awaddr            ( m00_axi_awaddr          ) ,
  .m_axi_awlen             ( m00_axi_awlen           ) ,
  .m_axi_wvalid            ( m00_axi_wvalid          ) ,
  .m_axi_wready            ( m00_axi_wready          ) ,
  .m_axi_wdata             ( m00_axi_wdata           ) ,
  .m_axi_wstrb             ( m00_axi_wstrb           ) ,
  .m_axi_wlast             ( m00_axi_wlast           ) ,
  .m_axi_bvalid            ( m00_axi_bvalid          ) ,
  .m_axi_bready            ( m00_axi_bready          ) ,
  .s_axis_aclk             ( kernel_clk              ) ,
  .s_axis_areset           ( kernel_rst              ) ,
  .s_axis_tvalid           ( merger_out_tvalid & current_pass[0]) ,
  .s_axis_tready           ( merger_out_tready_00    ) ,
  .s_axis_tdata            ( merger_out_tdata        )
);

// AXI4 Write Master 01
axi_write_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M01_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M01_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH     ) ,
  .C_MAX_OUTSTANDING   ( LP_WR_MAX_OUTSTANDING_01 ) ,
  .C_INCLUDE_DATA_FIFO ( 1                     )
)
AXI_write_inst01 (
  .aclk                    ( aclk                    ) ,
  .areset                  ( areset                  ) ,
  .ctrl_start              ( write_start & (~current_pass[0])) ,
  .ctrl_done               ( write_done_01           ) ,
  .ctrl_addr_offset        ( write_addr              ) ,
  .ctrl_xfer_size_in_bytes ( out_xfer_size_in_bytes  ) ,
  .m_axi_awvalid           ( m01_axi_awvalid         ) ,
  .m_axi_awready           ( m01_axi_awready         ) ,
  .m_axi_awaddr            ( m01_axi_awaddr          ) ,
  .m_axi_awlen             ( m01_axi_awlen           ) ,
  .m_axi_wvalid            ( m01_axi_wvalid          ) ,
  .m_axi_wready            ( m01_axi_wready          ) ,
  .m_axi_wdata             ( m01_axi_wdata           ) ,
  .m_axi_wstrb             ( m01_axi_wstrb           ) ,
  .m_axi_wlast             ( m01_axi_wlast           ) ,
  .m_axi_bvalid            ( m01_axi_bvalid          ) ,
  .m_axi_bready            ( m01_axi_bready          ) ,
  .s_axis_aclk             ( kernel_clk              ) ,
  .s_axis_areset           ( kernel_rst              ) ,
  .s_axis_tvalid           ( merger_out_tvalid & (~current_pass[0])) ,
  .s_axis_tready           ( merger_out_tready_01    ) ,
  .s_axis_tdata            ( merger_out_tdata        )
);

time_cnt time_cnt_inst_0(
    .aclk(aclk),
    .ap_start(ap_start),
    .time_out(time_out)
);

assign ap_done = all_done | time_out;

endmodule : MERGER_TREE_P16_L32_I64_MB_TOP
`default_nettype wire

