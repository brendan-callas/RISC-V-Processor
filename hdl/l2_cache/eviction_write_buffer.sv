
module eviction_write_buffer
(
	input clk,
	input rst,
	
	input logic load,
	input logic [31:0] hit_addr,
	
	input logic [255:0] wdata_i, // from cache
	input logic [31:0] address_i,
	input logic empty,
	
	output logic [255:0] wdata_o, //to main memory and L1
	output logic [31:0] address_o,
	output logic full_o,
	output logic hit_o
	

);

// internal registers
logic [255:0] wdata;
logic [31:0] address;
logic [26:0] tag; //tag of data currently held
logic [26:0] mem_addr_tag; //tag of incoming address to check for a hit
logic full; //if EWB has valid data that still needs writing back
logic hit;




always_ff @(posedge clk)
begin
    if (empty | rst) begin
        wdata <= '0;
		address <= '0;
		full <= '0;
    end
    else begin
        if(load) begin
			wdata <= wdata_i;
			address <= address_i;
			full <= 1'b1;
		end
    end
end

always_comb begin
	wdata_o = wdata;
	address_o = address;
	full_o = full;
	hit_o = hit & full; //only have a hit if there is valid data
	
	tag = address[31:5];
	mem_addr_tag = hit_addr[31:5]; //use more bits since it has no associated set
	
	if( (tag == mem_addr_tag) & full)
		hit_o = 1'b1;
	else hit_o = 1'b0;
	
end




endmodule : eviction_write_buffer