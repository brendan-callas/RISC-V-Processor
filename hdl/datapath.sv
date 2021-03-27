import rv32i_types::*;

module datapath
(
	input clk,
    input rst,
    input instr_mem_resp, //both mem_resp signals are unused for CP1 since we expect data ready in 1 cycle always from magic mem
	input data_mem_resp,
    input rv32i_word instr_mem_rdata,
	input rv32i_word data_mem_rdata,
	output logic instr_mem_read,
    output logic data_mem_read,
    output logic data_mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word instr_mem_address,
	output rv32i_word data_mem_address,
    output rv32i_word data_mem_wdata
);

// Internal Signals

// Outputs of IF/ID Stage
rv32i_word pc_if_id;
rv32i_word instruction_if_id;
rv32i_word instruction_decoded; //from instruction_decoder

// Outputs of Regfile
rv32i_word rs1_out;
rv32i_word rs2_out;

// Output of Control ROM
rv32i_control_word control_word;

// Outputs of ID/EX Stage
rv32i_control_word control_word_id_ex;
rv32i_word rs1_out_id_ex;
rv32i_word rs2_out_id_ex;
rv32i_word pc_id_ex;
rv32i_word instruction_id_ex;
rv32i_word instruction_decoded_id_ex;

rv32i_word cmpmux_out;
logic br_en; //output of Comparator
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word alu_out; // original output of ALU

// Outputs of EX/MEM Stage
rv32i_control_word control_word_ex_mem;
rv32i_word rs2_out_ex_mem;
rv32i_word pc_ex_mem;
rv32i_word instruction_ex_mem;
rv32i_word instruction_decoded_ex_mem;
rv32i_word alu_out_ex_mem;
logic br_en_ex_mem;
logic [31:0] br_en_extended; //zero-extend

rv32i_word mem_data_out; //from Data Cache

// Outputs of MEM/WB Stage
rv32i_control_word control_word_mem_wb;
rv32i_word pc_mem_wb;
rv32i_word instruction_mem_wb;
rv32i_word instruction_decoded_mem_wb;
rv32i_word alu_out_mem_wb;
logic [31:0] br_en_mem_wb;
rv32i_word mem_data_out_mem_wb;

rv32i_word regfilemux_out;

// Mux Selects
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;




// Pipeline stage registers

if_id_regs if_id_regs(
	.clk(clk),
    .rst(rst),
    .load(1'b1),
    .pc_i(pc_out),
	.instruction_i(instr_mem_rdata),
    .pc_o(pc_if_id),
	.instruction_o(instruction_if_id)
);

id_ex_regs id_ex_regs(
	.clk(clk),
    .rst(rst),
    .load(1'b1),
    .pc_i(pc_if_id),
	.instruction_i(instruction_if_id),
	.instruction_decoded_i(instruction_decoded),
	.control_word_i(control_word),
	.rs1_out_i(rs1_out),
	.rs2_out_i(rs2_out),
    .pc_o(pc_id_ex),
	.instruction_o(instruction_id_ex),
	.instruction_decoded_o(instruction_decoded_id_ex),
	.control_word_o(control_word_id_ex),
	.rs1_out_o(rs1_id_ex),
	.rs2_out_o(rs2_id_ex)
);


// other modules

pc_register PC(
    .clk  (clk),
    .rst (rst),
    .load (1'b1),
    .in   (pcmux_out),
    .out  (pc_out)
);

control_rom control_rom(
	.opcode(instruction_decoded.opcode),
	.funct3(instruction_decoded.funct3),
    .funct7(instruction_decoded.funct7),
	.control_word(control_word)
);

// loading in data (load, data in, dest/rd) comes from MEM/WB stage
// selecting rs1 and rs2 comes from IF/ID stage
regfile regfile(
	.clk(clk),
    .rst(rst),
    .load(control_word_mem_wb.load_regfile),
    .in(regfilemux_out),
    .src_a(instruction_decoded.rs1),
	.src_b(instruction_decoded.rs2),
	.dest(instruction_decoded_mem_wb.rd),
    .reg_a(rs1_out),
	.reg_b(rs2_out)
);

instruction_decoder instruction_decoder(
    .in(instruction_if_id),
    .out(instruction_decoded)
);





endmodule : datapath