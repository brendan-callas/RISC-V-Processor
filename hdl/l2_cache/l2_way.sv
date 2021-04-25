module way
(
    input clk,
    input rst,
	
	input logic [2:0] index_i,
	input logic [255:0] data_i,
	input logic [31:0] byte_enable_i,
	input logic load_i,
	input logic mem_write_i,
	input logic [23:0] tag_i,
	input logic read_cache_data_i,
	input logic load_dirty,
	
	output logic [23:0] tag_o,
	output logic valid_o,
	output logic [255:0] data_o,
	output logic dirty_o

    
);

reg_array #(.s_index(3), .width(1)) valid_array(
	.clk(clk),
    .rst(rst),
    .load(load_i),
    .index(index_i),
    .datain(1'b1),	// 1 because the valid bit can never change from 1 to 0 (I think).
    .dataout(valid_o)
);

reg_array #(.s_index(3), .width(1)) dirty_array(
	.clk(clk),
    .rst(rst),
    //.read(read_cache_data_i), //not sure if this needs a separate read signal, or is always 1. Note: read_cache_data_i is currently wired to 1.
    .load(load_dirty),
    //.rindex(index_i),
    //.windex(index_i),
	.index(index_i),
    .datain(mem_write_i), // if we are writing, then the data becomes dirty. This will also be loaded with 0 if read and evict. (write and evict should still load 1).
    .dataout(dirty_o)
);

reg_array #(.s_index(3), .width(24)) tag_array(
	.clk(clk),
    .rst(rst),
    //.read(read_cache_data_i), //not sure if this needs a separate read signal, or is always 1. Note: read_cache_data_i is currently wired to 1.
    .load(load_i),
    //.rindex(index_i),
    //.windex(index_i),
	.index(index_i),
    .datain(tag_i),
    .dataout(tag_o)
);

data_array data_array(
	.clk(clk),
	.rst(rst),
	.read(read_cache_data_i),
	.write_en(byte_enable_i),
	.rindex(index_i),
	.windex(index_i),
	.datain(data_i),
	.dataout(data_o)
);

endmodule : way

//********** Comparator ************//
module comparator #(
    parameter width = 24
)
(
    input logic [width-1:0] a,
	input logic [width-1:0] b,
	output logic f
);

always_comb begin

	if(a == b) begin
		f = 1'b1;
	end
	else f = 1'b0;
	
end

endmodule : comparator