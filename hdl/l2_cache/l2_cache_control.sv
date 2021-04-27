/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module l2_cache_control (

	input clk,
	input rst,
	
	// port to cpu
    input logic mem_read,
    input logic mem_write,
	output logic mem_resp,

	//signals between datapath and control
	output logic source_sel,
	output logic [2:0] way_sel,
	output logic tag_sel,
	output logic load_cache,
	output logic load_lru,
	output logic read_cache_data,
	output logic load_dirty_arr,
	output logic [2:0] dirty_sel,
	input logic cache_hit,
	input logic dirty_o,
	input logic [2:0] hit_idx,
	input logic [2:0] plru_idx,
	
	// signals for EWB
	output logic load_ewb,
	output logic evict_addr_sel,
	output logic empty_ewb,
	output logic ewb_wdata_sel,
	input logic ewb_full,
	input logic ewb_hit,
	
	//port to memory
	input logic resp_from_mem,
	output logic read_from_mem,
	output logic write_to_mem
);

// performance counters
int num_hits;
int num_misses;
int num_writebacks;



enum int unsigned {
    /* List of states */
	s_idle,
	s_wait_for_ewb,
	s_write_back_to_ewb,
	s_load_data_from_mem,
	s_respond_to_cpu
	
} state, next_state;

function void set_defaults();
	
	way_sel = hit_idx; // on a hit (idle), want to select the way which has the hit
	tag_sel = 1'b1; //make default to mem addr tag
	read_from_mem = 1'b0;
	write_to_mem = 1'b0;
	load_cache = 1'b0;
	load_lru = 1'b0;
	source_sel = 1'b0;
	read_cache_data = 1'b1; // always want to read cache data
	mem_resp = 1'b0;
	load_dirty_arr = 1'b0;
	dirty_sel = plru_idx; // dirty output is only important for checking if we need to write back when evicting.
	load_ewb = 1'b0;
	evict_addr_sel = 1'b0; // L2 Addr
	empty_ewb = 1'b0;
	ewb_wdata_sel = 1'b0; //cacheline data from L2
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
	
    /* Actions for each state */
	case(state)
		
		s_idle: begin
			//all signals are default
		end
		
		s_wait_for_ewb: begin
			write_to_mem = 1'b1;
			evict_addr_sel = 1'b1;
			if(resp_from_mem)
				empty_ewb = 1'b1;
		end
		
		s_write_back_to_ewb: begin
			way_sel = plru_idx;
			tag_sel = 1'b0; // tag related to cacheline data
			load_ewb = 1'b1;
		end
		
		s_load_data_from_mem: begin
			read_from_mem = 1'b1;
			way_sel = plru_idx;
			tag_sel = 1'b1; //select mem addr tag
			evict_addr_sel = 1'b0; //L2 Address
			
			if(resp_from_mem == 1'b1) begin
				load_cache = 1'b1;
				source_sel = 1'b1; // memory
				load_dirty_arr = 1'b1; // load a 0 if reading (and evicting), load 1 if writing. 
			end
		end
		
		s_respond_to_cpu: begin
			mem_resp = 1'b1;
			way_sel = hit_idx; // redundant since this is default; keeping it here anyway for now
			
			if(ewb_hit) begin
				ewb_wdata_sel = 1'b1; //wdata from L1
				load_ewb = mem_write;
			end
			else begin
				load_cache = mem_write; // want to load cache if we are writing;
				load_lru = 1'b1; // lru will load way_sel into the respective index
				if(mem_write) load_dirty_arr = 1'b1;
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
				if( (mem_read | mem_write) & ~(cache_hit | ewb_hit) & dirty_o) begin
				
					if(ewb_full)
						next_state = s_wait_for_ewb;
					else
						next_state = s_write_back_to_ewb;
				end
				
				else if( (mem_read | mem_write) & ~(cache_hit | ewb_hit) & ~dirty_o) begin
					next_state = s_load_data_from_mem;
				end
				
				if( (mem_read | mem_write) & (cache_hit | ewb_hit) ) begin
					next_state = s_respond_to_cpu;
				end
			end
			
			s_wait_for_ewb: begin
				if(resp_from_mem == 1'b1)
					next_state = s_write_back_to_ewb;
			end
			
			s_write_back_to_ewb: begin
				next_state = s_load_data_from_mem; //loading EWB should only take 1 cycle
			end
			
			s_load_data_from_mem: begin
				if(resp_from_mem == 1'b1) begin
					next_state = s_respond_to_cpu;
				end
			end
			
			s_respond_to_cpu: begin
				next_state = s_idle;
			end
			
		endcase
	end
end



always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_state;
end


endmodule : l2_cache_control

