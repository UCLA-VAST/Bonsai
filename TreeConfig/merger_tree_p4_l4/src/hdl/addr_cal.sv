// Address calculator for multipass
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
module addr_cal #(
  parameter integer NUM_READ_CHANNELS           = 1 , 
  parameter integer C_M_AXI_ADDR_WIDTH          = 64 ,
  parameter integer C_XFER_SIZE_WIDTH           = 64 ,
  parameter integer C_BURST_SIZE_BYTES          = 1024
)
(
  // System Signals
  input wire                                                    aclk                 ,
  // Engine signal
  input wire                                                    ap_start             ,
  output wire                                                   ap_done              ,  
  // AXI read control information
  input wire [8-1:0]                                            num_pass             , // number of total passes needed
  input wire [C_M_AXI_ADDR_WIDTH-1:0]                           in_addr_offset       , // 
  input wire [C_XFER_SIZE_WIDTH-1:0]                            in_xfer_size_in_bytes, // total input size in bytes
  input wire [C_M_AXI_ADDR_WIDTH-1:0]                           out_addr_offset      , // 
  input wire                                                    single_run_read_done , // asserted to indicate a single run of read is done
  input wire                                                    write_done           , // write done means one pass is done
  output wire                                                   read_start           , //
  output wire [NUM_READ_CHANNELS-1:0][C_M_AXI_ADDR_WIDTH-1:0]   read_addr            , // read address for each leaf node
  output wire [C_XFER_SIZE_WIDTH-1:0]                           read_size_in_bytes   , // how many bytes needs to be read per node for the current run
  output wire                                                   read_divide          , // asserted to indicate burst needs to be divided for multiple runs
  output wire [C_XFER_SIZE_WIDTH-1:0]                           read_run_count       , // indicate after how many 64-byte reads append 0s
  output wire                                                   write_start          , // 
  output wire [C_M_AXI_ADDR_WIDTH-1:0]                          write_addr             //                     
);

timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_NUM_READ_NODES                 = NUM_READ_CHANNELS;
localparam integer LP_PASS_INCREMENT                 = $clog2(LP_NUM_READ_NODES); // each pass increase bytes by 2^3 
localparam integer LP_LOG_BURST_SIZE_BYTE            = $clog2(C_BURST_SIZE_BYTES);
localparam integer LP_INIT_XFER_WIDTH                = C_XFER_SIZE_WIDTH - 7;
localparam integer LP_TRANSCATION_CNTR_WIDTH         = C_XFER_SIZE_WIDTH - LP_LOG_BURST_SIZE_BYTE;

///////////////////////////////////////////////////////////////////////////////
// Addr control information
///////////////////////////////////////////////////////////////////////////////
logic                                                          ap_start_delay = 0;
logic                                                          single_run_read_done_delay = 0; 
logic                                                          write_done_delay = 0;

logic [8-1:0]                                                  pass_count = 0;         // count how many passes have been done


logic [C_M_AXI_ADDR_WIDTH-1:0]                                 ctrl_addr_multi_run = 0;    // the starting addr for multi-runs read
logic [NUM_READ_CHANNELS-1:0][C_M_AXI_ADDR_WIDTH-1:0]          ctrl_addr_offset;        // read address for each node

logic [C_XFER_SIZE_WIDTH-1:0]                                  single_run_xfer_bytes = 0;  // for the current pass, how many bytes need to read per node, round to an axi burst
logic [C_XFER_SIZE_WIDTH-1:0]                                  single_run_xfer_bytes_sum = 0;   // single_run_xfer_bytes_sum = single_run_xfer_bytes * LP_NUM_READ_NODES
logic [C_XFER_SIZE_WIDTH-1:0]                                  total_run_xfer_bytes = 0;    // for the current pass, how many bytes in total have been read till the current run

logic [C_XFER_SIZE_WIDTH-1:0]                                  real_single_run_xfer_bytes_next = 0; // for the next pass, how many bytes actually read per node

logic                                                          need_divide = 0;
logic [C_XFER_SIZE_WIDTH-1:0]                                  axi_cnt_per_run = 0;

logic [C_M_AXI_ADDR_WIDTH-1:0]                                 ctrl_addr_write = 0; // write addr

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////
assign read_start = ap_start_delay || (write_done_delay && (pass_count != num_pass)) || (single_run_read_done_delay && total_run_xfer_bytes < in_xfer_size_in_bytes);
assign read_addr = ctrl_addr_offset;
assign read_size_in_bytes = single_run_xfer_bytes;

