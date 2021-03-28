module mp4(

	input clk,
	input rst,
	
	
	input pmem_mem_resp,
	input pmem_mem_rdata,
	
	output rv32i_word pmem_mem_read,
	output pmem_mem_write,
	output pmem_mem_wdata,
	output rv32i_word pmem_mem_addr

);

	

datapath datapath(

	.clk,
	.rst,

	//inputs
	.instr_mem_resp,
	.data_mem_resp,
	.instr_mem_rdata,
	.data_mem_rdata,

	//outputs
	.instr_mem_read,
	.data_mem_read,
	.data_mem_write,
	.mem_byte_enable,
	.instr_mem_address,
	.data_mem_address,
	.data_mem_wdata

);

control_rom control_rom(

	.opcode,
	.funct3,
	.funct7,
	
	.control_word

);

endmodule : mp4
