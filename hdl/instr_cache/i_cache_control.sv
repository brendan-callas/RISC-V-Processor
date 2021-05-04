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
	output logic lru_index_sel,

	input logic instr_line_hit,
	input logic obl_line_hit,
	input logic obl_lru_out,
	
	//port to memory
	input logic resp_from_mem,
	// output logic write_to_mem,
	output logic read_from_mem,
	
	// inputs for performance counters
    input logic data_request,
    input logic arbiter_instr_state,
	input logic prefetched,
	input logic data_resp

);

// performance counters
/*
- num cycles spent prefetching when data request needs to be fulfilled
- num instruction hits in the prefetch state
- num instruction hits in idle state
- num instruction misses
*/

/*
UPDATED PERFORMANCE COUNTERS:
- num hits in idle state
- num hits on prefetched cache lines
- num misses
- num cycles spent on misses (cycles spent in load_instr state)
- num cycles spent prefetching when there is a data request
- num cycles spent in load_instr when there is a data request
*/


int num_cycles_instr_hit; //
int num_cycles_instr_hit_prefetched; //
int num_instr_misses; //
int num_cycles_load_instr; //
int num_cycles_load_instr_data_req; //
int num_cycles_load_prefetch_data_req;
int num_cycles_instr_hit_data_req; // 
int num_cycles_instr_hit_prefetched_data_req; //
int num_cycles_wasted_prefetching; //

int num_cycles_instr_hit_i;
int num_cycles_instr_hit_prefetched_i;
int num_instr_misses_i;
int num_cycles_load_instr_i;
int num_cycles_load_instr_data_req_i;
int num_cycles_load_prefetch_data_req_i;
int num_cycles_instr_hit_data_req_i;
int num_cycles_instr_hit_prefetched_data_req_i;
int num_cycles_wasted_prefetching_i;

enum int unsigned {
    /* List of states */
	s_idle,
	s_load_instr_from_mem,
	s_load_prefetch_from_mem
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
	lru_index_sel = 1'b0;
endfunction

function void respond_to_cpu();
	mem_resp = 1'b1;
	way_sel = hit1; // redundant since this is default; keeping it here anyway for now
	load_lru = 1'b1; // lru will load way_sel into the respective index
endfunction

function void change_busy_status(input logic is_busy_i);

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
			read_from_mem = 1'b1;

			if (resp_from_mem == 1'b1) begin
				load_cache = 1'b1;
				lru_index_sel = 1'b1; // select the lru index from rpefetch line
				way_sel = lru_out; // we need to make sure that it overwrites the the data in the way that's lru

				// unmark the previously busy line
				change_busy_status(1'b0);
			end
			else if (mem_read & instr_line_hit) begin
				// respond to cpu
				lru_index_sel = 1'b0;
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

always_comb 
begin : calculate_performance_counters

	num_cycles_instr_hit_i = num_cycles_instr_hit;
	num_cycles_instr_hit_prefetched_i = num_cycles_instr_hit_prefetched;
	num_instr_misses_i = num_instr_misses;
	num_cycles_load_instr_i = num_cycles_load_instr;
	num_cycles_load_instr_data_req_i = num_cycles_load_instr_data_req;
	num_cycles_load_prefetch_data_req_i = num_cycles_load_prefetch_data_req;
	num_cycles_instr_hit_data_req_i = num_cycles_instr_hit_data_req;
	num_cycles_instr_hit_prefetched_data_req_i = num_cycles_instr_hit_prefetched_data_req;

	num_cycles_wasted_prefetching_i = num_cycles_wasted_prefetching;
	// num_instr_hits_prefetch_i = num_instr_hits_prefetch;

	if (instr_line_hit) begin
		num_cycles_instr_hit_i = num_cycles_instr_hit+1;
		if (prefetched) begin
			num_cycles_instr_hit_prefetched_i = num_cycles_instr_hit_prefetched+1;
		end
	end

	if (instr_line_hit & (data_request & ~data_resp)) begin
		num_cycles_instr_hit_data_req_i = num_cycles_instr_hit_data_req+1;
		if (prefetched & (data_request & ~data_resp)) begin
			num_cycles_instr_hit_prefetched_data_req_i = num_cycles_instr_hit_prefetched_data_req+1;
		end
	end


	case (state)
		s_idle: begin
			if (~instr_line_hit) begin
				num_instr_misses_i = num_instr_misses+1;
			end
		end

		s_load_instr_from_mem: begin
			num_cycles_load_instr_i = num_cycles_load_instr+1;
			if (data_request & ~arbiter_instr_state & ~data_resp) begin
				num_cycles_load_instr_data_req_i = num_cycles_load_instr_data_req+1;
			end
		end

		s_load_prefetch_from_mem: begin
			if (data_request & ~data_resp) begin
				num_cycles_load_prefetch_data_req_i = num_cycles_load_prefetch_data_req+1;
			end
			// add if condition for num_cycles_wasted_prefetching
			if (data_request & arbiter_instr_state) begin
				num_cycles_wasted_prefetching_i = num_cycles_wasted_prefetching+1;
			end
		end
	endcase

end

/* update performance counters*/

always_ff @(posedge clk)
begin : update_performance_counters

	if (rst) begin
		num_cycles_instr_hit <= '0;
		num_cycles_instr_hit_prefetched <= '0;
		num_instr_misses <= '0;
		num_cycles_load_instr <= '0;
		num_cycles_load_instr_data_req <= '0;
		num_cycles_load_prefetch_data_req <= '0;
		num_cycles_instr_hit_data_req <= '0;
		num_cycles_instr_hit_prefetched_data_req <= '0;

		num_cycles_wasted_prefetching <= '0;

		// num_instr_hits_prefetch <= '0;

	end
	else begin
		num_cycles_instr_hit <= num_cycles_instr_hit_i;
		num_cycles_instr_hit_prefetched <= num_cycles_instr_hit_prefetched_i;
		num_instr_misses <= num_instr_misses_i;
		num_cycles_load_instr <= num_cycles_load_instr_i;
		num_cycles_load_instr_data_req <= num_cycles_load_instr_data_req_i;
		num_cycles_load_prefetch_data_req <= num_cycles_load_prefetch_data_req_i;
		num_cycles_instr_hit_data_req <= num_cycles_instr_hit_data_req_i;
		num_cycles_instr_hit_prefetched_data_req <= num_cycles_instr_hit_prefetched_data_req_i;

		num_cycles_wasted_prefetching <= num_cycles_wasted_prefetching_i;

		// num_instr_hits_prefetch <= num_instr_hits_prefetch_i;
		// num_instr_misses <= num_instr_misses_i;
	end

end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_state;
end


endmodule : i_cache_control

