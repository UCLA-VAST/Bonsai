///////////////////////////////////////////////////////////////////////////////
// 
// Description: This is a multi-threaded AXI4 read master. Each channel will 
// issue commands on a different IDs. As a result data may arrive out ot order
///////////////////////////////////////////////////////////////////////////////

// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module axi_read_master #(
  // set the channel ID width
  // Must be >= $clog2(C_NUM_CHANNELS)
  parameter integer C_ID_WIDTH  = 1,

  // Set to the address width of the interface
  parameter integer C_M_AXI_ADDR_WIDTH  = 64,

  // Set the data width of the interface
  // Range: 32, 64, 128, 256, 512, 1024
  parameter integer C_M_AXI_DATA_WIDTH  = 32,

  // Set the number of channels this AXI read master will connect
  parameter integer C_NUM_CHANNELS = 2,

  // Width of the ctrl_xfer_size_in_bytes input
  // Range: 16:C_M_AXI_ADDR_WIDTH
  parameter integer C_XFER_SIZE_WIDTH   = C_M_AXI_ADDR_WIDTH,

  // Specifies how many bytes each full burst is
  parameter integer C_BURST_SIZE_BYTES = 1024,

  // Specifies the maximum number of AXI4 transactions that may be outstanding.
  // Affects FIFO depth if data FIFO is enabled.
  parameter integer C_MAX_OUTSTANDING   = 16, 

  // Includes a data fifo between the AXI4 read channel master and the AXI4-Stream
  // master.  It will be sized to hold C_MAX_OUTSTANDING transactions. If no
  // FIFO is instantiated then the AXI4 read channel is passed through to the
  // AXI4-Stream slave interface.
  // Range: 0, 1
  parameter integer C_INCLUDE_DATA_FIFO = 1
)
(
  // System signals
  input  wire                                               aclk,
  input  wire                                               areset,

  // Control signals
  input  wire                                               ctrl_start,              // Pulse high for one cycle to begin reading
  input  wire                                               pass_start,              // Pusle high for one cycle to indicate one pass begin
  output wire                                               ctrl_done,               // Pulses high for one cycle when transfer request is complete

  // The following ctrl signals are sampled when ctrl_start is asserted
  input  wire [C_NUM_CHANNELS-1:0][C_M_AXI_ADDR_WIDTH-1:0]  ctrl_addr_offset,        // Starting Address offset
  input  wire                     [C_XFER_SIZE_WIDTH-1:0]   ctrl_xfer_size_in_bytes, // Length in number of bytes, limited by the address width.
  input  wire                                               ctrl_read_divide,        // A full axi read burst needs to be divided for multiple run.
  input  wire                     [C_XFER_SIZE_WIDTH-1:0]   ctrl_read_run_count,     // How many 512-bit axi transfer is needed for the current run.

  // AXI4 master interface (read only)
  output wire                                               m_axi_arvalid,
  input  wire                                               m_axi_arready,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]                      m_axi_araddr,
  output wire [C_ID_WIDTH-1:0]                              m_axi_arid,
  output wire [8-1:0]                                       m_axi_arlen,
  output wire [3-1:0]                                       m_axi_arsize,

  input  wire                                               m_axi_rvalid,
  output wire                                               m_axi_rready,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]                      m_axi_rdata,
  input  wire                                               m_axi_rlast,
  input  wire [C_ID_WIDTH - 1:0]                            m_axi_rid,

  // AXI4-Stream master interface
  input  wire                                               m_axis_aclk,
  input  wire                                               m_axis_areset,
  output wire [C_NUM_CHANNELS-1:0]                          m_axis_tvalid,
  input  wire [C_NUM_CHANNELS-1:0]                          m_axis_tready,
  output wire [C_NUM_CHANNELS-1:0][C_M_AXI_DATA_WIDTH-1:0]  m_axis_tdata,
  output wire [C_NUM_CHANNELS-1:0]                          m_axis_tlast
  
);

timeunit 1ps;
timeprecision 1ps;
///////////////////////////////////////////////////////////////////////////////
// functions
///////////////////////////////////////////////////////////////////////////////
function integer f_max (
  input integer a,
  input integer b
);
  f_max = (a > b) ? a : b;
endfunction

