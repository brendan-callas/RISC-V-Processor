import rv32i_types::*;

module mem_wb_regs
(
    input clk,
    input rst,
    input load,
    input logic [31:0] pc_i,
	input rv32i_word instruction_i,
	input instruction_decoded_t instruction_decoded_i,
	input rv32i_control_word control_word_i,
	input logic [31:0] mem_data_out_i,
	input logic [31:0] alu_out_i,
	input logic [31:0] br_en_i,
	
    output logic [31:0] pc_o,
	output rv32i_word instruction_o,
	output instruction_decoded_t instruction_decoded_o,
	output rv32i_control_word control_word_o,
	output logic [31:0] mem_data_out_o,
	output logic [31:0] alu_out_o,
	output logic [31:0] br_en_o,
	
	input logic halt_i,
	output logic halt_o
);

// internal registers
logic [31:0] pc;
rv32i_word instruction;
instruction_decoded_t instruction_decoded;
rv32i_control_word control_word;
logic [31:0] mem_data_out;
logic [31:0] alu_out;
logic [31:0] br_en;

logic halt;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        pc <= '0;
		instruction <= '0;
		instruction_decoded <= '0;
		control_word <= '0;
		mem_data_out <= '0;
		alu_out <= '0;
		br_en <= '0;
		
		halt <= halt_i; //dont squah halt
    end
    else if (load)
    begin
        pc <= pc_i;
		instruction <= instruction_i;
		instruction_decoded <= instruction_decoded_i;
		control_word <= control_word_i;
		mem_data_out <= mem_data_out_i;
		alu_out <= alu_out_i;
		br_en <= br_en_i;
		halt <= halt_i;
    end
    else
    begin
        pc <= pc;
		instruction <= instruction;
		instruction_decoded <= instruction_decoded;
		control_word <= control_word;
		mem_data_out <= mem_data_out;
		alu_out <= alu_out;
		br_en <= br_en;
		halt <= halt;
    end
end

always_comb
begin
    pc_o = pc;
	instruction_o = instruction;
	instruction_decoded_o = instruction_decoded;
	control_word_o = control_word;
	mem_data_out_o = mem_data_out;
	alu_out_o = alu_out;
	br_en_o = br_en;
	halt_o = halt;
end

endmodule : mem_wb_regs
