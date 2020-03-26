// Address calculator for multipass
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
module addr_cal #(
  parameter integer NUM_READ_CHANNELS         = 1 , 
  parameter integer C_M_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_XFER_SIZE_WIDTH        = 32 
)
(
  // System Signals
  input wire                                                    aclk                 ,
  // Engine signal
  input wire                                                    ap_start             ,
  output wire                                                   ap_done              ,  
  // AXI read control information
  input wire [8-1:0]                                            num_pass             ,
  input wire [64-1:0]                                           single_trans_bytes   ,
  input wire [32-1:0]                                           log_single_trans_bytes,
  input wire [C_M_AXI_ADDR_WIDTH-1:0]                           in_addr_offset       ,
  input wire [C_XFER_SIZE_WIDTH-1:0]                            in_xfer_size_in_bytes, // total input size in bytes
  input wire [C_M_AXI_ADDR_WIDTH-1:0]                           out_addr_offset      ,  
  input wire                                                    single_run_read_done ,
  input wire                                                    write_done           , // write done means one pass is done
  output wire                                                   read_start           ,
  output wire [NUM_READ_CHANNELS-1:0][C_M_AXI_ADDR_WIDTH-1:0]   read_addr            ,
  output wire [C_XFER_SIZE_WIDTH-1:0]                           read_size_in_bytes   ,
  output wire                                                   write_start          ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]                          write_addr                                 
);

timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_SINGLE_TRANSFER_BYTES          = 256; // start from 64-element chunk
localparam integer LP_LOG_SINGLE_TRANSFER_BYTES      = $clog2(LP_SINGLE_TRANSFER_BYTES);
localparam integer LP_NUM_READ_NODES                 = NUM_READ_CHANNELS;
localparam integer LP_PASS_INCREMENT                 = $clog2(LP_NUM_READ_NODES); // each pass increase bytes by 2^3 

///////////////////////////////////////////////////////////////////////////////
// Addr control information
///////////////////////////////////////////////////////////////////////////////
logic                                                          ap_start_delay = 0;
logic                                                          single_run_read_done_delay = 0; 
logic                                                          write_done_delay = 0;

logic [8-1:0]                                                  pass_count = 0;         // count how many passes have been done
logic [C_XFER_SIZE_WIDTH-1:0]                                  run_count = 0;          // count how many runs already been done for the current pass.

logic [C_M_AXI_ADDR_WIDTH-1:0]                                 ctrl_addr_multi_run = 0;    // the starting addr for multi-runs read
logic [NUM_READ_CHANNELS-1:0][C_M_AXI_ADDR_WIDTH-1:0]          ctrl_addr_offset;        // read address for each node
logic [C_XFER_SIZE_WIDTH-1:0]                                  single_transfer_bytes = 0;  // for each pass, it increases by 2^LP_PASS_INCREMENT;

logic [C_XFER_SIZE_WIDTH-1:0]                                  log_run_size_in_bytes = 0;

logic [C_M_AXI_ADDR_WIDTH-1:0]                                 ctrl_addr_write = 0; // write addr

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////
assign read_start = ap_start_delay || (write_done_delay && (pass_count != num_pass)) || (single_run_read_done_delay && run_count < (in_xfer_size_in_bytes >> log_run_size_in_bytes));
assign read_addr = ctrl_addr_offset;
assign read_size_in_bytes = single_transfer_bytes;
assign ap_done = write_done && (pass_count == (num_pass - 1));

assign write_start = ap_start_delay || (write_done_delay && (pass_count != num_pass));
assign write_addr = ctrl_addr_write;

// calculate pass_count
always @(posedge aclk) begin
    if (ap_start) begin
        pass_count <= 0;
    end
    else if (write_done) begin
        pass_count <= pass_count + 1;
    end
end

// calculate run_count
always @(posedge aclk) begin
  if (ap_start | write_done) begin
    run_count <= 0;
  end
  else if (single_run_read_done) begin
    run_count <= run_count + 1;
  end
end

// calculate ctrl_addr_write
always @(posedge aclk) begin
    if(ap_start) begin
        ctrl_addr_write <= out_addr_offset;
    end
    else if (write_done && (~pass_count[0])) begin
        ctrl_addr_write <= in_addr_offset;
    end 
    else if (write_done && pass_count[0]) begin
        ctrl_addr_write <= out_addr_offset;
    end
end

// calculate ctrl_addr_multi_run
always @(posedge aclk) begin
    if (ap_start) begin
        ctrl_addr_multi_run <= in_addr_offset;
    end
    else if (write_done && (~pass_count[0])) begin
        ctrl_addr_multi_run <= out_addr_offset;
    end
    else if (write_done && pass_count[0]) begin
        ctrl_addr_multi_run <= in_addr_offset;
    end
    else if (single_run_read_done) begin
        ctrl_addr_multi_run <= ctrl_addr_multi_run + LP_NUM_READ_NODES * single_transfer_bytes;
    end
end

// calculate read address for each node
always_comb begin
    for (int i = 0; i < LP_NUM_READ_NODES; i++) begin
        ctrl_addr_offset[i] = ctrl_addr_multi_run + i * single_transfer_bytes;
    end
end

// calculate single_transfer_bytes
always @(posedge aclk) begin
    if (ap_start) begin
        single_transfer_bytes <= single_trans_bytes;
    end
    else if(write_done) begin
        single_transfer_bytes <= single_transfer_bytes << LP_PASS_INCREMENT;
    end
end

// calculate log_run_size_in_bytes
always @(posedge aclk) begin
    if (ap_start) begin
        log_run_size_in_bytes <= log_single_trans_bytes + LP_PASS_INCREMENT;
    end
    else if(write_done) begin
        log_run_size_in_bytes <= log_run_size_in_bytes + LP_PASS_INCREMENT;
    end
end

// delay ap_start_delay for 1 cycle
always @(posedge aclk) begin
  ap_start_delay <= ap_start;
end

// delay single_run_read_done for 1 cycle
always @(posedge aclk) begin
  single_run_read_done_delay <= single_run_read_done;
end

// delay write_done_delay for 1 cycle
always @(posedge aclk) begin
  write_done_delay <= write_done;
end

endmodule : addr_cal
`default_nettype wire