function integer f_min (
  input integer a,
  input integer b
);
  f_min = (a < b) ? a : b;
endfunction

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES                   = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_LOG_DW_BYTES               = $clog2(LP_DW_BYTES);
localparam integer LP_MAX_BURST_LENGTH           = 256;   // Max AXI Protocol burst length
localparam integer LP_MAX_BURST_BYTES            = C_BURST_SIZE_BYTES;  // Max AXI Protocol burst size in bytes
localparam integer LP_AXI_BURST_LEN              = f_min(LP_MAX_BURST_BYTES/LP_DW_BYTES, LP_MAX_BURST_LENGTH);
localparam integer LP_LOG_BURST_LEN              = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_OUTSTANDING_CNTR_WIDTH     = $clog2(C_MAX_OUTSTANDING+1);
localparam integer LP_TOTAL_LEN_WIDTH            = C_XFER_SIZE_WIDTH-LP_LOG_DW_BYTES;
localparam integer LP_TRANSACTION_CNTR_WIDTH     = LP_TOTAL_LEN_WIDTH-LP_LOG_BURST_LEN;
localparam [C_M_AXI_ADDR_WIDTH-1:0] LP_ADDR_MASK = LP_DW_BYTES*LP_AXI_BURST_LEN - 1;
// FIFO Parameters
localparam integer LP_FIFO_DEPTH                 = 2**($clog2(LP_AXI_BURST_LEN*C_MAX_OUTSTANDING)); // Ensure power of 2
localparam integer LP_FIFO_READ_LATENCY          = 2; // 2: Registered output on BRAM, 1: Registered output on LUTRAM
localparam integer LP_FIFO_COUNT_WIDTH           = $clog2(LP_FIFO_DEPTH)+1;

