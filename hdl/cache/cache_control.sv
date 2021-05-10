/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (

	input clk,
	input rst,
	
	// port to cpu
    input logic mem_read,
    input logic mem_write,
	output logic mem_resp,

	//signals between datapath and control
	output logic source_sel,
	output logic way_sel,
	output logic tag_sel,
	output logic load_cache,
	output logic read_lru,
	output logic load_lru,
	output logic read_cache_data,
	output logic load_dirty,
	output logic dirty_sel,
	input logic cache_hit,
	input logic dirty_o,
	input logic lru_out,
	input logic hit1,
	
	//port to memory
	input logic resp_from_mem,
	output logic read_from_mem,
	output logic write_to_mem,

	// performance counters
	input logic stall_ex_mem,
	input logic arbiter_data_state,
	input logic instr_resp
);


// performance counters
int num_instr_hit;
int num_instr_misses;
int num_cycles_miss;

int num_instr_hit_i;
int num_instr_misses_i;
int num_cycles_miss_i;


enum int unsigned {
    /* List of states */
	s_idle,
	s_write_back_prev,
	s_write_back,
	s_load_data_from_mem,
	s_load_data_into_cache,
	s_respond_to_cpu
	
} state, next_state;

function void set_defaults();
	
	way_sel = hit1; // on a hit (idle), want to select the way which has the hit
	tag_sel = 1'b1; //make default to mem addr tag
	read_from_mem = 1'b0;
	write_to_mem = 1'b0;
	load_cache = 1'b0;
	load_lru = 1'b0;
	read_lru = 1'b1; // might need to make this default to 1
	source_sel = 1'b0;
	read_cache_data = 1'b1; // always want to read cache data
	mem_resp = 1'b0;
	load_dirty = 1'b0;
	dirty_sel = lru_out; // dirty output is only important for checking if we need to write back when evicting.
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
	
    /* Actions for each state */
	case(state)
		
		s_idle: begin
			if( (mem_read | mem_write) & cache_hit) begin
				mem_resp = 1'b1;
				way_sel = hit1; // redundant since this is default; keeping it here anyway for now
				load_lru = 1'b1; // lru will load way_sel into the respective index
				// not sure if mem_write signal will persist here, so additional logic/signals may be needed
				load_cache = mem_write; // want to load cache if we are writing;
				if(mem_write) load_dirty = 1'b1;
			end
		end
		
		s_write_back_prev: begin
			way_sel = lru_out;
		end
		
		s_write_back: begin
			write_to_mem = 1'b1;
			way_sel = lru_out; //should this be changed since data from cacheline is delayed a cycle? (set this in prev state)
			tag_sel = 1'b0; //choose mem address from tag (concat with set)
		end
		
		s_load_data_from_mem: begin
			read_from_mem = 1'b1;
			way_sel = lru_out;
			tag_sel = 1'b1; //select mem addr tag
			
			if(resp_from_mem == 1'b1) begin
				load_cache = 1'b1;
				source_sel = 1'b1; // memory
				load_dirty = 1'b1; // load a 0 if reading (and evicting), load 1 if writing. 
			end
		end
		
		s_load_data_into_cache: begin
			load_cache = 1'b1;
			source_sel = 1'b1; // memory
			way_sel = lru_out; //replace least recently used
			load_dirty = 1'b1; // load a 0 if reading (and evicting), load 1 if writing. 
		end
		
		s_respond_to_cpu: begin
			mem_resp = 1'b1;
			way_sel = hit1; // redundant since this is default; keeping it here anyway for now
			load_lru = 1'b1; // lru will load way_sel into the respective index
			// not sure if mem_write signal will persist here, so additional logic/signals may be needed
			load_cache = mem_write; // want to load cache if we are writing;
			if(mem_write) load_dirty = 1'b1;
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
				if( (mem_read | mem_write) & ~cache_hit & dirty_o) begin
					next_state = s_write_back;
				end
				
				else if( (mem_read | mem_write) & ~cache_hit & ~dirty_o) begin
					next_state = s_load_data_from_mem;
				end
				
				if( (mem_read | mem_write) & cache_hit) begin
					next_state = s_idle; //respond_to_cpu
				end
			end
			
			s_write_back_prev: begin
				next_state = s_write_back;
			end
			
			s_write_back: begin
				if(resp_from_mem == 1'b1) begin
					next_state = s_load_data_from_mem;
				end
			end
			
			s_load_data_from_mem: begin
				if(resp_from_mem == 1'b1) begin
					next_state = s_respond_to_cpu; //s_load_data_into_cache
				end
			end
			
			s_load_data_into_cache: begin
				next_state = s_respond_to_cpu;
			end
			
			s_respond_to_cpu: begin
				next_state = s_idle;
			end
		endcase
	end
end

always_comb 
begin : calculate_performance_counters

	num_instr_hit_i = num_instr_hit;
	num_instr_misses_i = num_instr_misses;
	num_cycles_miss_i = num_cycles_miss;

	case(state)
		
		s_idle: begin
			if( (mem_read | mem_write) & ~cache_hit) begin
				num_instr_misses_i = num_instr_misses+1;
			end

			if ((mem_read | mem_write) & cache_hit & ~stall_ex_mem) begin
				num_instr_hit_i = num_instr_hit+1;
			end
		end
		
		s_write_back_prev: begin
			if (~(~arbiter_data_state & ~instr_resp)) begin
				num_cycles_miss_i = num_cycles_miss+1;
			end
		end
		
		s_write_back: begin
			if (~(~arbiter_data_state & ~instr_resp)) begin
				num_cycles_miss_i = num_cycles_miss+1;
			end
		end
		
		s_load_data_from_mem: begin
			if (~(~arbiter_data_state & ~instr_resp)) begin
				num_cycles_miss_i = num_cycles_miss+1;
			end
		end
		
		s_load_data_into_cache: begin
		end
		
		s_respond_to_cpu: begin
		end
	endcase

end

/* update performance counters*/

always_ff @(posedge clk)
begin : update_performance_counters
	if (rst) begin
		num_instr_hit <= '0;
		num_instr_misses <= '0;
		num_cycles_miss <= '0;
	end
	else begin
		num_instr_hit <= num_instr_hit_i;
		num_instr_misses <= num_instr_misses_i;
		num_cycles_miss <= num_cycles_miss_i;
	end

end


always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_state;
end


endmodule : cache_control

