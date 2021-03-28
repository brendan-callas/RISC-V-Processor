module mp4(

	input clk,
	input rst,
	
	/* I Cache Ports */
    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input logic [31:0] inst_rdata,

    /* D Cache Ports */
    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input logic data_resp,
    input logic [31:0] data_rdata
);

	
datapath datapath(

	.clk(clk),
	.rst(rst),
	
	// I Cache ports
	.instr_mem_read(inst_read),
	.instr_mem_address(inst_addr),
	.instr_mem_resp(inst_resp),
	.instr_mem_rdata(inst_rdata),
	
	
	// D Cache ports
	.data_mem_read(data_read),
	.data_mem_write(data_write),
	.mem_byte_enable(data_mbe),
	.data_mem_address(data_addr),
	.data_mem_wdata(data_wdata),
	.data_mem_resp(data_resp),
	.data_mem_rdata(data_rdata)	

);


endmodule : mp4
