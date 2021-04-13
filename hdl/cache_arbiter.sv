module cache_arbiter
(
	input clk,
	input rst,

	//inputs from caches
	input logic data_mem_read,
	input logic inst_mem_read,
	input logic data_mem_write,
	input logic [31:0] data_mem_addr,
	input logic [31:0] inst_mem_addr,
	input logic [255:0] data_mem_wdata,
	
	//outputs to caches
	output logic [255:0] data_mem_rdata,
	output logic [255:0] inst_mem_rdata,
	output logic data_mem_resp,
	output logic inst_mem_resp,
	
	//inputs from adaptor
	input logic [255:0] mem_rdata,
	input logic mem_resp,
	
	//outputs to adaptor
	output logic mem_read,
	output logic mem_write,
	output logic [255:0] mem_wdata,
	output logic [31:0] mem_address
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
	

	case(state)
	 idle: begin
		//do nothing
	 end
	 
	 inst_c: begin
		mem_read = inst_mem_read;
		mem_write = 1'b0;
		mem_address = inst_mem_addr;
		inst_mem_resp = mem_resp;
	 end
	 
	 data_c: begin
		mem_read = data_mem_read;
		mem_write = data_mem_write;
		mem_address = data_mem_addr;
		data_mem_resp = mem_resp;
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
			if(inst_mem_read & ~inst_mem_resp) begin
				next_states = inst_c;
			end else if(data_mem_read | data_mem_write) begin
				next_states = data_c;
			end else begin
				next_states = idle;
			end
		 end
		 
		 data_c: begin
			if((data_mem_read | data_mem_write) & ~data_mem_resp) begin
				next_states = data_c;
			end else if(inst_mem_read) begin
				next_states = inst_c;
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
always_ff @(posedge clk) begin
	if(rst) begin
		state <= idle;
	end else begin
		state <= next_states;
	end
end

endmodule : cache_arbiter