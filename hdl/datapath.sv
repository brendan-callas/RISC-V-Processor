`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
	input clk,
    input rst,
    input inst_mem_resp, //both mem_resp signals are unused for CP1 since we expect data ready in 1 cycle always from magic mem
	input data_mem_resp,
    input rv32i_word inst_mem_rdata,
	input rv32i_word data_mem_rdata,
	output logic inst_mem_read,
    output logic data_mem_read,
    output logic data_mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word inst_mem_address,
	output rv32i_word data_mem_address,
    output rv32i_word data_mem_wdata
);



// Internal Signals

// Outputs of IF/ID Stage
rv32i_word pc_if_id;
rv32i_word instruction_if_id;
instruction_decoded_t instruction_decoded; //from instruction_decoder

// Outputs of Regfile
rv32i_word rs1_out;
rv32i_word rs2_out;

// Output of Control ROM
rv32i_control_word control_word;

rv32i_word pc_out;
rv32i_word pcmux_out;

// Outputs of ID/EX Stage
rv32i_control_word control_word_id_ex;
rv32i_word rs1_out_id_ex;
rv32i_word rs2_out_id_ex;
rv32i_word pc_id_ex;
rv32i_word instruction_id_ex;
instruction_decoded_t instruction_decoded_id_ex;

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
instruction_decoded_t instruction_decoded_ex_mem;
rv32i_word alu_out_ex_mem;
logic br_en_ex_mem;
logic [31:0] br_en_extended; //zero-extend

rv32i_word mem_data_out; //from Data Cache

// Outputs of MEM/WB Stage
rv32i_control_word control_word_mem_wb;
rv32i_word pc_mem_wb;
rv32i_word instruction_mem_wb;
instruction_decoded_t instruction_decoded_mem_wb;
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


// signals for loading bytes/halves
rv32i_word lb;
rv32i_word lbu;
rv32i_word lh;
rv32i_word lhu;

// signals for storing bytes/halves
rv32i_word data_out_b;
rv32i_word data_out_h;

logic [3:0] data_out_mask_b;
logic [3:0] data_out_mask_h;

// Connect outputs
assign inst_mem_read = 1'b1; //always read next instruction for CP1 (no hazards)
assign data_mem_read = control_word_ex_mem.data_mem_read;
assign data_mem_write = control_word_ex_mem.data_mem_write;
assign inst_mem_address = pc_out;
assign data_mem_address = {alu_out_ex_mem[31:2], 2'b0}; //align to 4-byte

// signals for forwarding/hazard module
rs1mux::rs1mux_sel_t rs1mux_sel;
rs2mux::rs2mux_sel_t rs2mux_sel;
rv32i_word ex_mem_forwarded_out;
rv32i_word mem_wb_forwarded_out;
rv32i_word rs1mux_out;
rv32i_word rs2mux_out;

rv32i_word lb_ex_mem;
rv32i_word lbu_ex_mem;
rv32i_word lh_ex_mem;
rv32i_word lhu_ex_mem;

assign mem_wb_forwarded_out = regfilemux_out; // this double name is unnecessary but it helps somewhat with keeping track of signals

// stall signals
logic stall_pc;
logic stall_if_id;
logic stall_id_ex;
logic stall_ex_mem;
logic stall_mem_wb;
logic bubble_control;

// Instantiate pipeline stage registers

if_id_regs if_id_regs(
	.clk(clk),
    .rst(rst),
    .load(~stall_if_id),
    .pc_i(pc_out),
	.instruction_i(inst_mem_rdata),
    .pc_o(pc_if_id),
	.instruction_o(instruction_if_id)
);

id_ex_regs id_ex_regs(
	.clk(clk),
    .rst(rst),
    .load(~stall_id_ex),
    .pc_i(pc_if_id),
	.instruction_i(instruction_if_id),
	.instruction_decoded_i(instruction_decoded),
	.control_word_i(control_word),
	.rs1_out_i(rs1_out),
	.rs2_out_i(rs2_out),
	.bubble_control(bubble_control),
    .pc_o(pc_id_ex),
	.instruction_o(instruction_id_ex),
	.instruction_decoded_o(instruction_decoded_id_ex),
	.control_word_o(control_word_id_ex),
	.rs1_out_o(rs1_out_id_ex),
	.rs2_out_o(rs2_out_id_ex)
);

ex_mem_regs ex_mem_regs(
	.clk(clk),
    .rst(rst),
    .load(~stall_ex_mem),
    .pc_i(pc_id_ex),
	.instruction_i(instruction_id_ex),
	.instruction_decoded_i(instruction_decoded_id_ex),
	.control_word_i(control_word_id_ex),
	.rs2_out_i(rs2mux_out),
	.alu_out_i(alu_out),
	.br_en_i(br_en),
    .pc_o(pc_ex_mem),
	.instruction_o(instruction_ex_mem),
	.instruction_decoded_o(instruction_decoded_ex_mem),
	.control_word_o(control_word_ex_mem),
	.rs2_out_o(rs2_out_ex_mem),
	.alu_out_o(alu_out_ex_mem),
	.br_en_o(br_en_ex_mem)
);

mem_wb_regs mem_wb_regs(
	.clk(clk),
    .rst(rst),
    .load(~stall_mem_wb),
    .pc_i(pc_ex_mem),
	.instruction_i(instruction_ex_mem),
	.instruction_decoded_i(instruction_decoded_ex_mem),
	.control_word_i(control_word_ex_mem),
	.alu_out_i(alu_out_ex_mem),
	.br_en_i(br_en_extended),
	.mem_data_out_i(data_mem_rdata),
    .pc_o(pc_mem_wb),
	.instruction_o(instruction_mem_wb),
	.instruction_decoded_o(instruction_decoded_mem_wb),
	.control_word_o(control_word_mem_wb),
	.alu_out_o(alu_out_mem_wb),
	.br_en_o(br_en_mem_wb),
	.mem_data_out_o(mem_data_out_mem_wb)
);


// other modules

pc_register PC(
    .clk  (clk),
    .rst (rst),
    .load (~stall_pc),
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

cmp cmp(
	.cmpop(control_word_id_ex.cmpop),
	.a(rs1mux_out),
	.b(cmpmux_out),
	.br_en(br_en)
);

alu alu(
	.aluop(control_word_id_ex.aluop),
    .a(alumux1_out),
	.b(alumux2_out),
    .f(alu_out)
);

// Forwarding/Hazard Module
forward_hazard forward_hazard_module(

	// inputs for forwarding
	.rs1_id_ex(instruction_decoded_id_ex.rs1),
	.rs2_id_ex(instruction_decoded_id_ex.rs2),
	.rd_ex_mem(instruction_decoded_ex_mem.rd),
	.rd_mem_wb(instruction_decoded_mem_wb.rd),
	.load_regfile_ex_mem(control_word_ex_mem.load_regfile),
	.load_regfile_mem_wb(control_word_mem_wb.load_regfile),
	
	// inputs for hazard detection
	.rd_id_ex(instruction_decoded_id_ex.rd),
	.rs1_if_id(instruction_decoded.rs1),
	.rs2_if_id(instruction_decoded.rs2),
	.inst_mem_resp(inst_mem_resp),
	.data_mem_resp(data_mem_resp),
	.inst_mem_read(inst_mem_read),
	.data_mem_read(data_mem_read),
	.data_mem_write(data_mem_write),
	
	// outputs for forwarding
	.rs1mux_sel(rs1mux_sel),
	.rs2mux_sel(rs2mux_sel),
	
	// outputs for hazard detection (stalling)
	.stall_pc(stall_pc),
	.stall_if_id(stall_if_id),
	.stall_id_ex(stall_id_ex),
	.stall_ex_mem(stall_ex_mem),
	.stall_mem_wb(stall_mem_wb),
	.bubble_control(bubble_control)
);

// Mux Selects
always_comb begin

	//logic for pcmux_sel
	if ((br_en && control_word_id_ex.opcode == op_br) || control_word_id_ex.opcode == op_jal) begin
		pcmux_sel = pcmux::alu_out;
	end
	else if (control_word_id_ex.opcode == op_jalr) begin
		pcmux_sel = pcmux::alu_mod2;
	end
	else pcmux_sel = pcmux::pc_plus4;


	/*
	if(br_en) begin
		if(control_word_id_ex.opcode == op_br || control_word_id_ex.opcode == op_jal) begin
			pcmux_sel = pcmux::alu_out;
		end
		else if (control_word_id_ex.opcode == op_jalr) begin
			pcmux_sel = pcmux::alu_mod2;
		end
		else pcmux_sel = pcmux::pc_plus4;
	end
	else pcmux_sel = pcmux::pc_plus4;*/
	
	
	// ALU Mux Selects
	alumux1_sel = control_word_id_ex.alumux1_sel;
	alumux2_sel = control_word_id_ex.alumux2_sel;
	
	// Regfile Mux Select
	regfilemux_sel = control_word_mem_wb.regfilemux_sel;
	
	// CMP Mux Select
	cmpmux_sel = control_word_id_ex.cmpmux_sel;
	
	//zero extend br_en
	br_en_extended = {31'b0, br_en_ex_mem};

end



/******************************** Muxes **************************************/
always_comb begin : MUXES
	
	
	// logic for regfilemux inputs
	case ( alu_out_mem_wb[1:0] )
	
		2'b00: begin
			lb = { {24{mem_data_out_mem_wb[7]}}, mem_data_out_mem_wb[7:0] };
			lbu = { 24'b0, mem_data_out_mem_wb[7:0] };
			lh = { {16{mem_data_out_mem_wb[15]}}, mem_data_out_mem_wb[15:0] };
			lhu = { 16'b0, mem_data_out_mem_wb[15:0] };
			
			
		end
		
		2'b01: begin
			lb = { {24{mem_data_out_mem_wb[15]}}, mem_data_out_mem_wb[15:8] };
			lbu = { 24'b0, mem_data_out_mem_wb[15:8] };
			lh = { {16{mem_data_out_mem_wb[15]}}, mem_data_out_mem_wb[23:8] }; // this is probably undefined for half word
			lhu = { 16'b0, mem_data_out_mem_wb[23:8] };
			
			
		end
		
		2'b10: begin 
			lb = { {24{mem_data_out_mem_wb[23]}}, mem_data_out_mem_wb[23:16] };
			lbu = { 24'b0, mem_data_out_mem_wb[23:16] };
			lh = { {16{mem_data_out_mem_wb[31]}}, mem_data_out_mem_wb[31:16] };
			lhu = { 16'b0, mem_data_out_mem_wb[31:16] };
			
			
		end
		
		2'b11: begin
			lb = { {24{mem_data_out_mem_wb[31]}}, mem_data_out_mem_wb[31:24] };
			lbu = { 24'b0, mem_data_out_mem_wb[31:24] };
			lh = { {16{mem_data_out_mem_wb[31]}}, mem_data_out_mem_wb[31:16] };
			lhu = { 16'b0, mem_data_out_mem_wb[31:16] };
		end
	endcase
	
	// Mux for setting data out (to memory) and mem_byte_enable masks, for storing/loading bytes or halves
	case ( alu_out_ex_mem[1:0]) // alu_out will hold memory address
	
		2'b00: begin
			data_out_b = { 24'b0, rs2_out_ex_mem[7:0] };
			data_out_h = { 16'b0, rs2_out_ex_mem[15:0] };
			
			data_out_mask_b = 4'b0001;
			data_out_mask_h = 4'b0011;
		end
		
		2'b01: begin
			data_out_b = { 16'b0, rs2_out_ex_mem[7:0], 8'b0 };
			data_out_h = { 8'b0, rs2_out_ex_mem[15:0], 8'b0 }; // this is probably undefined for half word
			
			data_out_mask_b = 4'b0010;
			data_out_mask_h = 4'b0011;
		end
		
		2'b10: begin 
			data_out_b = { 8'b0, rs2_out_ex_mem[7:0], 16'b0 };
			data_out_h = { rs2_out_ex_mem[15:0], 16'b0 };
			
			data_out_mask_b = 4'b0100;
			data_out_mask_h = 4'b1100;
		end
		
		2'b11: begin
			data_out_b = { rs2_out_ex_mem[7:0], 24'b0 };
			data_out_h = { rs2_out_ex_mem[15:0], 16'b0 };
			
			data_out_mask_b = 4'b1000;
			data_out_mask_h = 4'b1100;
		end
	endcase
	
	
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
		pcmux::alu_out: pcmux_out = alu_out;
		pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
        default: `BAD_MUX_SEL;
    endcase
	
	// alumux1
	unique case (alumux1_sel)
		alumux::rs1_out: alumux1_out = rs1mux_out;
		alumux::pc_out: alumux1_out = pc_id_ex;
		default: `BAD_MUX_SEL;
	endcase
	
	// alumux2
	unique case (alumux2_sel)
		alumux::i_imm: alumux2_out = instruction_decoded_id_ex.i_imm;
		alumux::u_imm: alumux2_out = instruction_decoded_id_ex.u_imm;
		alumux::b_imm: alumux2_out = instruction_decoded_id_ex.b_imm;
		alumux::s_imm: alumux2_out = instruction_decoded_id_ex.s_imm;
		alumux::j_imm: alumux2_out = instruction_decoded_id_ex.j_imm;
		alumux::rs2_out: alumux2_out = rs2mux_out;
		default: `BAD_MUX_SEL;
	endcase
	
	// cmpmux
	unique case (cmpmux_sel)
		cmpmux::rs2_out: cmpmux_out = rs2_out_id_ex;
		cmpmux::i_imm: cmpmux_out = instruction_decoded_id_ex.i_imm;
		default: `BAD_MUX_SEL;
	endcase
	
	// regfilemux
	unique case (regfilemux_sel)
		regfilemux::alu_out: regfilemux_out = alu_out_mem_wb;
		regfilemux::br_en: regfilemux_out = br_en_mem_wb;
		regfilemux::u_imm: regfilemux_out = instruction_decoded_mem_wb.u_imm;
		regfilemux::lw: regfilemux_out = mem_data_out_mem_wb;
		regfilemux::pc_plus4: regfilemux_out = pc_mem_wb + 4;
		regfilemux::lb: regfilemux_out = lb;
		regfilemux::lbu: regfilemux_out = lbu;
		regfilemux::lh: regfilemux_out = lh;
		regfilemux::lhu: regfilemux_out = lhu;
		default: `BAD_MUX_SEL;
	endcase
	
	// set data being sent to memory (data cache)
	case (instruction_decoded_ex_mem.funct3)
		sb: begin
			data_mem_wdata = data_out_b;
			mem_byte_enable = data_out_mask_b;
		end	
		
		sh: begin
			data_mem_wdata = data_out_h;
			mem_byte_enable = data_out_mask_h;
		end
		
		sw: begin
			data_mem_wdata = rs2_out_ex_mem;
			mem_byte_enable = 4'b1111;
		end
		
		default: begin
			data_mem_wdata = rs2_out_ex_mem;
			mem_byte_enable = 4'b1111;
		end
		
	endcase
	
	/******* Muxes for Forwarding/Hazard Below ***********/
	
	// logic for regfilemux (ex/mem) inputs
	// TODO Not entirely sure that data_mem_rdata is the correct value to use
	case ( alu_out_ex_mem[1:0] )
	
		2'b00: begin
			lb_ex_mem = { {24{data_mem_rdata[7]}}, data_mem_rdata[7:0] };
			lbu_ex_mem = { 24'b0, data_mem_rdata[7:0] };
			lh_ex_mem = { {16{data_mem_rdata[15]}}, data_mem_rdata[15:0] };
			lhu_ex_mem = { 16'b0, data_mem_rdata[15:0] };
			
			
		end
		
		2'b01: begin
			lb_ex_mem = { {24{data_mem_rdata[15]}}, data_mem_rdata[15:8] };
			lbu_ex_mem = { 24'b0, data_mem_rdata[15:8] };
			lh_ex_mem = { {16{data_mem_rdata[15]}}, data_mem_rdata[23:8] }; // this is probably undefined for half word
			lhu_ex_mem = { 16'b0, data_mem_rdata[23:8] };
			
			
		end
		
		2'b10: begin 
			lb_ex_mem = { {24{data_mem_rdata[23]}}, data_mem_rdata[23:16] };
			lbu_ex_mem = { 24'b0, data_mem_rdata[23:16] };
			lh_ex_mem = { {16{data_mem_rdata[31]}}, data_mem_rdata[31:16] };
			lhu_ex_mem = { 16'b0, data_mem_rdata[31:16] };
			
			
		end
		
		2'b11: begin
			lb_ex_mem = { {24{data_mem_rdata[31]}}, data_mem_rdata[31:24] };
			lbu_ex_mem = { 24'b0, data_mem_rdata[31:24] };
			lh_ex_mem = { {16{data_mem_rdata[31]}}, data_mem_rdata[31:16] };
			lhu_ex_mem = { 16'b0, data_mem_rdata[31:16] };
		end
	endcase
	
	// regfilemux on output of EX/MEM Stage
	unique case (control_word_ex_mem.regfilemux_sel)
		regfilemux::alu_out: ex_mem_forwarded_out = alu_out_ex_mem;
		regfilemux::br_en: ex_mem_forwarded_out = br_en_ex_mem;
		regfilemux::u_imm: ex_mem_forwarded_out = instruction_decoded_ex_mem.u_imm;
		regfilemux::lw: ex_mem_forwarded_out = data_mem_rdata;
		regfilemux::pc_plus4: ex_mem_forwarded_out = pc_ex_mem + 4;
		regfilemux::lb: ex_mem_forwarded_out = lb_ex_mem;
		regfilemux::lbu: ex_mem_forwarded_out = lbu_ex_mem;
		regfilemux::lh: ex_mem_forwarded_out = lh_ex_mem;
		regfilemux::lhu: ex_mem_forwarded_out = lhu_ex_mem;
		default: `BAD_MUX_SEL;
	endcase
	
	// rs1mux
	unique case (rs1mux_sel)
		rs1mux::rs1_out: rs1mux_out = rs1_out_id_ex;
		rs1mux::ex_mem_forwarded: rs1mux_out = ex_mem_forwarded_out;
		rs1mux::mem_wb_forwarded: rs1mux_out = mem_wb_forwarded_out; // same as regfilemux_out
	endcase
	
	// rs2mux
	unique case (rs2mux_sel)
		rs2mux::rs2_out: rs2mux_out = rs2_out_id_ex;
		rs2mux::ex_mem_forwarded: rs2mux_out = ex_mem_forwarded_out;
		rs2mux::mem_wb_forwarded: rs2mux_out = mem_wb_forwarded_out; // same as regfilemux_out
	endcase
	
	
	
	
	
end





endmodule : datapath