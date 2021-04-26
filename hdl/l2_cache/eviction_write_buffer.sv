
module eviction_write_buffer
(
	input clk,
	input rst,
	
	input logic load,
	input logic [255:0] wdata_i, // from cache
	input logic [31:0] address_i,
	
	output logic [255:0] wdata_o, //to main memory
	output logic [31:0] address_o
	

);

// internal registers
logic [255:0] wdata;
logic [31:0] address;


always_ff @(posedge clk)
begin
    if (rst) begin
        wdata <= '0;
		address <= '0;
    end
    else begin
        if(load) begin
			wdata <= wdata_i;
			address <= address_i;
		end
    end
end

always_comb begin
	wdata_o = wdata;
	address_o = address;
end




endmodule : eviction_write_buffer