// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////

// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1ns/1ps
module merger_tree_p8_l8_i16_control_s_axi #(
  parameter integer C_S_AXI_ADDR_WIDTH = 6,
  parameter integer C_S_AXI_DATA_WIDTH = 32
)
(
  // AXI4-Lite slave signals
  input  wire                            aclk                  ,
  input  wire                            areset                ,
  input  wire                            aclk_en               ,

  input  wire                            awvalid               ,
  output wire                            awready               ,
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]   awaddr                ,
  input  wire                            wvalid                ,
  output wire                            wready                ,
  input  wire [C_S_AXI_DATA_WIDTH-1:0]   wdata                 ,
  input  wire [C_S_AXI_DATA_WIDTH/8-1:0] wstrb                 ,
  input  wire                            arvalid               ,
  output wire                            arready               ,
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]   araddr                ,
  output wire                            rvalid                ,
  input  wire                            rready                ,
  output wire [C_S_AXI_DATA_WIDTH-1:0]   rdata                 ,
  output wire [2-1:0]                    rresp                 ,
  output wire                            bvalid                ,
  input  wire                            bready                ,
  output wire [2-1:0]                    bresp                 ,
  output wire                            interrupt             ,
  
  // User control signals
  output wire                            ap_start              ,
  input  wire                            ap_idle               ,
  input  wire                            ap_done               ,
  input  wire                            ap_ready              ,
  // User defined arguments
  output wire [64-1:0]             size                  ,
  output wire [8-1:0]              num_pass              ,
  output wire [64-1:0]             single_trans_bytes    ,
  output wire [32-1:0]             log_single_trans_bytes,
  output wire [64-1:0]             in_ptr                ,
  output wire [64-1:0]             out_ptr               
);

//------------------------Address Info-------------------
// 0x000 : Control signals
//         bit 0  - ap_start (Read/Write/COH)
//         bit 1  - ap_done (Read/COR)
//         bit 2  - ap_idle (Read)
//         bit 3  - ap_ready (Read)
//         bit 7  - auto_restart (Read/Write)
//         others - reserved
// 0x004 : Global Interrupt Enable Register
//         bit 0  - Global Interrupt Enable (Read/Write)
//         others - reserved
// 0x008 : IP Interrupt Enable Register (Read/Write)
//         bit 0  - Channel 0 (ap_done)
//         bit 1  - Channel 1 (ap_ready)
//         others - reserved
// 0x00c : IP Interrupt Status Register (Read/TOW)
//         bit 0  - Channel 0 (ap_done)
//         bit 1  - Channel 1 (ap_ready)
//         others - reserved
// 0x010 : Data signal of size
//         bit 31~0 - size[31:0] (Read/Write)
// 0x014 : Data signal of size
//         bit 31~0 - size[63:32] (Read/Write)
// 0x018 : Data signal of num_pass
//         bit 07~0 - num_pass[7:0] (Read/Write)
// 0x01c : reserved
// 0x020 : Data signal of in_ptr
//         bit 31~0 - in_ptr[31:0] (Read/Write)
// 0x024 : Data signal of in_ptr
//         bit 31~0 - in_ptr[63:32] (Read/Write)
// 0x028 : Data signal of out_ptr
//         bit 31~0 - out_ptr[31:0] (Read/Write)
// 0x02c : Data signal of out_ptr
//         bit 31~0 - out_ptr[63:32] (Read/Write)
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_AP_CTRL                = 6'h00;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_GIE                    = 6'h04;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_IER                    = 6'h08;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_ISR                    = 6'h0c;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_SIZE_0                 = 6'h10;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_SIZE_1                 = 6'h14;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_NUM_PASS_0             = 6'h18;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_in_ptr_0               = 6'h20;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_in_ptr_1               = 6'h24;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_out_ptr_0              = 6'h28;
localparam [C_S_AXI_ADDR_WIDTH-1:0]       LP_ADDR_out_ptr_1              = 6'h2c;
localparam integer                  LP_SM_WIDTH                    = 2;
localparam [LP_SM_WIDTH-1:0]        SM_WRIDLE                      = 2'd0;
localparam [LP_SM_WIDTH-1:0]        SM_WRDATA                      = 2'd1;
localparam [LP_SM_WIDTH-1:0]        SM_WRRESP                      = 2'd2;
localparam [LP_SM_WIDTH-1:0]        SM_RDIDLE                      = 2'd0;
localparam [LP_SM_WIDTH-1:0]        SM_RDDATA                      = 2'd1;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
reg  [LP_SM_WIDTH-1:0]              wstate                         = SM_WRIDLE;
reg  [LP_SM_WIDTH-1:0]              wnext                         ;
reg  [C_S_AXI_ADDR_WIDTH-1:0]       waddr                         ;
wire [C_S_AXI_DATA_WIDTH-1:0]       wmask                         ;
wire                                aw_hs                         ;
wire                                w_hs                          ;
reg  [LP_SM_WIDTH-1:0]              rstate                         = SM_RDIDLE;
reg  [LP_SM_WIDTH-1:0]              rnext                         ;
reg  [C_S_AXI_DATA_WIDTH-1:0]       rdata_r                       ;
wire                                ar_hs                         ;
wire [C_S_AXI_ADDR_WIDTH-1:0]       raddr                         ;
// internal registers
wire                                int_ap_idle                   ;
wire                                int_ap_ready                  ;
reg                                 int_ap_done                    = 1'b0;
reg                                 int_ap_start                   = 1'b0;
reg                                 int_auto_restart               = 1'b0;
reg                                 int_gie                        = 1'b0;
reg [1:0]                           int_ier                        = 2'b0;
reg [1:0]                           int_isr                        = 2'b0;

