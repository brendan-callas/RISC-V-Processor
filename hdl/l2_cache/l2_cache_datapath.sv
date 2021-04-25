/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module l2_cache_datapath #(
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
    input logic mem_read,
    input logic mem_write,
    input rv32i_word mem_address,
    input logic [255:0] mem_wdata256,
	
	// port to cacheline adaptor (to memory)
	output logic [255:0] cacheline_data_out,
    input logic [255:0] data_from_mem,
    output logic [31:0] address_to_mem,
	
	//signals between datapath and control
	input logic source_sel,
	input logic [2:0] way_sel,
	input logic tag_sel,
	input logic load_cache,
	input logic load_lru,
	input logic read_cache_data,
	input logic load_dirty_arr,
	input logic [2:0] dirty_sel,
	output logic cache_hit,
	output logic dirty_o,
	output logic [2:0] plru_idx,
	output logic [2:0] hit_idx
);

// Internal Signals
logic [23:0] mem_addr_tag; // from mem_address
logic [2:0] set; //from mem_address
logic [255:0] data_source_mux_out;
logic [31:0] byte_enable_mux_out;
logic [31:0] byte_enable_masked[7:0]; //this signal goes into the ways' byte enable
logic [255:0] cacheline_data[7:0]; //output of way 0 data
logic [23:0] tag[7:0];
logic load_way[7:0];
logic hit[7:0];
logic dirty[7:0];
logic load_dirty[7:0];
logic valid[7:0];
logic [23:0] cache_tag_out;
logic [23:0] tag_mux_out;
logic comparator_o [7:0];



assign mem_addr_tag = mem_address[31:8];
assign set = mem_address[7:5];
assign address_to_mem = {tag_mux_out, mem_address[7:5], 5'b0}; //Still need to get specific 32-byte block, so use mem_addr[7:5]; align to 32-byte blocks



/******************************** Muxes **************************************/
always_comb begin : MUXES

	// data source mux
	unique case (source_sel)
		1'b0: data_source_mux_out = mem_wdata256; //cpu_data
		1'b1: data_source_mux_out = data_from_mem; //mem_data;
		default: data_source_mux_out = mem_wdata256; //cpu_data
	endcase
	
	// byte enable mux
	unique case (source_sel)
		1'b0: byte_enable_mux_out = 32'hffffffff; //cpu byte enable
		1'b1: byte_enable_mux_out = 32'hffffffff; // "memory" byte enable: if reading from memory, we want to overwrite the whole cacheline
		default: byte_enable_mux_out = 32'hffffffff; //cpu byte enable
	endcase
	
	// cacheline data mux
	cacheline_data_out = cacheline_data[way_sel];
	
	// tag mux
	cache_tag_out = tag[way_sel];
	
	// tag mux (selects between tag from ways, and memory address tag)
	unique case (tag_sel)
		1'b0: tag_mux_out = cache_tag_out;
		1'b1: tag_mux_out = mem_addr_tag;
		default: tag_mux_out = cache_tag_out;
	endcase
	
	// dirty bit out mux
	dirty_o = dirty[dirty_sel];

	
	// load cache demux
	load_way[0] = 1'b0;
	load_way[1] = 1'b0;
	load_way[2] = 1'b0;
	load_way[3] = 1'b0;
	load_way[4] = 1'b0;
	load_way[5] = 1'b0;
	load_way[6] = 1'b0;
	load_way[7] = 1'b0;
	
	load_dirty[0] = 1'b0;
	load_dirty[1] = 1'b0;
	load_dirty[2] = 1'b0;
	load_dirty[3] = 1'b0;
	load_dirty[4] = 1'b0;
	load_dirty[5] = 1'b0;
	load_dirty[6] = 1'b0;
	load_dirty[7] = 1'b0;
	// set selected to 1
	load_way[way_sel] = 1'b1 & load_cache;
	load_dirty[way_sel] = 1'b1 & load_dirty_arr;

	//end MUXES
	
	//other comb logic
	
	hit[0] = comparator_o[0] & valid[0];
	hit[1] = comparator_o[1] & valid[1];
	hit[2] = comparator_o[2] & valid[2];
	hit[3] = comparator_o[3] & valid[3];
	hit[4] = comparator_o[4] & valid[4];
	hit[5] = comparator_o[5] & valid[5];
	hit[6] = comparator_o[6] & valid[6];
	hit[7] = comparator_o[7] & valid[7];
	
	cache_hit = (hit[0] | hit[1] | hit[2] | hit[3] | hit[4] | hit[5] | hit[6] | hit[7]);
	
	if(hit[0])
		hit_idx = 3'd0;
	else if(hit[1])
		hit_idx = 3'd1;
	else if(hit[2])
		hit_idx = 3'd2;
	else if(hit[3])
		hit_idx = 3'd3;
	else if(hit[4])
		hit_idx = 3'd4;
	else if(hit[5])
		hit_idx = 3'd5;
	else if(hit[6])
		hit_idx = 3'd6;
	else if(hit[7])
		hit_idx = 3'd7;
	else hit_idx = 3'd0;
	
	//if we are not loading the cache, we do not want to enable writing over any bytes (since the data_array does not have a load signal)
	byte_enable_masked[0] = load_way[0] ? 32'hffffffff : 32'b0;
	byte_enable_masked[1] = load_way[1] ? 32'hffffffff : 32'b0;
	byte_enable_masked[2] = load_way[2] ? 32'hffffffff : 32'b0;
	byte_enable_masked[3] = load_way[3] ? 32'hffffffff : 32'b0;
	byte_enable_masked[4] = load_way[4] ? 32'hffffffff : 32'b0;
	byte_enable_masked[5] = load_way[5] ? 32'hffffffff : 32'b0;
	byte_enable_masked[6] = load_way[6] ? 32'hffffffff : 32'b0;
	byte_enable_masked[7] = load_way[7] ? 32'hffffffff : 32'b0;
	
	
end

way way0(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[0]),
	.load_i(load_way[0]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[0]),
	
	.tag_o(tag[0]),
	.valid_o(valid[0]),
	.data_o(cacheline_data[0]),
	.dirty_o(dirty[0])
);

