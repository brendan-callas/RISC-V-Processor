/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module i_cache_datapath #(
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
    // input logic mem_write,
    // input logic [31:0] mem_byte_enable256,
    input rv32i_word mem_address,
    // input logic [255:0] mem_wdata256,
	
	// port to cacheline adaptor (to memory)
	output logic [255:0] cacheline_data_out, // also used in port to cpu
    input logic [255:0] data_from_mem,
    output logic [31:0] address_to_mem,
	
	//signals between datapath and control
	// input logic source_sel,
	input logic way_sel,
	// input logic tag_sel,
	input logic load_cache,
	// input logic read_lru,
	input logic load_lru,
	// input logic read_cache_data,
	// input logic load_dirty,
	input logic load_prefetch_buffer,
	// input logic dirty_sel,

	output logic instr_line_hit,
	// output logic dirty_o,
	output logic lru_out,
	
	output logic hit1,

	// new signals between datapath and control
	input logic prefetch_sel,
	input logic load_prefetch_buffer,
	input logic load_busy,
	input logic busy_load_sel,
	input logic busy_index_sel,
	input logic busy_i,

	output logic instr_line_hit,
	output logic obl_line_hit,
	output logic obl_lru_out,
);

// Internal Signals
logic [23:0] mem_addr_tag; // from mem_address
logic [2:0] set; //from mem_address

// logic [255:0] data_source_mux_out;
// logic [31:0] byte_enable_mux_out;
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
// logic dirty0;
// logic dirty1;
// logic load_dirty0;
// logic load_dirty1;
logic valid0;
logic valid1;
// logic [23:0] cache_tag_out;
// logic [23:0] tag_mux_out;
logic comparator0_o;
logic comparator1_o;

// new signals
logic [31:0] obl_address;
logic [2:0] obl_set;
logic [23:0] obl_addr_tag;



assign mem_addr_tag = mem_address[31:8];
assign set = mem_address[7:5];

assign obl_address = mem_address + 32'h00000020;
assign obl_set = obl_address[7:5];
assign obl_addr_tag = obl_address[31:8];

/******************************** Muxes **************************************/
always_comb begin : MUXES

	// // data source mux
	// unique case (source_sel)
	// 	1'b0: data_source_mux_out = mem_wdata256; //cpu_data
	// 	1'b1: data_source_mux_out = data_from_mem; //mem_data;
	// 	default: data_source_mux_out = mem_wdata256; //cpu_data
	// endcase
	
	// // byte enable mux
	// unique case (source_sel)
	// 	1'b0: byte_enable_mux_out = mem_byte_enable256; //cpu byte enable
	// 	1'b1: byte_enable_mux_out = 32'hffffffff; // "memory" byte enable: if reading from memory, we want to overwrite the whole cacheline
	// 	default: byte_enable_mux_out = mem_byte_enable256; //cpu byte enable
	// endcase

	// select address to physical memory
	unique case (prefetch_sel)
		//Still need to get specific 32-byte block, so use addr[31:5]; align to 32-byte blocks
		1'b0: address_to_mem = {mem_address[31:5], 5'b0};
		1'b1: address_to_mem = {prefetch_line, 5'b0}};
		default: address_to_mem = {mem_address[31:5], 5'b0};
	endcase

	// select which index you want 
	unique case (prefetch_sel & load_cache)
		1'b0: begin
			index_i = set;
			tag_i = mem_addr_tag;
		end
		1'b1: begin
			index_i = prefetch_line[2:0];
			tag_i = prefetch_line[26:3];
		end
		default: begin
			index_i = set;
			tag_i = mem_addr_tag;
		end
	endcase

	// select which lru_index you want 
	unique case (prefetch_sel)
		1'b0: lru_index = set;
		1'b1: lru_index = prefetch_line[2:0];
		default: lru_index = set;
	endcase

	// cacheline data mux (selects between the data output of way0 and way1)
	unique case (way_sel)
		1'b0: cacheline_data_out = cacheline_data0;
		1'b1: cacheline_data_out = cacheline_data1;
		default: cacheline_data_out = cacheline_data0;
	endcase

	unique case (busy_index_sel)
		1'b0: busy_index = (prefetch_sel & load_busy) ? prefetch_line[2:0] : set;
		1'b1: busy_index = obl_set;
		default: ;
	endcase
	
	// // tag mux (selects between tag0 and tag1)
	// unique case (way_sel)
	// 	1'b0: cache_tag_out = tag0;
	// 	1'b1: cache_tag_out = tag1;
	// 	default: cache_tag_out = tag0;
	// endcase
	
	// // tag mux (selects between tag from ways, and memory address tag)
	// unique case (tag_sel)
	// 	1'b0: tag_mux_out = cache_tag_out;
	// 	1'b1: tag_mux_out = mem_addr_tag;
	// 	default: tag_mux_out = cache_tag_out;
	// endcase
	
	// // dirty bit out mux
	// unique case (dirty_sel)
	// 	1'b0: dirty_o = dirty0;
	// 	1'b1: dirty_o = dirty1;
	// 	default: dirty_o = dirty0;
	// endcase

	
	// load cache demux
	unique case (way_sel)
		1'b0: begin
			load_way0 = load_cache;
			load_way1 = 1'b0;
			
			// load_dirty0 = load_dirty;
			// load_dirty1 = 1'b0;
		end
		1'b1: begin
			load_way0 = 1'b0;
			load_way1 = load_cache;
			
			// load_dirty0 = 1'b0;
			// load_dirty1 = load_dirty;
		end
		default: begin
			load_way0 = 1'b0;
			load_way1 = 1'b0;
			
			// load_dirty0 = 1'b0;
			// load_dirty1 = 1'b0;
		end
	endcase

	// load cache demux
	unique case (busy_load_sel)
		1'b0: begin
			load_busy0 = load_busy;
			load_busy1 = 1'b0;
		end
		1'b1: begin
			load_busy0 = 1'b0;
			load_busy1 = load_busy;
		end
		default: begin
			load_busy0 = 1'b0;
			load_busy1 = 1'b0;
		end
	endcase

	//end MUXES
	
	//other comb logic
	
	hit0 = (comparator0_o & valid0 & ~busy0);
	hit1 = (comparator1_o & valid1 & ~busy1);

	obl_hit0 = (obl_comparator0 & obl_valid0 & ~obl_busy0);
	obl_hit1 = (obl_comparator0 & obl_valid1 & ~obl_busy1);
	
	instr_line_hit = (hit0 | hit1);

	obl_line_hit = (obl_hit0 | obl_hit1);
	
	//if we are not loading the cache, we do not want to enable writing over any bytes (since the data_array does not have a load signal)
	if(load_way0) begin
		byte_enable_masked0 = 32'hffffffff; // byte_enable_mux_out;
	end
	else byte_enable_masked0 = 32'b0;
	
	if(load_way1) begin
		byte_enable_masked1 = 32'hffffffff; // byte_enable_mux_out;
	end
	else byte_enable_masked1 = 32'b0;
	
	// loading dirty bits
	//logic moved (and changed)
	//load_dirty0 = load_dirty & load_way0;
	//load_dirty1 = load_dirty & load_way1;

end

// new prefetch buffer
register #(.width(27)) prefetch_buffer(
	.clk(clk),
	.rst(rst),
	.load(load_prefetch_buffer),
	.in(obl_address[31:5]), // {obl_addr_tag, obl_set}
	.out(prefetch_line)
);

