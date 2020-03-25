// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1ps / 1ps

module axi_write_controller #(
	parameter integer C_AXIS_TDATA_WIDTH = 512,
	parameter integer C_SORTER_BIT_WIDTH = 32
)
(
	input wire                                m_axis_aclk,
  	input wire                                m_axis_areset,

  	output wire                               m_axis_tvalid,
    input  wire                               m_axis_tready,
    output wire [C_AXIS_TDATA_WIDTH-1:0]      m_axis_tdata,
    output wire [C_AXIS_TDATA_WIDTH/8-1:0]    m_axis_tkeep,
    output wire                               m_axis_tlast,

  	input wire 								  read_fifo_out,
  	input wire [C_SORTER_BIT_WIDTH-1:0]	      out_fifo_item,
  	output wire 							  fifo_out_i_deq
);

// signals for axi stream write
reg [C_AXIS_TDATA_WIDTH-1:0]      data_out = 0;
wire                              data_valid;
reg [2:0]                         write_counter = 0;
reg                               fifo_out_i_deq_reg = 0;

assign fifo_out_i_deq = fifo_out_i_deq_reg;

// fsm for writing control
localparam S0 = 3'd0;
localparam S1 = 3'd1;
localparam S2 = 3'd2;
localparam S3 = 3'd3;
localparam S4 = 3'd4;

reg     [2:0]   state = S0;
reg     [2:0]   next_state;

always @(posedge m_axis_aclk)
begin
    if(m_axis_areset)
    begin
        state <= S0;
    end
    else
    begin
        state <= next_state;
    end
end

always @(*)
begin
    write_counter <= 3'd0;
    fifo_out_i_deq_reg <= 1'b0;
    case(state)
    S0:
    if(read_fifo_out && (out_fifo_item != 0))
    begin
        next_state <= S1;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else if(read_fifo_out && (out_fifo_item == 0))
    begin
        next_state <= S0;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else
    begin
        next_state <= S0;
        fifo_out_i_deq_reg <= 1'b0;
    end

    S1: 
    if(read_fifo_out && (out_fifo_item != 0))
    begin
        next_state <= S2;
        write_counter <= 3'd1;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else if(read_fifo_out && (out_fifo_item == 0))
    begin
        next_state <= S1;
        write_counter <= 3'd1;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else
    begin
        next_state <= S1;
        write_counter <= 3'd1;
        fifo_out_i_deq_reg <= 1'b0;
    end

    S2: 
    if(read_fifo_out && (out_fifo_item != 0))
    begin
        next_state <= S3;
        write_counter <= 3'd2;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else if(read_fifo_out && (out_fifo_item == 0))
    begin
        next_state <= S2;
        write_counter <= 3'd2;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else
    begin
        next_state <= S2;
        write_counter <= 3'd2;
        fifo_out_i_deq_reg <= 1'b0;
    end

    S3: 
    if(read_fifo_out && (out_fifo_item != 0))
    begin
        next_state <= S4;
        write_counter <= 3'd3;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else if(read_fifo_out && (out_fifo_item == 0))
    begin
        next_state <= S3;
        write_counter <= 3'd3;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else
    begin
        next_state <= S3;
        write_counter <= 3'd3;
        fifo_out_i_deq_reg <= 1'b0;
    end

    S4: 
    if(~m_axis_tready)
    begin
        next_state <= S4;
        write_counter <= 3'd0;
        fifo_out_i_deq_reg <= 1'b0;
    end
    else if(read_fifo_out && (out_fifo_item != 0))
    begin
        next_state <= S1;
        write_counter <= 3'd0;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else if(read_fifo_out && (out_fifo_item == 0))
    begin
        next_state <= S0;
        write_counter <= 3'd0;
        fifo_out_i_deq_reg <= 1'b1;
    end
    else
    begin
        next_state <= S0;
        write_counter <= 3'd0;
        fifo_out_i_deq_reg <= 1'b0;
    end

    default:
    begin
        next_state <= S0;
        write_counter <= 3'd0;
        fifo_out_i_deq_reg <= 1'b0;
    end
    endcase
end


always @(posedge m_axis_aclk)
begin
    if(fifo_out_i_deq && (out_fifo_item != 0))
    begin
        case (write_counter)
            3'd0: 
            begin
                data_out <= {384'd0, out_fifo_item[C_SORTER_BIT_WIDTH-1:0]};
            end
            3'd1:
            begin
                data_out <= {256'd0, out_fifo_item[C_SORTER_BIT_WIDTH-1:0], data_out[1*C_SORTER_BIT_WIDTH-1:0]};
            end
            3'd2:
            begin
                data_out <= {128'd0, out_fifo_item[C_SORTER_BIT_WIDTH-1:0], data_out[2*C_SORTER_BIT_WIDTH-1:0]};
            end
            3'd3:
            begin
                data_out <= {out_fifo_item[C_SORTER_BIT_WIDTH-1:0], data_out[3*C_SORTER_BIT_WIDTH-1:0]};
            end
            default:
            begin
                data_out <= data_out;
            end
        endcase
    end
end


assign data_valid = (state == S4);
assign m_axis_tdata = data_out;
assign m_axis_tvalid = data_valid;


endmodule

`default_nettype wire