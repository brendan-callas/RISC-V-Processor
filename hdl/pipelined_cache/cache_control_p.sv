/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control_p (

	input clk,
	input rst,
	
	// port to cpu
    input logic mem_read,
    input logic mem_write,
	//output logic mem_resp, // this is output by datapath now

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
	output logic addrmux_sel,
	output logic stall_regs,
	output logic force_load,
	input logic cache_hit,
	input logic dirty_o,
	input logic lru_out,
	input logic hit1,
	input logic stall, //if there is a pipeline stall due to instruction read
	
	//port to memory
	input logic resp_from_mem,
	output logic read_from_mem,
	output logic write_to_mem
);


enum int unsigned {
    /* List of states */
	s_idle,
	s_miss,
	s_write_back,
	s_load_data_from_mem,
	s_load_data_into_cache,
	s_load_data_into_cache2,
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
	//mem_resp = 1'b0;
	load_dirty = 1'b0;
	dirty_sel = lru_out; // dirty output is only important for checking if we need to write back when evicting.
	addrmux_sel = 1'b0; // cpu (current) address
	stall_regs = 1'b0;
	force_load = 1'b0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
	
    /* Actions for each state */
	case(state)
		
		s_idle: begin
			if( (mem_read | mem_write) & cache_hit) begin
				//way_sel = hit1; // redundant since this is default; keeping it here anyway for now
				//load_lru = 1'b1; // lru will load way_sel into the respective index
				//load_cache = mem_write; // want to load cache if we are writing;
				//if(mem_write) load_dirty = 1'b1;
			end
			
			force_load = 1'b1;
			
			//if(~cache_hit) stall_regs = 1'b1;
		end
		
		// have a state for checking dirty bit
		s_miss: begin
			way_sel = lru_out; //should this be changed since data from cacheline is delayed a cycle? (set this in prev state)
			tag_sel = 1'b1;
			addrmux_sel = 1'b1; // previous address
			stall_regs = 1'b1;
		end
		
		
		s_write_back: begin
			write_to_mem = 1'b1;
			way_sel = lru_out; //should this be changed since data from cacheline is delayed a cycle? (set this in prev state)
			tag_sel = 1'b0; //choose mem address from tag (concat with set)
			addrmux_sel = 1'b1; // previous address
			stall_regs = 1'b1;
		end
		
		s_load_data_from_mem: begin
			read_from_mem = 1'b1;
			way_sel = lru_out;
			tag_sel = 1'b1; //select mem addr tag
			addrmux_sel = 1'b1; // previous address
			stall_regs = 1'b1;
			
		end
		
		s_load_data_into_cache: begin
			load_cache = 1'b1;
			source_sel = 1'b1; // memory
			way_sel = lru_out; //replace least recently used
			load_dirty = 1'b1; // load a 0 if reading (and evicting), load 1 if writing. 
			addrmux_sel = 1'b1; // previous address
			stall_regs = 1'b1;
		end
		
		s_load_data_into_cache2: begin
			load_cache = 1'b1;
			source_sel = 1'b1; // memory
			way_sel = lru_out; //replace least recently used
			load_dirty = 1'b1; // load a 0 if reading (and evicting), load 1 if writing. 
			addrmux_sel = 1'b1; // previous address
			stall_regs = 1'b1;
		end
		
		s_respond_to_cpu: begin
			//mem_resp = 1'b1;
			way_sel = hit1; // redundant since this is default; keeping it here anyway for now
			load_lru = 1'b1; // lru will load way_sel into the respective index
			load_cache = mem_write; // want to load cache if we are writing;
			if(mem_write) load_dirty = 1'b1;
			addrmux_sel = 1'b0; // cpu (current) address
			stall_regs = 1'b0;
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
					next_state = s_respond_to_cpu;
				end
			end
			
			s_miss: begin
				if(dirty_o) begin
					next_state = s_write_back;
				end
				
				else begin
					next_state = s_load_data_from_mem;
				end
			end
			
			
			s_write_back: begin
				if(resp_from_mem == 1'b1) begin
					next_state = s_load_data_from_mem;
				end
			end
			
			s_load_data_from_mem: begin
				if(resp_from_mem == 1'b1) begin
					next_state = s_load_data_into_cache; //s_load_data_into_cache
				end
			end
			
			s_load_data_into_cache: begin
				next_state = s_respond_to_cpu; 
			end
			
			s_load_data_into_cache2: begin
				next_state = s_respond_to_cpu;
			end
			
			s_respond_to_cpu: begin
			
				if( (mem_read | mem_write) & ~cache_hit & dirty_o) begin
					next_state = s_write_back; //s_write_back;
				end
				
				else if( (mem_read | mem_write) & ~cache_hit & ~dirty_o) begin
					next_state = s_load_data_from_mem; //s_load_data_from_mem;
				end
				
				else if( (mem_read | mem_write) & cache_hit) begin
					next_state = s_respond_to_cpu;
				end
				else next_state = s_idle; //NOT SURE ABOUT THIS
			end
		endcase
	end
end



always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	if(~stall)
		state <= next_state;
end


endmodule : cache_control_p

