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
	input logic way_sel_i,
	input logic stall_i,
	input logic [31:0] addrmux_out_i,
	input logic force_load,
	
	
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
	output logic way_sel_o,
	output logic stall_o,
	output logic stall2_o,
	output logic [31:0] addrmux_out_o
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
logic way_sel;
logic stall;
logic stall2;
logic [31:0] addrmux_out;

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
		way_sel <= '0;
		stall <= '0;
		addrmux_out <= '0;
    end
    else if (load)
    begin
	
		dirty <= dirty_i;
		hit1 <= hit1_i;
		lru <= lru_i;
		mem_write <= mem_write_i;
		load_cache <= load_cache_i;
		byte_enable_masked0 <= byte_enable_masked0_i;
		byte_enable_masked1 <= byte_enable_masked1_i;
		way_sel <= way_sel_i;
		stall <= stall_i;
		stall2 <= stall;
		
		hit <= hit_i;
		
		
		
		
		if(~stall_i & (hit_i | force_load)) begin

			mem_wdata <= mem_wdata_i;
			mem_rdata <= mem_rdata_i;
			
			address <= address_i;
			addrmux_out <= addrmux_out_i;
			

		end

		if(~stall_i) begin
			
		end
		
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
		way_sel <= way_sel;
		stall <= stall;
		stall2 <= stall;
		addrmux_out <= addrmux_out;
    end
	
	
end

always_comb
begin
<<<<<<< HEAD
	if(hit_i & load)
		mem_rdata_o = mem_rdata_i;
	else mem_rdata_o = mem_rdata;
	//mem_rdata_o = mem_rdata_i;
=======
	//if(~stall)
		//mem_rdata_o = mem_rdata_i;
	//else mem_rdata_o = mem_rdata;
	mem_rdata_o = mem_rdata_i;
>>>>>>> temp
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
	way_sel_o = way_sel;
	stall_o = stall;
	stall2_o = stall2;
	addrmux_out_o = addrmux_out;
end

endmodule : pipelined_cache_regs