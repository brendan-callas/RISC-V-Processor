/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module cache_datapath #(
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
    //output logic [255:0] mem_rdata256,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] mem_byte_enable256,
    input rv32i_word mem_address,
    input logic [255:0] mem_wdata256,
	
	// port to cacheline adaptor (to memory)
	output logic [255:0] cacheline_data_out,
    input logic [255:0] data_from_mem,
    output logic [31:0] address_to_mem,
	
	//signals between datapath and control
	input logic source_sel,
	input logic way_sel,
	input logic tag_sel,
	input logic load_cache,
	input logic read_lru,
	input logic load_lru,
	input logic read_cache_data,
	input logic load_dirty,
	input logic dirty_sel,
	output logic cache_hit,
	output logic dirty_o,
	output logic lru_out,
	output logic hit1
);

// Internal Signals
logic [23:0] mem_addr_tag; // from mem_address
logic [2:0] set; //from mem_address
logic [255:0] data_source_mux_out;
logic [31:0] byte_enable_mux_out;
logic [31:0] byte_enable_masked0; //this signal goes into the ways' byte enable
logic [31:0] byte_enable_masked1; //this signal goes into the ways' byte enable
logic [255:0] cacheline_data0; //output of way 0 data
logic [255:0] cacheline_data1;
logic [23:0] tag0;
logic [23:0] tag1;
logic load_way0;
logic load_way1;
// hit0 declared as output
logic hit0;
logic dirty0;
logic dirty1;
logic load_dirty0;
logic load_dirty1;
logic valid0;
logic valid1;
logic [23:0] cache_tag_out;
logic [23:0] tag_mux_out;
logic comparator0_o;
logic comparator1_o;



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
		1'b0: byte_enable_mux_out = mem_byte_enable256; //cpu byte enable
		1'b1: byte_enable_mux_out = 32'hffffffff; // "memory" byte enable: if reading from memory, we want to overwrite the whole cacheline
		default: byte_enable_mux_out = mem_byte_enable256; //cpu byte enable
	endcase
	
	// cacheline data mux (selects between the data output of way0 and way1)
	unique case (way_sel)
		1'b0: cacheline_data_out = cacheline_data0;
		1'b1: cacheline_data_out = cacheline_data1;
		default: cacheline_data_out = cacheline_data0;
	endcase
	
	// tag mux (selects between tag0 and tag1)
	unique case (way_sel)
		1'b0: cache_tag_out = tag0;
		1'b1: cache_tag_out = tag1;
		default: cache_tag_out = tag0;
	endcase
	
	// tag mux (selects between tag from ways, and memory address tag)
	unique case (tag_sel)
		1'b0: tag_mux_out = cache_tag_out;
		1'b1: tag_mux_out = mem_addr_tag;
		default: tag_mux_out = cache_tag_out;
	endcase
	
	// dirty bit out mux
	unique case (dirty_sel)
		1'b0: dirty_o = dirty0;
		1'b1: dirty_o = dirty1;
		default: dirty_o = dirty0;
	endcase

	
	// load cache demux
	unique case (way_sel)
		1'b0: begin
			load_way0 = load_cache;
			load_way1 = 1'b0;
			
			load_dirty0 = load_dirty;
			load_dirty1 = 1'b0;
		end
		1'b1: begin
			load_way0 = 1'b0;
			load_way1 = load_cache;
			
			load_dirty0 = 1'b0;
			load_dirty1 = load_dirty;
		end
		default: begin
			load_way0 = 1'b0;
			load_way1 = 1'b0;
			
			load_dirty0 = 1'b0;
			load_dirty1 = 1'b0;
		end
	endcase
	//end MUXES
	
	//other comb logic
	
	hit0 = (comparator0_o & valid0);
	hit1 = (comparator1_o & valid1);
	
	cache_hit = (hit0 | hit1);
	
	//if we are not loading the cache, we do not want to enable writing over any bytes (since the data_array does not have a load signal)
	if(load_way0) begin
		byte_enable_masked0 = byte_enable_mux_out;
	end
	else byte_enable_masked0 = 32'b0;
	
	if(load_way1) begin
		byte_enable_masked1 = byte_enable_mux_out;
	end
	else byte_enable_masked1 = 32'b0;
	
	// loading dirty bits
	//logic moved (and changed)
	//load_dirty0 = load_dirty & load_way0;
	//load_dirty1 = load_dirty & load_way1;
	
	
end

way way0(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked0),
	.load_i(load_way0),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty0),
	
	.tag_o(tag0),
	.valid_o(valid0),
	.data_o(cacheline_data0),
	.dirty_o(dirty0)
);

way way1(
	.clk(clk),
    .rst(rst),
	
	.index_i(set),
	.data_i(data_source_mux_out),
	.byte_enable_i(byte_enable_masked1),
	.load_i(load_way1),
	.mem_write_i(mem_write),
	.tag_i(mem_addr_tag),
	.read_cache_data_i(1'b1),
	.load_dirty(load_dirty1),
	
	.tag_o(tag1),
	.valid_o(valid1),
	.data_o(cacheline_data1),
	.dirty_o(dirty1)
);

reg_array lru_array(
	.clk(clk),
    .rst(rst),
    //.read(read_lru),
    .load(load_lru),
    //.rindex(set),
    //.windex(set),
	.index(set),
    .datain(~way_sel), // want to load the way which is NOT being used
    .dataout(lru_out)
);

comparator comparator0(
	.a(mem_addr_tag),
	.b(tag0),
	.f(comparator0_o)
);

comparator comparator1(
	.a(mem_addr_tag),
	.b(tag1),
	.f(comparator1_o)
);





endmodule : cache_datapath

