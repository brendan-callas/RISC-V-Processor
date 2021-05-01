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
	
	// port to L1
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


/*
logic mem_read_st;
logic mem_write_st;
logic [31:0] mem_address_st;
logic [255:0] mem_wdata256_st;

logic mem_read;
logic mem_write;
logic [31:0] mem_address;
logic [255:0] mem_wdata256;



always_ff @(posedge clk) begin

	mem_address_st <= mem_address_i;
	mem_wdata256_st <= mem_wdata256_i;

	if(mem_read_i | mem_write_i) begin
		mem_read_st <= mem_read_i;
		mem_write_st <= mem_write_i;
		
	end

end

always_comb begin
	mem_read = mem_read_st;
	mem_write = mem_write_st;
	mem_address = mem_address_st;
	mem_wdata256 = mem_wdata256_st;
end
*/


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
	// pmem_wdata = cacheline_data_out; this now comes from EWB
	pmem_read = read_from_mem;
	pmem_write = write_to_mem;
	//pmem_address = address_to_mem; this now comes from a mux selecting between cache addr and EWB addr
	
	//mem_rdata = cacheline_data_out; selected by mux now
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

// signals for eviction write buffer
logic load_ewb;
logic evict_addr_sel;
logic [31:0] evict_address_to_mem;
logic ewb_full;
logic ewb_hit;
logic empty_ewb;
logic ewb_wdata_sel;
logic [255:0] ewb_data_in;
logic [31:0] ewb_addr_in;


l2_cache_control cache_control(.*);

l2_cache_datapath cache_datapath(.*);

eviction_write_buffer EWB(
	.clk(clk),
	.rst(rst),
	
	.load(load_ewb),
	.hit_addr(mem_address),
	
	.wdata_i(ewb_data_in),
	.address_i(ewb_addr_in),
	.empty(empty_ewb),
	
	.wdata_o(pmem_wdata),
	.address_o(evict_address_to_mem),
	.full_o(ewb_full),
	.hit_o(ewb_hit)
);



always_comb begin
	
	// Mux to select between Cache Addr and EWB Addr
	unique case(evict_addr_sel)
		1'b0: pmem_address = address_to_mem;
		1'b1: pmem_address = evict_address_to_mem;
		default: pmem_address = address_to_mem;
	endcase
	
	// Mux to select rdata going back to L1 (from L2 or from EWB)
	unique case(ewb_hit)
		1'b0: mem_rdata = cacheline_data_out;
		1'b1: mem_rdata = pmem_wdata; // if EWB hit, get data out of EWB
		default: mem_rdata = cacheline_data_out;
	endcase
	
	//Mux for data into EWB
	unique case(ewb_wdata_sel)
		1'b0: begin
			ewb_data_in = cacheline_data_out;
			ewb_addr_in = address_to_mem;
		end
		1'b1: begin
			ewb_data_in = mem_wdata256;
			ewb_addr_in = mem_address;
		end
		default: begin
			ewb_data_in = cacheline_data_out;
			ewb_addr_in = address_to_mem;
		end
	endcase
end
 


endmodule : l2_cache