///////////////////////////////////////////////////////////////////////////////
// Variables
///////////////////////////////////////////////////////////////////////////////
// Control logic
logic [C_NUM_CHANNELS-1:0]                                    done = '0;
logic                                                         has_partial_bursts;
logic                                                         start_d1 = 1'b0;
logic [C_NUM_CHANNELS-1:0][C_M_AXI_ADDR_WIDTH-1:0]            addr_offset_r;
logic                                                         start    = 1'b0;
logic [LP_TOTAL_LEN_WIDTH-1:0]                                total_len_r;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]                         num_transactions;
logic [LP_LOG_BURST_LEN-1:0]                                  final_burst_len;
logic                                                         single_transaction;
logic [C_NUM_CHANNELS-1:0]                                    ar_idle = {C_NUM_CHANNELS{1'b1}};
logic [C_NUM_CHANNELS-1:0]                                    ar_done_i = '0;
logic                                                         ar_done;

logic                                                         pass_start_d1;
logic                                                         pass_start_d2;
logic                                                         pass_start_d3;
// AXI Read Address Channel
//logic                                                         fifo_stall;
logic                                                         arxfer_general;
logic [C_NUM_CHANNELS-1:0]                                    arxfer = '0;
logic [C_NUM_CHANNELS-1:0]                                    arvalid_r = '0;
logic [C_NUM_CHANNELS-1:0][C_M_AXI_ADDR_WIDTH-1:0]            addr;
logic [C_ID_WIDTH-1:0]                                        id = {C_ID_WIDTH{1'b1}};
logic [C_NUM_CHANNELS-1:0][LP_TRANSACTION_CNTR_WIDTH-1:0]     ar_transactions_to_go;
logic [C_NUM_CHANNELS-1:0]                                    ar_final_transaction;
logic [C_NUM_CHANNELS-1:0]                                    incr_ar_to_r_cnt;
logic [C_NUM_CHANNELS-1:0]                                    decr_ar_to_r_cnt;
logic [C_NUM_CHANNELS-1:0]                                    stall_ar;
logic [C_NUM_CHANNELS-1:0]                                    stall_ar_d = '0;
logic [C_NUM_CHANNELS-1:0][LP_OUTSTANDING_CNTR_WIDTH-1:0]     outstanding_vacancy_count;
// AXI Data Channel
logic [C_NUM_CHANNELS-1:0]                                    tvalid;
logic [C_NUM_CHANNELS-1:0][C_M_AXI_DATA_WIDTH-1:0]            tdata;
logic [C_NUM_CHANNELS-1:0]                                    tlast;
logic                                                         rxfer;
logic [C_NUM_CHANNELS-1:0]                                    r_completed;
logic [C_NUM_CHANNELS-1:0]                                    decr_r_transaction_cntr;
logic [C_NUM_CHANNELS-1:0][LP_TRANSACTION_CNTR_WIDTH-1:0]     r_transactions_to_go;
logic [C_NUM_CHANNELS-1:0]                                    r_final_transaction;
logic [C_NUM_CHANNELS-1:0][LP_LOG_BURST_LEN-1:0]              tcnt = '0;

//logic [C_NUM_CHANNELS-1:0]                                    ctrl_prog_full;
logic [C_NUM_CHANNELS-1:0][C_M_AXI_DATA_WIDTH:0]              fifo_din;
logic [C_NUM_CHANNELS-1:0]                                    fifo_empty; // for debug
logic [C_NUM_CHANNELS-1:0]                                    fifo_full; // for debug
logic [C_NUM_CHANNELS-1:0][C_M_AXI_DATA_WIDTH:0]              fifo_dout;
logic [C_NUM_CHANNELS-1:0]                                    tlast_fifo_out;
logic [C_NUM_CHANNELS-1:0][C_M_AXI_DATA_WIDTH-1:0]            tdata_fifo_out;

// presorted data
logic [C_M_AXI_DATA_WIDTH-1:0]                                m_axi_rdata_sort;
logic                                                         m_axi_rvalid_sort;
logic                                                         rxfer_sort;
logic                                                         m_axi_rlast_sort;
logic [C_ID_WIDTH - 1:0]                                      m_axi_rid_sort;
logic [C_NUM_CHANNELS-1:0]                                    r_final_transaction_sort;

// multiple run info
logic [C_NUM_CHANNELS-1:0][C_XFER_SIZE_WIDTH-1:0]             axi_cnt_per_run;
logic [C_NUM_CHANNELS-1:0]                                    run_last;
logic [C_NUM_CHANNELS-1:0]                                    run_last_sort;



///////////////////////////////////////////////////////////////////////////////
// Control Logic
///////////////////////////////////////////////////////////////////////////////

always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    done[i] <= rxfer & m_axi_rlast & (m_axi_rid == i) & r_final_transaction[i] ? 1'b1 : 
               ctrl_done ? 1'b0 : done[i];
  end
end

assign ctrl_done = &done;

always @(posedge aclk) begin
  start_d1 <= ctrl_start;
  start <= start_d1;
end

always @(posedge aclk) begin
  pass_start_d1 <= pass_start;
  pass_start_d2 <= pass_start_d1;
  pass_start_d3 <= pass_start_d2;
end

// Store the address and transfer size after some pre-processing.
always @(posedge aclk) begin
  if (ctrl_start) begin
    // Round transfer size up to integer value of the axi interface data width. Convert to axi_arlen format which is length -1.
    total_len_r <= ctrl_xfer_size_in_bytes[0+:LP_LOG_DW_BYTES] > 0
                      ? ctrl_xfer_size_in_bytes[LP_LOG_DW_BYTES+:LP_TOTAL_LEN_WIDTH]
                      : ctrl_xfer_size_in_bytes[LP_LOG_DW_BYTES+:LP_TOTAL_LEN_WIDTH] - 1'b1;
    for (int i = 0; i < C_NUM_CHANNELS; i++) begin
      addr_offset_r[i] <= ctrl_addr_offset[i];
    end
  end
end

// Determine how many full burst to issue and if there are any partial bursts.
assign num_transactions = total_len_r[LP_LOG_BURST_LEN+:LP_TRANSACTION_CNTR_WIDTH];
assign has_partial_bursts = total_len_r[0+:LP_LOG_BURST_LEN] == {LP_LOG_BURST_LEN{1'b1}} ? 1'b0 : 1'b1;

always @(posedge aclk) begin
  final_burst_len <=  total_len_r[0+:LP_LOG_BURST_LEN];
end

// Special case if there is only 1 AXI transaction.
assign single_transaction = (num_transactions == {LP_TRANSACTION_CNTR_WIDTH{1'b0}}) ? 1'b1 : 1'b0;

///////////////////////////////////////////////////////////////////////////////
// AXI Read Address Channel
///////////////////////////////////////////////////////////////////////////////
assign m_axi_arvalid = arvalid_r[id];
assign m_axi_araddr = addr[id];
assign m_axi_arlen  = ar_final_transaction[id] || (start & single_transaction) ? final_burst_len : LP_AXI_BURST_LEN - 1;
assign m_axi_arsize = $clog2((C_M_AXI_DATA_WIDTH/8));
assign m_axi_arid = id;

// assign arxfer = m_axi_arvalid & m_axi_arready;
assign arxfer_general = m_axi_arvalid & m_axi_arready;
always_comb begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    arxfer[i] = m_axi_arvalid & m_axi_arready & (id == i);
  end
end

//assign fifo_stall = ctrl_prog_full[id];

always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    if (areset) begin
      arvalid_r[i] <= 1'b0;
    end
    else begin
      arvalid_r[i] <= ~ar_idle[i] & ~stall_ar[i] & ~arvalid_r[i] ? 1'b1 :
                  m_axi_arready ? 1'b0 : arvalid_r[i];
    end
  end
end

// When ar_idle, there are no transactions to issue.
always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    if (areset) begin
      ar_idle[i] <= 1'b1;
    end
    else begin
      ar_idle[i] <= start   ? 1'b0 :
                ar_done_i[i] ? 1'b1 :
                          ar_idle[i];
    end
  end
end

// delay stall_ar for 1 cycle to match arvalid_r
always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    stall_ar_d[i] <= stall_ar[i];
  end
end

// each channel is assigned a different id. The transactions are interleaved.
always @(posedge aclk) begin
  if (start) begin
    id <= {C_ID_WIDTH{1'b1}};
  end
  else begin
    id <= (arxfer_general | (~m_axi_arvalid & m_axi_arready & stall_ar_d[id]) | ar_done_i[id])? id - 1'b1 : id;
  end
end


// Increment to next address after each transaction is issued.
always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    addr[i] <= start               ? addr_offset_r[i] :
               arxfer[i] ? addr[i] + LP_AXI_BURST_LEN*C_M_AXI_DATA_WIDTH/8 :
                                     addr[i];
  end
end

// Counts down the number of transactions to send.
genvar k;
generate 
  for(k = 0; k < C_NUM_CHANNELS; k++) begin: ar_transaction_cntr 
  axi_transaction_counter #(
  .C_WIDTH ( LP_TRANSACTION_CNTR_WIDTH         ) ,
  .C_INIT  ( {LP_TRANSACTION_CNTR_WIDTH{1'b0}} )
  )
  inst_ar_transaction_cntr (
    .clk        ( aclk                   ) ,
    .clken      ( 1'b1                   ) ,
    .rst        ( areset                 ) ,
    .load       ( start                  ) ,
    .incr       ( 1'b0                   ) ,
    .decr       ( arxfer[k]              ) ,
    .load_value ( num_transactions       ) ,
    .count      ( ar_transactions_to_go[k]  ) ,
    .is_zero    ( ar_final_transaction[k]   )
  );
  end
endgenerate

always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    ar_done_i[i] <= ar_final_transaction[i] & arxfer[i] ? 1'b1 :
                    ar_done ? 1'b0 : ar_done_i[i];
  end
end

assign ar_done = &ar_done_i;

assign r_completed = incr_ar_to_r_cnt;

always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    if (start & pass_start_d3) begin
      tcnt[i] <= {LP_LOG_BURST_LEN{1'b0}};
    end
    else if (m_axis_tvalid[i] & m_axis_tready[i]) begin
      if (tcnt[i] == (LP_AXI_BURST_LEN-1)) begin
        tcnt[i] <= {LP_LOG_BURST_LEN{1'b0}};
      end
      else begin
        tcnt[i] <= tcnt[i] + 1;
      end
    end
  end
end

always_comb begin 
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin 
    incr_ar_to_r_cnt[i] = m_axis_tvalid[i] & m_axis_tready[i] & (tcnt[i] == (LP_AXI_BURST_LEN-1));
    decr_ar_to_r_cnt[i] = arxfer[i];
  end
end

// Keeps track of the number of outstanding transactions. Stalls
// when the value is reached so that the FIFO won't overflow.
// If no FIFO present, then just limit at max outstanding transactions.
axi_transaction_counter #(
  .C_WIDTH ( LP_OUTSTANDING_CNTR_WIDTH                       ) ,
  .C_INIT  ( C_MAX_OUTSTANDING[0+:LP_OUTSTANDING_CNTR_WIDTH] )
)
inst_ar_to_r_transaction_cntr[C_NUM_CHANNELS-1:0] (
  .clk        ( aclk                              ) ,
  .clken      ( 1'b1                              ) ,
  .rst        ( areset                            ) ,
  .load       ( 1'b0                              ) ,
  .incr       ( incr_ar_to_r_cnt                  ) ,
  .decr       ( decr_ar_to_r_cnt                  ) ,
  .load_value ( {LP_OUTSTANDING_CNTR_WIDTH{1'b0}} ) ,
  .count      ( outstanding_vacancy_count         ) ,
  .is_zero    ( stall_ar                          )
);


///////////////////////////////////////////////////////////////////////////////
// AXI Read Channel
///////////////////////////////////////////////////////////////////////////////
generate
if (C_INCLUDE_DATA_FIFO == 1) begin : gen_fifo

  // xpm_fifo_sync: Synchronous FIFO
  // Xilinx Parameterized Macro, Version 2017.4
  xpm_fifo_sync # (
    .FIFO_MEMORY_TYPE    ( "distributed"        ) , // string; "auto", "block", "distributed", or "ultra";
    .ECC_MODE            ( "no_ecc"             ) , // string; "no_ecc" or "en_ecc";
    .FIFO_WRITE_DEPTH    ( LP_FIFO_DEPTH        ) , // positive integer
    .WRITE_DATA_WIDTH    ( C_M_AXI_DATA_WIDTH+1 ) , // positive integer
    .WR_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
    .PROG_FULL_THRESH    ( 10                   ) , // positive integer, not used
    .FULL_RESET_VALUE    ( 1                    ) , // positive integer; 0 or 1
    .USE_ADV_FEATURES    ( "1F1F"               ) , // string; "0000" to "1F1F";
    .READ_MODE           ( "fwft"               ) , // string; "std" or "fwft";
    .FIFO_READ_LATENCY   ( LP_FIFO_READ_LATENCY ) , // positive integer;
    .READ_DATA_WIDTH     ( C_M_AXI_DATA_WIDTH+1 ) , // positive integer
    .RD_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
    .PROG_EMPTY_THRESH   ( 10                   ) , // positive integer, not used
    .DOUT_RESET_VALUE    ( "0"                  ) , // string, don't care
    .WAKEUP_TIME         ( 0                    ) // positive integer; 0 or 2;
  )
  inst_rd_xpm_fifo_sync[C_NUM_CHANNELS-1:0] (
    .sleep         ( 1'b0                        ) ,
    .rst           ( areset                      ) ,
    .wr_clk        ( aclk                        ) ,
    .wr_en         ( tvalid                      ) ,
    .din           ( fifo_din                    ) ,
    .full          ( fifo_full                   ) ,
    .overflow      (                             ) ,
    .prog_full     (                             ) ,
    .wr_data_count (                             ) ,
    .almost_full   (                             ) ,
    .wr_ack        (                             ) ,
    .wr_rst_busy   (                             ) ,
    .rd_en         ( m_axis_tready               ) ,
    .dout          ( fifo_dout                   ) ,
    .empty         ( fifo_empty                  ) ,
    .prog_empty    (                             ) ,
    .rd_data_count (                             ) ,
    .almost_empty  (                             ) ,
    .data_valid    ( m_axis_tvalid               ) ,
    .underflow     (                             ) ,
    .rd_rst_busy   (                             ) ,
    .injectsbiterr ( 1'b0                        ) ,
    .injectdbiterr ( 1'b0                        ) ,
    .sbiterr       (                             ) ,
    .dbiterr       (                             )
  ) ;
  
  always_comb begin 
      for (int i = 0; i < C_NUM_CHANNELS; i++) begin
        fifo_din[i] = {tlast[i], tdata[i]}; 
        tlast_fifo_out[i] = fifo_dout[i][C_M_AXI_DATA_WIDTH];
        tdata_fifo_out[i] = fifo_dout[i][C_M_AXI_DATA_WIDTH-1:0];
      end
  end
  
  assign m_axis_tdata = tdata_fifo_out;
  assign m_axis_tlast = tlast_fifo_out;

  assign m_axi_rready = 1'b1;
end
else begin : gen_no_fifo

  // All signals pass through.
  assign m_axis_tvalid = tvalid;
  assign m_axis_tdata = tdata;
  assign m_axi_rready  = m_axis_tready;
  assign m_axis_tlast  = tlast;
end
endgenerate

always_comb begin 
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    tvalid[i] = m_axi_rvalid_sort && (m_axi_rid_sort == i); 
    tdata[i] = m_axi_rdata_sort;
    tlast[i] = rxfer_sort && (m_axi_rid_sort == i) && ((m_axi_rlast_sort && r_final_transaction_sort[i]) || run_last_sort[i]);
  end
end

presorter #(
    .DATA_WIDTH(C_M_AXI_DATA_WIDTH/16)
)
presorter_inst(
    .aclk(aclk),  
    .in_data(m_axi_rdata),
    .out_data(m_axi_rdata_sort)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rvalid_delay_inst(
   .clk(aclk),
   .in_bus(m_axi_rvalid),
   .out_bus(m_axi_rvalid_sort)
);

delay_chain #(
    .WIDTH(C_ID_WIDTH), 
    .STAGES(10)
) 
rid_delay_inst(
   .clk(aclk),
   .in_bus(m_axi_rid),
   .out_bus(m_axi_rid_sort)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rxfer_delay_inst(
   .clk(aclk),
   .in_bus(rxfer),
   .out_bus(rxfer_sort)
);

delay_chain #(
    .WIDTH(1), 
    .STAGES(10)
) 
rlast_delay_inst(
   .clk(aclk),
   .in_bus(m_axi_rlast),
   .out_bus(m_axi_rlast_sort)
);

delay_chain #(
    .WIDTH(C_NUM_CHANNELS), 
    .STAGES(10)
) 
r_final_transaction_delay_inst(
   .clk(aclk),
   .in_bus(r_final_transaction),
   .out_bus(r_final_transaction_sort)
);

delay_chain #(
    .WIDTH(C_NUM_CHANNELS), 
    .STAGES(10)
) 
run_last_delay_inst(
   .clk(aclk),
   .in_bus(run_last),
   .out_bus(run_last_sort)
);

assign rxfer = m_axi_rready & m_axi_rvalid;

always_comb begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    decr_r_transaction_cntr[i] = rxfer & m_axi_rlast & (m_axi_rid == i);
  end
end

always @(posedge aclk) begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    if (ctrl_start) begin
      axi_cnt_per_run[i] <= 1;
    end
    else if ((axi_cnt_per_run[i] == ctrl_read_run_count) & rxfer & (m_axi_rid == i)) begin
      axi_cnt_per_run[i] <= 1;
    end
    else if (rxfer & (m_axi_rid == i)) begin
      axi_cnt_per_run[i] <= axi_cnt_per_run[i] + 1;
    end
    else begin
      axi_cnt_per_run[i] <= axi_cnt_per_run[i];
    end
  end
end

always_comb begin
  for (int i = 0; i < C_NUM_CHANNELS; i++) begin
    run_last[i] = (axi_cnt_per_run[i] == ctrl_read_run_count) & ctrl_read_divide;
  end
end

axi_transaction_counter #(
  .C_WIDTH ( LP_TRANSACTION_CNTR_WIDTH         ) ,
  .C_INIT  ( {LP_TRANSACTION_CNTR_WIDTH{1'b0}} )
)
inst_r_transaction_cntr[C_NUM_CHANNELS-1:0] (
  .clk        ( aclk                          ) ,
  .clken      ( 1'b1                          ) ,
  .rst        ( areset                        ) ,
  .load       ( start                         ) ,
  .incr       ( 1'b0                          ) ,
  .decr       ( decr_r_transaction_cntr       ) ,
  .load_value ( num_transactions              ) ,
  .count      ( r_transactions_to_go          ) ,
  .is_zero    ( r_final_transaction           )
);

endmodule : axi_read_master

`default_nettype wire