way way1(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[1]),
	.load_i(load_way[1]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[1]),
	
	.tag_o(tag[1]),
	.valid_o(valid[1]),
	.data_o(cacheline_data[1]),
	.dirty_o(dirty[1])
);

way way2(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[2]),
	.load_i(load_way[2]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[2]),
	
	.tag_o(tag[2]),
	.valid_o(valid[2]),
	.data_o(cacheline_data[2]),
	.dirty_o(dirty[2])
);

way way3(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[3]),
	.load_i(load_way[3]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[3]),
	
	.tag_o(tag[3]),
	.valid_o(valid[3]),
	.data_o(cacheline_data[3]),
	.dirty_o(dirty[3])
);

way way4(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[4]),
	.load_i(load_way[4]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[4]),
	
	.tag_o(tag[4]),
	.valid_o(valid[4]),
	.data_o(cacheline_data[4]),
	.dirty_o(dirty[4])
);

way way5(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[5]),
	.load_i(load_way[5]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[5]),
	
	.tag_o(tag[5]),
	.valid_o(valid[5]),
	.data_o(cacheline_data[5]),
	.dirty_o(dirty[5])
);

way way6(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[6]),
	.load_i(load_way[6]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[6]),
	
	.tag_o(tag[6]),
	.valid_o(valid[6]),
	.data_o(cacheline_data[6]),
	.dirty_o(dirty[6])
);

way way7(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked[7]),
	.load_i(load_way[7]),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty[7]),
	
	.tag_o(tag[7]),
	.valid_o(valid[7]),
	.data_o(cacheline_data[7]),
	.dirty_o(dirty[7])
);


plru plru
(
    .clk(clk),
    .rst(rst),
    .load(load_lru),
	.set(set), // the set idx which is being accessed
    .plru_idx(plru_idx) // the index to replace if evicting
);

comparator comparator0(
	.a(mem_addr_tag),
	.b(tag[0]),
	.f(comparator_o[0])
);

comparator comparator1(
	.a(mem_addr_tag),
	.b(tag[1]),
	.f(comparator_o[1])
);

comparator comparator2(
	.a(mem_addr_tag),
	.b(tag[2]),
	.f(comparator_o[2])
);

comparator comparator3(
	.a(mem_addr_tag),
	.b(tag[3]),
	.f(comparator_o[3])
);

comparator comparator4(
	.a(mem_addr_tag),
	.b(tag[4]),
	.f(comparator_o[4])
);

comparator comparator5(
	.a(mem_addr_tag),
	.b(tag[5]),
	.f(comparator_o[5])
);

comparator comparator6(
	.a(mem_addr_tag),
	.b(tag[6]),
	.f(comparator_o[6])
);

comparator comparator7(
	.a(mem_addr_tag),
	.b(tag[7]),
	.f(comparator_o[7])
);






endmodule : l2_cache_datapath

