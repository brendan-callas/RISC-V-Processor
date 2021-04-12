module cache_arbiter
(
	input clk,
	input rst,

	//inputs from caches
	input data_mem_read,
	input inst_mem_read,
	input data_mem_write,
	input [31:0] data_mem_addr,
	input [31:0] inst_mem_addr,
	input [255:0] data_mem_wdata,
	input [3:0] inst_mbe,
	input [3:0] data_mbe,
	
	//outputs to caches
	output [255:0] data_mem_rdata,
	output [255:0] inst_mem_rdata,
	output data_mem_resp,
	output inst_mem_resp,
	
	//inputs from adaptor
	input [255:0] mem_rdata,
	input mem_resp,
	
	//outputs to adaptor
	output mem_read,
	output mem_write,
	output [255:0] mem_wdata,
	output [31:0] mem_address,
	output [3:0] mem_byte_enable
);

/* State Enumeration */
enum int unsigned {
	 idle,
	 inst_c,
	 data_c
} state, next_states;

/* State Control Signals */
always_comb begin : state_actions

	/* Defaults */
	mem_read = 1'b0;
	mem_write = 1'b0;
	data_mem_resp = 1'b0;
	inst_mem_resp = 1'b0;
	mem_address = inst_mem_addr;
	mem_wdata = data_mem_wdata;
	data_mem_rdata = mem_rdata; 
	inst_mem_rdata = mem_rdata;
	mem_byte_enable = inst_mbe;
	

	case(state)
	 idle: begin
		//do nothing
	 end
	 
	 inst_c: begin
		mem_read = inst_mem_read;
		mem_write = 1'b0;
		mem_address = inst_mem_addr;
		inst_mem_resp = mem_resp;
		mem_byte_enable = inst_mbe;
	 end
	 
	 data_c: begin
		mem_read = data_mem_read;
		mem_write = data_mem_write;
		mem_address = data_mem_addr;
		data_mem_resp = mem_resp;
		mem_byte_enable = data_mbe;
	 end
	 
	 default: begin
		//N/A
	 end

	endcase
end

/* Next State Logic */
always_comb begin : next_state_logic

	/* Default state transition */
	next_states = state;

	case(state)
    idle: begin
		if(inst_mem_read) begin
			next_states = inst_c;
		end else if(data_mem_read | data_mem_write) begin
			next_states = data_c;
		end else begin
			next_states = idle;
		end
	 end
	 
	 inst_c: begin
		if(~inst_mem_resp) begin
			next_states = inst_c;
		end else if(data_mem_read | data_mem_write) begin
			next_states = data_c;
		end else if(inst_mem_read) begin
			next_states = inst_c;
		end else begin
			next_states = idle;
		end
	 end
	 
	 data_c: begin
		if(~data_mem_resp) begin
			next_states = data_c;
		end else if(inst_mem_read) begin
			next_states = inst_c;
		end else if(data_mem_read | data_mem_write) begin
			next_states = data_c;
		end else begin
			next_states = idle;
		end
	 end
	 
	 default: begin
		next_states = idle;
	 end

	endcase
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
	if(rst) begin
		state <= idle;
	end else begin
		state <= next_states;
	end
end

endmodule : cache_arbiter