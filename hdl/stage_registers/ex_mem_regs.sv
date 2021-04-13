import rv32i_types::*;

module ex_mem_regs
(
    input clk,
    input rst,
    input load,
    input logic [31:0] pc_i,
	input rv32i_word instruction_i,
	input instruction_decoded_t instruction_decoded_i,
	input rv32i_control_word control_word_i,
	input rv32i_word rs2_out_i,
	input logic [31:0] alu_out_i,
	input logic br_en_i,
	input logic squash,
    output logic [31:0] pc_o, 
	output rv32i_word instruction_o,
	output instruction_decoded_t instruction_decoded_o,
	output rv32i_control_word control_word_o,
	output rv32i_word rs2_out_o,
	output logic [31:0] alu_out_o,
	output logic br_en_o
);

// internal registers
logic [31:0] pc;
rv32i_word instruction;
instruction_decoded_t instruction_decoded;
rv32i_control_word control_word;
rv32i_word rs2_out;
logic [31:0] alu_out;
logic br_en;

always_ff @(posedge clk)
begin
	// EX/MEM has a special case for squash here, since if there is a stall then we still want to maintain address/mem signals to data cache until the stall is resolved
    if (rst | (squash & load))
    begin
        pc <= '0;
		instruction <= '0;
		instruction_decoded <= '0;
		control_word <= '0;
		rs2_out <= '0;
		alu_out <= '0;
		br_en <= '0;
    end
    else if (load)
    begin
        pc <= pc_i;
		instruction <= instruction_i;
		instruction_decoded <= instruction_decoded_i;
		control_word <= control_word_i;
		rs2_out <= rs2_out_i;
		alu_out <= alu_out_i;
		br_en <= br_en_i;
    end
    else
    begin
        pc <= pc;
		instruction <= instruction;
		instruction_decoded <= instruction_decoded;
		control_word <= control_word;
		rs2_out <= rs2_out;
		alu_out <= alu_out;
		br_en <= br_en;
    end
end

always_comb
begin
    pc_o = pc;
	instruction_o = instruction;
	instruction_decoded_o = instruction_decoded;
	control_word_o = control_word;
	rs2_out_o = rs2_out;
	alu_out_o = alu_out;
	br_en_o = br_en;
end

endmodule : ex_mem_regs
