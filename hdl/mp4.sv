module mp4(

	input clk,
	input rst,
	
	input logic pmem_resp,
	input logic [63:0] pmem_rdata,
	
	output logic pmem_read,
	output logic pmem_write,
	output logic [31:0] pmem_address,
	output logic [63:0] pmem_wdata

	
);

/* I Cache Ports */
logic inst_read;
logic [31:0] inst_addr;
logic inst_resp;
logic [31:0] inst_rdata;

/* D Cache Ports */
logic data_read;
logic data_write;
logic [3:0] data_mbe;
logic [31:0] data_addr;
logic [31:0] data_wdata;
logic data_resp;
logic [31:0] data_rdata;

/* I Cache Ports, to Physical mem */
logic inst_read_p;
logic [31:0] inst_addr_p;
logic inst_resp_p;
logic [255:0] inst_rdata_p;
logic [255:0] inst_wdata_p; //useless
logic inst_write_p; //useless

/* D Cache Ports, to Physical Mem */
logic data_read_p;
logic data_write_p;
logic [31:0] data_addr_p;
logic [255:0] data_wdata_p;
logic data_resp_p;
logic [255:0] data_rdata_p;

// signals between cache and cacheline adaptor
logic [255:0] cacheline_data_out;
logic [255:0] data_from_mem;
logic [31:0] address_to_mem;
logic read_from_mem;
logic write_to_mem;
logic resp_from_mem;

	
datapath datapath(

	.clk(clk),
	.rst(rst),
	
	// I Cache ports
	.inst_mem_read(inst_read),
	.inst_mem_address(inst_addr),
	.inst_mem_resp(inst_resp),
	.inst_mem_rdata(inst_rdata),
	
	
	// D Cache ports
	.data_mem_read(data_read),
	.data_mem_write(data_write),
	.mem_byte_enable(data_mbe),
	.data_mem_address(data_addr),
	.data_mem_wdata(data_wdata),
	.data_mem_resp(data_resp),
	.data_mem_rdata(data_rdata)	

);

cache_arbiter cache_arbiter
(
	.clk(clk),
	.rst(rst),

	//inputs from caches
	.data_mem_read(data_read_p),
	.inst_mem_read(inst_read_p),
	.data_mem_write(data_write_p),
	.data_mem_addr(data_addr_p),
	.inst_mem_addr(inst_addr_p),
	.data_mem_wdata(data_wdata_p),
	
	//outputs to caches
	.data_mem_rdata(data_rdata_p),
	.inst_mem_rdata(inst_rdata_p),
	.data_mem_resp(data_resp_p),
	.inst_mem_resp(inst_resp_p),
	
	//inputs from adaptor
	.mem_rdata(data_from_mem),
	.mem_resp(resp_from_mem),
	
	//outputs to adaptor
	.mem_read(read_from_mem),
	.mem_write(write_to_mem),
	.mem_wdata(cacheline_data_out),
	.mem_address(address_to_mem)
);

cacheline_adaptor cacheline_adaptor
(
	.clk(clk),
    .reset_n(~rst),

    // Port to LLC (Arbiter)
    .line_i(cacheline_data_out),
    .line_o(data_from_mem),
    .address_i(address_to_mem),
    .read_i(read_from_mem),
    .write_i(write_to_mem), 
    .resp_o(resp_from_mem),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

cache inst_cache (
  .clk(clk),
  .rst(rst),

  /* Physical memory signals */
  .pmem_resp(inst_resp_p),
  .pmem_rdata(inst_rdata_p),
  .pmem_address(inst_addr_p),
  .pmem_wdata(inst_wdata_p), //nothing
  .pmem_read(inst_read_p),
  .pmem_write(inst_write_p), //nothing

  /* CPU memory signals */
  .mem_read(inst_read),
  .mem_write(1'b0),
  .mem_byte_enable(4'b1111),
  .mem_address(inst_addr),
  .mem_wdata(32'b0),
  .mem_resp(inst_resp),
  .mem_rdata(inst_rdata)
);

pipelined_cache data_cache (
  .clk(clk),
  .rst(rst),

  /* Physical memory signals */
  .pmem_resp(data_resp_p),
  .pmem_rdata(data_rdata_p),
  .pmem_address(data_addr_p),
  .pmem_wdata(data_wdata_p),
  .pmem_read(data_read_p),
  .pmem_write(data_write_p),

  /* CPU memory signals */
  .mem_read(data_read),
  .mem_write(data_write),
  .mem_byte_enable(data_mbe),
  .mem_address(data_addr),
  .mem_wdata(data_wdata),
  .mem_resp(data_resp),
  .mem_rdata(data_rdata)
);


endmodule : mp4
