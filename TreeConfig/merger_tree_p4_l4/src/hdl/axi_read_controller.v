// 2019/07/10
// Added one feature:
// when s_axis_tlast is asserted, output one more extra 0;
//////////////////////////////////////////////////////////////////////////////// 

// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1ps / 1ps

module axi_read_controller #(
	parameter integer C_AXIS_TDATA_WIDTH = 512,
	parameter integer C_SORTER_BIT_WIDTH = 32
)
(
	input wire                                s_axis_aclk,
  	input wire                                s_axis_areset,

  	input wire                                s_axis_tvalid,
  	output wire                               s_axis_tready,
  	input wire  [C_AXIS_TDATA_WIDTH-1:0]      s_axis_tdata,
  	input wire  [C_AXIS_TDATA_WIDTH/8-1:0]    s_axis_tkeep,
  	input wire                                s_axis_tlast,
  	//input wire                                axi_fifo_empty,

  	input wire 								  fifo_full,
  	output wire [C_SORTER_BIT_WIDTH-1:0]	  in_fifo_data,
  	output wire 							  in_fifo_en
);


reg [C_AXIS_TDATA_WIDTH-1:0]      	s_axis_tdata_reg = 0;
reg 								s_axis_tlast_reg = 0;
reg 								write_fifo_en_reg = 0;
reg 								ready_reg = 0;

// for debug
// reg [31:0]						local_cnt = 0;
// for debug end

assign in_fifo_data = s_axis_tdata_reg[C_SORTER_BIT_WIDTH-1:0];
assign s_axis_tready = ready_reg;
assign in_fifo_en = write_fifo_en_reg;

// fsm for writing control
localparam S0 = 5'd0;
localparam S1 = 5'd1;
localparam S2 = 5'd2;
localparam S3 = 5'd3;
localparam S4 = 5'd4;
localparam S5 = 5'd5;
localparam S6 = 5'd6;
localparam S7 = 5'd7;
localparam S8 = 5'd8;
localparam S9 = 5'd9;
localparam S10 = 5'd10;
localparam S11 = 5'd11;
localparam S12 = 5'd12;
localparam S13 = 5'd13;
localparam S14 = 5'd14;
localparam S15 = 5'd15;
localparam S16 = 5'd16;
localparam S17 = 5'd17;


reg 	[4:0]	state = S0;
reg 	[4:0]	next_state;


always @(posedge s_axis_aclk)
begin
    if(s_axis_areset)
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
	ready_reg <= 0;
	write_fifo_en_reg <= 0;
	case(state)
	S0:
	if(s_axis_tvalid) begin
		next_state <= S1;
		ready_reg <= 1;
	end
	else begin
		next_state <= S0;
	end

	S1:
	if(~fifo_full) begin
		next_state <= S2;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S1;
	end

	S2:
	if(~fifo_full) begin
		next_state <= S3;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S2;
	end

	S3:
	if(~fifo_full) begin
		next_state <= S4;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S3;
	end

	S4:
	if(~fifo_full) begin
		next_state <= S5;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S4;
	end

	S5:
	if(~fifo_full) begin
		next_state <= S6;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S5;
	end

	S6:
	if(~fifo_full) begin
		next_state <= S7;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S6;
	end

	S7:
	if(~fifo_full) begin
		next_state <= S8;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S7;
	end

	S8:
	if(~fifo_full) begin
		next_state <= S9;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S8;
	end

	S9:
	if(~fifo_full) begin
		next_state <= S10;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S9;
	end

	S10:
	if(~fifo_full) begin
		next_state <= S11;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S10;
	end

	S11:
	if(~fifo_full) begin
		next_state <= S12;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S11;
	end


	S12:
	if(~fifo_full) begin
		next_state <= S13;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S12;
	end

	S13:
	if(~fifo_full) begin
		next_state <= S14;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S13;
	end

	S14:
	if(~fifo_full) begin
		next_state <= S15;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S14;
	end

	S15:
	if(~fifo_full) begin
		next_state <= S16;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S15;
	end

	S16:
	if(~fifo_full) begin
		if(s_axis_tlast_reg) begin
			next_state <= S17;
			ready_reg <= 0;
			write_fifo_en_reg <= 1;
		end
		else if(s_axis_tvalid) begin
			next_state <= S1;
			ready_reg <= 1;
			write_fifo_en_reg <= 1;
		end
		else begin
			next_state <= S0;
			ready_reg <= 0;
			write_fifo_en_reg <= 1;
		end
	end
	else begin
		next_state <= S16;
	end
	/*
	S16: 
	if(~fifo_full && (~s_axis_tlast_reg)) begin
		next_state <= S1;
		ready_reg <= 1;
		write_fifo_en_reg <= 1;
	end
	else if(~fifo_full && s_axis_tlast_reg) begin
		next_state <= S17;
		ready_reg <= 0;
		write_fifo_en_reg <= 1;
	end
	else begin
		next_state <= S16;
	end
	*/

	S17: // this state writes one more 0s
	begin
		next_state <= S0;
		ready_reg <= 0;
		write_fifo_en_reg <= 1;
	end

	default: begin
		next_state <= S0;
	end
    endcase
end


always @(posedge s_axis_aclk) begin
	if (ready_reg) begin
		s_axis_tdata_reg <= s_axis_tdata;
	end
	else if (write_fifo_en_reg) begin
		s_axis_tdata_reg <= (s_axis_tdata_reg >> C_SORTER_BIT_WIDTH);
	end
	else begin
		s_axis_tdata_reg <= s_axis_tdata_reg;
	end
end

always @(posedge s_axis_aclk) begin
	if (ready_reg) begin
		s_axis_tlast_reg <= s_axis_tlast;
	end
end

/*
// for debug
always @(posedge s_axis_aclk) begin
	if (s_axis_tvalid & s_axis_tready) begin
		local_cnt <= local_cnt + 1;
	end
end
// for debug end
*/

endmodule
