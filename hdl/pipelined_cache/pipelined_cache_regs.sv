import rv32i_types::*;

module pipelined_cache_regs
(
    input clk,
    input rst,
    input load,
    
	input logic [255:0] mem_rdata_i, 	// from cache
	input logic [255:0] mem_wdata_i,	// from cpu
	input logic hit_i, 				// from cache
	input logic dirty_i, 			// from cache
	input rv32i_word address_i,		// from cpu
	input logic hit1_i,
	input logic lru_i,
	input logic mem_write_i,
	input logic load_cache_i,
	input logic [31:0] byte_enable_masked0_i,
	input logic [31:0] byte_enable_masked1_i,
	input logic [2:0] set_i,
	
	
	output logic [255:0] mem_rdata_o, // to cpu
	output logic [255:0] mem_wdata_o, // to cache
	output logic hit_o,            // to control
	output logic dirty_o,          // to control
	output rv32i_word address_o,    // to cache (mux)
	output logic hit1_o,
	output logic lru_o,
	output logic mem_write_o,
	output logic load_cache_o,
	output logic [31:0] byte_enable_masked0_o,
	output logic [31:0] byte_enable_masked1_o,
	output logic [2:0] set_o
);

// internal registers
logic [255:0] mem_rdata;
logic [255:0] mem_wdata;
logic hit;
logic dirty;
rv32i_word address;
logic hit1;
logic lru;
logic mem_write;
logic load_cache;
logic [31:0] byte_enable_masked0;
logic [31:0] byte_enable_masked1;
logic [2:0] set;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        mem_rdata <= '0;
		mem_wdata <= '0;
		hit <= '0;
		dirty <= '0;
		address <= '0;
		hit1 <= '0;
		lru <= '0;
		mem_write <= '0;
		load_cache <= '0;
		byte_enable_masked0 <= '0;
		byte_enable_masked1 <= '0;
		set <= '0;
    end
    else if (load)
    begin
        mem_rdata <= mem_rdata_i;
		mem_wdata <= mem_wdata_i;
		hit <= hit_i;
		dirty <= dirty_i;
		address <= address_i;
		hit1 <= hit1_i;
		lru <= lru_i;
		mem_write <= mem_write_i;
		load_cache <= load_cache_i;
		byte_enable_masked0 <= byte_enable_masked0_i;
		byte_enable_masked1 <= byte_enable_masked1_i;
		set <= set_i;
    end
    else
    begin
        mem_rdata <= mem_rdata;
		mem_wdata <= mem_wdata;
		hit <= hit;
		dirty <= dirty;
		address <= address;
		hit1 <= hit1;
		lru <= lru;
		mem_write <= mem_write;
		load_cache <= load_cache;
		byte_enable_masked0 <= byte_enable_masked0;
		byte_enable_masked1 <= byte_enable_masked1;
		set <= set;
    end
end

always_comb
begin
    mem_rdata_o = mem_rdata;
	mem_wdata_o = mem_wdata;
	hit_o = hit;
	dirty_o = dirty;
	address_o = address;
	hit1_o = hit1;
	lru_o = lru;
	mem_write_o = mem_write;
	load_cache_o = load_cache;
	byte_enable_masked0_o = byte_enable_masked0;
	byte_enable_masked1_o = byte_enable_masked1;
	set_o = set;
end

endmodule : pipelined_cache_regs