i_way way0(
	.clk(clk),
  .rst(rst),
	
	.index_i(index_i),
	.data_i(data_from_mem),
	.byte_enable_i(byte_enable_masked0),
	.load_i(load_way0),
	// .mem_write_i(mem_write),
	.tag_i(tag_i),
	.read_cache_data_i(1'b1),
	// .load_dirty(load_dirty0),

	.load_busy(load_busy0),
	.busy_i(busy_i),
	.busy_index_i(busy_index),

	.data_o(cacheline_data0),
	
	.tag_o(tag0),
	.valid_o(valid0),
	.busy_o(busy0),
	// .dirty_o(dirty0),

	.obl_tag_o(obl_tag0),
	.obl_valid_o(obl_valid0),
	.obl_busy_o(obl_busy0)
);

i_way way1(
	.clk(clk),
	.rst(rst),

	.index_i(index_i),
	.data_i(data_from_mem),
	.byte_enable_i(byte_enable_masked1),
	.load_i(load_way1),
	// .mem_write_i(mem_write),
	.tag_i(tag_i),
	.read_cache_data_i(1'b1),
	// .load_dirty(load_dirty1),

	.load_busy(load_busy1),
	.busy_i(busy_i),
	.busy_index_i(busy_index),
	
	.data_o(cacheline_data1),

	.tag_o(tag1),
	.valid_o(valid1),
	.busy_o(busy1),
	// .dirty_o(dirty1),

	.obl_tag_o(obl_tag1),
	.obl_valid_o(obl_valid1),
	.obl_busy_o(obl_busy1)
);

i_reg_array lru_array(
	.clk(clk),
  .rst(rst),
  .load(load_lru),
	.index(lru_index),
  .datain(~way_sel), // want to load the way which is NOT being used
  .dataout(lru_out),
	.obl_dataout(obl_lru_out)
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

comparator obl_comparator0(
	.a(obl_addr_tag),
	.b(obl_tag0),
	.f(obl_comparator0_o)
);

comparator obl_comparator1(
	.a(obl_addr_tag),
	.b(obl_tag1),
	.f(obl_comparator1_o)
);



endmodule : cache_datapath

