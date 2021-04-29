/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

import rv32i_types::*;

module i_cache #(
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
	
	// port to cpu
	output logic mem_resp,
    output rv32i_word mem_rdata,
    input logic mem_read,
    // input logic mem_write,
    // input logic [3:0] mem_byte_enable,
    input rv32i_word mem_address,
    // input rv32i_word mem_wdata,
	
	// port to cacheline adaptor (to memory)
	output logic [255:0] pmem_wdata,
    input logic [255:0] pmem_rdata,
    output logic [31:0] pmem_address,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp,
	//output logic [255:0] cacheline_data_out,
    //input logic [255:0] data_from_mem,
    //output logic [31:0] address_to_mem,
    //output logic read_from_mem,
    //output logic write_to_mem,
    //input logic resp_from_mem

    // inputs for performance counters
    input logic data_request,
    input logic arbiter_instr_state
	
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
end



//signals between control and datapath
// logic source_sel;
logic way_sel;
// logic tag_sel;
logic load_cache;
// logic read_lru;
logic load_lru;
// logic read_cache_data;
// logic load_dirty;
logic cache_hit;
// logic dirty_o;
logic lru_out;
logic hit1;
// logic dirty_sel;

// new signals between datapath and control
logic prefetch_sel;
logic load_prefetch_buffer;
logic load_busy;
logic busy_load_sel;
logic busy_index_sel;
logic busy_i;
logic lru_index_sel;

logic instr_line_hit;
logic obl_line_hit;
logic obl_lru_out;

// bus adaptor signals
logic mem_write;
logic [3:0] mem_byte_enable;
rv32i_word mem_wdata;

logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic [31:0] mem_byte_enable256;

assign mem_write = 1'b1;
assign mem_byte_enable = 4'b1111;

i_cache_control control(.*);

i_cache_datapath datapath(.*); 

// A module to help your CPU (which likes to deal with 4 bytes at a time) talk to your cache (which likes to deal with 32 bytes at a time)
bus_adapter bus_adapter
(
	.mem_wdata256(mem_wdata256),
    .mem_rdata256(cacheline_data_out),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);

endmodule : i_cache