reg  [64-1:0]                       int_size                       = 64'd0;
reg  [8-1:0]                        int_num_pass                   = 8'd0;
reg  [64-1:0]                       int_in_ptr                     = 64'd0;
reg  [64-1:0]                       int_out_ptr                    = 64'd0;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

//------------------------AXI write fsm------------------
assign awready = (~areset) & (wstate == SM_WRIDLE);
assign wready  = (wstate == SM_WRDATA);
assign bresp   = 2'b00;  // OKAY
assign bvalid  = (wstate == SM_WRRESP);
assign wmask   = { {8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}} };
assign aw_hs   = awvalid & awready;
assign w_hs    = wvalid & wready;

// wstate
always @(posedge aclk) begin
  if (areset)
    wstate <= SM_WRIDLE;
  else if (aclk_en)
    wstate <= wnext;
end

// wnext
always @(*) begin
  case (wstate)
    SM_WRIDLE:
      if (awvalid)
        wnext = SM_WRDATA;
      else
        wnext = SM_WRIDLE;
    SM_WRDATA:
      if (wvalid)
        wnext = SM_WRRESP;
      else
        wnext = SM_WRDATA;
    SM_WRRESP:
      if (bready)
        wnext = SM_WRIDLE;
      else
        wnext = SM_WRRESP;
    default:
      wnext = SM_WRIDLE;
  endcase
end

// waddr
always @(posedge aclk) begin
  if (aclk_en) begin
    if (aw_hs)
      waddr <= awaddr;
  end
end

//------------------------AXI read fsm-------------------
assign arready = (~areset) & (rstate == SM_RDIDLE);
assign rdata   = rdata_r;
assign rresp   = 2'b00;  // OKAY
assign rvalid  = (rstate == SM_RDDATA);
assign ar_hs   = arvalid & arready;
assign raddr   = araddr;

// rstate
always @(posedge aclk) begin
  if (areset)
    rstate <= SM_RDIDLE;
  else if (aclk_en)
    rstate <= rnext;
end

// rnext
always @(*) begin
  case (rstate)
    SM_RDIDLE:
      if (arvalid)
        rnext = SM_RDDATA;
      else
        rnext = SM_RDIDLE;
    SM_RDDATA:
      if (rready & rvalid)
        rnext = SM_RDIDLE;
      else
        rnext = SM_RDDATA;
    default:
      rnext = SM_RDIDLE;
  endcase
end