assign read_divide = need_divide;
assign read_run_count = axi_cnt_per_run;

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
        ctrl_addr_multi_run <= ctrl_addr_multi_run + single_run_xfer_bytes_sum;
    end
end

// calculate read address for each node
always_comb begin
    for (int i = 0; i < LP_NUM_READ_NODES; i++) begin
        ctrl_addr_offset[i] = ctrl_addr_multi_run + i * single_run_xfer_bytes;
    end
end

// calculate how many bytes actually needed to be read per each run for the next pass
always @(posedge aclk) begin
    if (ap_start) begin
        real_single_run_xfer_bytes_next <= ({{LP_INIT_XFER_WIDTH{1'b0}}, 7'h40} << LP_PASS_INCREMENT); // start from (16 elements/64 bytes << LP_PASS_INCREMENT)
    end
    else if(write_done) begin
        if (pass_count == (num_pass - 3)) begin // the next pass is the last pass: each node has only one run, run size is in_xfer_size_in_bytes/LP_NUM_READ_NODES
            real_single_run_xfer_bytes_next <= (in_xfer_size_in_bytes >> LP_PASS_INCREMENT);
        end
        else begin
            real_single_run_xfer_bytes_next <= (real_single_run_xfer_bytes_next << LP_PASS_INCREMENT);
        end
    end
end

// calculate how many bytes need to read per node for the current pass
// if less than an entire AXI burst, issue an entire AXI burst read
always @(posedge aclk) begin
    if (ap_start) begin
        single_run_xfer_bytes <= {{C_XFER_SIZE_WIDTH-1-LP_LOG_BURST_SIZE_BYTE{1'b0}}, 1'b1, {LP_LOG_BURST_SIZE_BYTE{1'b0}}}; // initially issue an entire AXI burst
        need_divide <= 1'b1;
        axi_cnt_per_run <= 1;
    end
    else if(write_done) begin
        if (real_single_run_xfer_bytes_next[LP_LOG_BURST_SIZE_BYTE+:LP_TRANSCATION_CNTR_WIDTH] > 0) begin // if single run transfer size is larger than an AXI burst read size
            need_divide <= 1'b0;
            axi_cnt_per_run <= axi_cnt_per_run;
            single_run_xfer_bytes <= real_single_run_xfer_bytes_next;
        end 
        else begin // if single run transfer size is less than an AXI burst read size, issue an AXI burst
            need_divide <= 1;
            axi_cnt_per_run <= (axi_cnt_per_run << LP_PASS_INCREMENT);
            single_run_xfer_bytes <= {{C_XFER_SIZE_WIDTH-1-LP_LOG_BURST_SIZE_BYTE{1'b0}}, 1'b1, {LP_LOG_BURST_SIZE_BYTE{1'b0}}};
        end
    end
end

// calculate how much address offset for all nodes per run
// if each node has less than an entire AXI burst, then address offset is LP_NUM_READ_NODES axi bursts
always @(posedge aclk) begin
    if (ap_start) begin
        single_run_xfer_bytes_sum <= ({{C_XFER_SIZE_WIDTH-1-LP_LOG_BURST_SIZE_BYTE{1'b0}}, 1'b1, {LP_LOG_BURST_SIZE_BYTE{1'b0}}} << LP_PASS_INCREMENT);
    end
    else if(write_done) begin
        if (real_single_run_xfer_bytes_next[LP_LOG_BURST_SIZE_BYTE+:LP_TRANSCATION_CNTR_WIDTH] > 0) begin 
            single_run_xfer_bytes_sum <= (real_single_run_xfer_bytes_next << LP_PASS_INCREMENT);
        end
        else begin
            single_run_xfer_bytes_sum <= ({{C_XFER_SIZE_WIDTH-1-LP_LOG_BURST_SIZE_BYTE{1'b0}}, 1'b1, {LP_LOG_BURST_SIZE_BYTE{1'b0}}} << LP_PASS_INCREMENT);
        end
    end
end

// calculate total_run_xfer_bytes
always @(posedge aclk) begin
  if (ap_start | write_done) begin
    total_run_xfer_bytes <= 0;
  end
  else if (single_run_read_done) begin
    total_run_xfer_bytes <= total_run_xfer_bytes + single_run_xfer_bytes_sum;
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