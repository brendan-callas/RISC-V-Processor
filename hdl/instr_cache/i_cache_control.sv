/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module i_cache_control (

	input clk,
	input rst,
	
	// port to cpu
    input logic mem_read,
    // input logic mem_write,
	output logic mem_resp,

	//signals between datapath and control
	// output logic source_sel,
	output logic way_sel,
	// output logic tag_sel,
	output logic load_cache,
	// output logic read_lru,
	output logic load_lru,
	// output logic read_cache_data,
	// output logic load_dirty,
	// output logic dirty_sel,
	// input logic dirty_o,
	input logic lru_out,
	input logic hit1,

	//new signals between datapath and control
	output logic prefetch_sel,
	output logic load_prefetch_buffer,
	output logic load_busy,
	output logic busy_load_sel,
	output logic busy_index_sel,
	output logic busy_i,

	input logic instr_line_hit,
	input logic obl_line_hit,
	input logic obl_lru_out,
	
	//port to memory
	input logic resp_from_mem,
	// output logic write_to_mem,
	output logic read_from_mem
	
);


enum int unsigned {
    /* List of states */
	s_idle,
	s_load_instr_from_mem,
	s_load_prefetch_from_mem,
} state, next_state;

function void set_defaults();
	way_sel = hit1; // on a hit (idle), want to select the way which has the hit
	// tag_sel = 1'b1; //make default to mem addr tag
	read_from_mem = 1'b0;
	// write_to_mem = 1'b0;
	load_cache = 1'b0;
	load_lru = 1'b0;
	// read_lru = 1'b1; // might need to make this default to 1
	// source_sel = 1'b1;
	// read_cache_data = 1'b1; // always want to read cache data
	mem_resp = 1'b0;
	// load_dirty = 1'b0;
	// dirty_sel = lru_out; // dirty output is only important for checking if we need to write back when evicting.

	// new signals
	prefetch_sel = 1'b0;
	load_prefetch_buffer = 1'b0;
	load_busy = 1'b0;
	busy_load_sel = 1'b0;
	busy_index_sel = 1'b0;
	busy_i = 1'b0;
endfunction

function void respond_to_cpu();
	mem_resp = 1'b1;
	way_sel = hit1; // redundant since this is default; keeping it here anyway for now
	load_lru = 1'b1; // lru will load way_sel into the respective index
endfunction

function void change_busy_status(input logic is_busy_i)
	load_busy = 1'b1;
	if (is_busy_i) begin
		// mark 'busy'
		busy_i = 1'b1;
		busy_load_sel = obl_lru_out;
		busy_index_sel = 1'b1;
	end
	else begin
		// mark 'not busy'
		busy_i = 1'b0;
		busy_load_sel = lru_out;
		busy_index_sel = 1'b0;
	end
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
	
    /* Actions for each state */
	case(state)
		
		s_idle: begin
			if ( mem_read & instr_line_hit) begin
				// respond to cpu
				respond_to_cpu();

				if (~obl_line_hit) begin
					// load prefetch buffer
					load_prefetch_buffer = 1'b1;

					// mark line busy
					change_busy_status(1'b1);
				end
			end

		end
		
		s_load_instr_from_mem: begin
			// read from memory with address_to_mem = mem_address
			way_sel = lru_out;
			read_from_mem = 1'b1;

			if (resp_from_mem == 1'b1) begin
				load_cache = 1'b1;				
			end
		end
		
		s_load_prefetch_from_mem: begin
			// read from memory with address_to_mem = olb_address
			// prefetch_sel will automatically select the correct way that's lru for the prefetch line
			prefetch_sel = 1'b1;
			way_sel = lru_out; // we need to make sure that it overwrites the the data in the way that's lru
			read_from_mem = 1'b1;

			if (resp_from_mem == 1'b1) begin
				load_cache = 1'b1;

				// unmark the previously busy line
				change_busy_status(1'b0);
			end
			else if (mem_read & instr_line_hit) begin
				// respond to cpu
				respond_to_cpu();
			end
		end
	endcase
	
end



always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	 
	 // default
	 next_state = state;
	 
	 if(rst == 1'b1) begin
		next_state = s_idle;
	 end
	 else begin
		 case(state)
			s_idle: begin
				if (mem_read & ~instr_line_hit) begin
					next_state = s_load_instr_from_mem;
				end
				else if (mem_read & instr_line_hit & ~obl_line_hit) begin
					next_state = s_load_prefetch_from_mem;
				end
			end
			
			s_load_instr_from_mem: begin
				if (resp_from_mem == 1'b1) begin
					next_state = s_idle;
				end
			end
			
			s_load_prefetch_from_mem: begin
				if (resp_from_mem == 1'b1) begin
					next_state = s_idle;
				end
			end
		endcase
	end
end



always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_state;
end


endmodule : cache_control

