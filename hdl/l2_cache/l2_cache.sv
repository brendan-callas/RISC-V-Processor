/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

import rv32i_types::*;

module l2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input rst,
	
	// port to L2
	output logic mem_resp,
    output logic [255:0] mem_rdata,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata256,
	
	// port to cacheline adaptor (to memory)
	output logic [255:0] pmem_wdata,
    input logic [255:0] pmem_rdata,
    output logic [31:0] pmem_address,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp
	
	
);

//******Internal Signals*****************//

//needed for autograder

//port to cacheline_adaptor
logic [255:0] cacheline_data_out;
logic [255:0] data_from_mem;
logic [31:0] address_to_mem;
logic read_from_mem;
logic write_to_mem;
logic resp_from_mem;


always_comb begin
	resp_from_mem = pmem_resp;
	data_from_mem = pmem_rdata;
	pmem_wdata = cacheline_data_out;
	pmem_read = read_from_mem;
	pmem_write = write_to_mem;
	pmem_address = address_to_mem;
	
	mem_rdata = cacheline_data_out;
end



//signals between control and datapath
logic source_sel;
logic [2:0] way_sel;
logic tag_sel;
logic load_cache;
logic load_lru;
logic read_cache_data;
logic load_dirty_arr;
logic cache_hit;
logic dirty_o;
logic [2:0] hit_idx;
logic [2:0] dirty_sel;
logic [2:0] plru_idx;


l2_cache_control cache_control(.*);

l2_cache_datapath cache_datapath(.*);
 


endmodule : l2_cache