// rdata_r
always @(posedge aclk) begin
  if (aclk_en) begin
    if (ar_hs) begin
      rdata_r <= {C_S_AXI_DATA_WIDTH{1'b0}};
      case (raddr)
        LP_ADDR_AP_CTRL: begin
          rdata_r[0] <= int_ap_start;
          rdata_r[1] <= int_ap_done;
          rdata_r[2] <= int_ap_idle;
          rdata_r[3] <= int_ap_ready;
          rdata_r[7] <= int_auto_restart;
        end
        LP_ADDR_GIE: begin
          rdata_r <= int_gie;
        end
        LP_ADDR_IER: begin
          rdata_r <= int_ier;
        end
        LP_ADDR_ISR: begin
          rdata_r <= int_isr;
        end
        LP_ADDR_SIZE_0: begin
          rdata_r <= int_size[0+:32];
        end
        LP_ADDR_SIZE_1: begin
          rdata_r <= int_size[32+:32];
        end
        LP_ADDR_NUM_PASS_0: begin
          rdata_r <= {24'b0, int_num_pass[0+:8]};
        end
        LP_ADDR_in_ptr_0: begin
          rdata_r <= int_in_ptr[0+:32];
        end
        LP_ADDR_in_ptr_1: begin
          rdata_r <= int_in_ptr[32+:32];
        end
        LP_ADDR_out_ptr_0: begin
          rdata_r <= int_out_ptr[0+:32];
        end
        LP_ADDR_out_ptr_1: begin
          rdata_r <= int_out_ptr[32+:32];
        end

        default: begin
          rdata_r <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end
      endcase
    end
  end
end

//------------------------Register logic-----------------
assign interrupt    = int_gie & (|int_isr);
assign ap_start     = int_ap_start;
assign int_ap_idle  = ap_idle;
assign int_ap_ready = ap_ready;
assign size = int_size;
assign num_pass = int_num_pass;
assign in_ptr = int_in_ptr;
assign out_ptr = int_out_ptr;

// int_ap_start
always @(posedge aclk) begin
  if (areset)
    int_ap_start <= 1'b0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_AP_CTRL && wstrb[0] && wdata[0])
      int_ap_start <= 1'b1;
    else if (int_ap_ready)
      int_ap_start <= int_auto_restart; // clear on handshake/auto restart
  end
end

// int_ap_done
always @(posedge aclk) begin
  if (areset)
    int_ap_done <= 1'b0;
  else if (aclk_en) begin
    if (ap_done)
      int_ap_done <= 1'b1;
    else if (ar_hs && raddr == LP_ADDR_AP_CTRL)
      int_ap_done <= 1'b0; // clear on read
  end
end

// int_auto_restart
always @(posedge aclk) begin
    if (areset)
        int_auto_restart <= 1'b0;
    else if (aclk_en) begin
        if (w_hs && waddr == LP_ADDR_AP_CTRL && wstrb[0])
            int_auto_restart <=  wdata[7];
    end
end

// int_gie
always @(posedge aclk) begin
  if (areset)
    int_gie     <= 1'b0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_GIE && wstrb[0])
      int_gie <= wdata[0];
  end
end

// int_ier
always @(posedge aclk) begin
  if (areset)
    int_ier     <= 2'b0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_IER && wstrb[0])
      int_ier <= wdata[1:0];
  end
end

// int_isr[0]
always @(posedge aclk) begin
  if (areset)
    int_isr[0]     <= 1'b0;
  else if (aclk_en) begin
    if (int_ier[0] & ap_done)
      int_isr[0] <= 1'b1;
    else if (w_hs && waddr == LP_ADDR_ISR && wstrb[0])
      int_isr[0] <= int_isr[0] ^ wdata[0]; // toggle on write
  end
end

// int_isr[1]
always @(posedge aclk) begin
  if (areset)
    int_isr[1]     <= 1'b0;
  else if (aclk_en) begin
    if (int_ier[1] & ap_ready)
      int_isr[1] <= 1'b1;
    else if (w_hs && waddr == LP_ADDR_ISR && wstrb[0])
      int_isr[1] <= int_isr[1] ^ wdata[1]; // toggle on write
  end
end


// int_size[32-1:0]
always @(posedge aclk) begin
  if (areset)
    int_size[0+:32] <= 32'd0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_SIZE_0)
      int_size[0+:32] <= (wdata[0+:32] & wmask[0+:32]) | (int_size[0+:32] & ~wmask[0+:32]);
  end
end

// int_size[32-1:0]
always @(posedge aclk) begin
  if (areset)
    int_size[32+:32] <= 32'd0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_SIZE_1)
      int_size[32+:32] <= (wdata[0+:32] & wmask[0+:32]) | (int_size[32+:32] & ~wmask[0+:32]);
  end
end

// int_num_pass[8-1:0]
always @(posedge aclk) begin
  if (areset)
    int_num_pass[0+:8] <= 8'd0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_NUM_PASS_0)
      int_num_pass[0+:8] <= (wdata[0+:8] & wmask[0+:8]) | (int_num_pass[0+:8] & ~wmask[0+:8]);
  end
end

// int_in_ptr[32-1:0]
always @(posedge aclk) begin
  if (areset)
    int_in_ptr[0+:32] <= 32'd0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_in_ptr_0)
      int_in_ptr[0+:32] <= (wdata[0+:32] & wmask[0+:32]) | (int_in_ptr[0+:32] & ~wmask[0+:32]);
  end
end

// int_in_ptr[32-1:0]
always @(posedge aclk) begin
  if (areset)
    int_in_ptr[32+:32] <= 32'd0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_in_ptr_1)
      int_in_ptr[32+:32] <= (wdata[0+:32] & wmask[0+:32]) | (int_in_ptr[32+:32] & ~wmask[0+:32]);
  end
end

// int_out_ptr[32-1:0]
always @(posedge aclk) begin
  if (areset)
    int_out_ptr[0+:32] <= 32'd0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_out_ptr_0)
      int_out_ptr[0+:32] <= (wdata[0+:32] & wmask[0+:32]) | (int_out_ptr[0+:32] & ~wmask[0+:32]);
  end
end

// int_out_ptr[32-1:0]
always @(posedge aclk) begin
  if (areset)
    int_out_ptr[32+:32] <= 32'd0;
  else if (aclk_en) begin
    if (w_hs && waddr == LP_ADDR_out_ptr_1)
      int_out_ptr[32+:32] <= (wdata[0+:32] & wmask[0+:32]) | (int_out_ptr[32+:32] & ~wmask[0+:32]);
  end
end


endmodule

`default_nettype wire