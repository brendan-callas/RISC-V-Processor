import rv32i_types::*;

module control_rom
(
	input rv32i_opcode opcode,
	input logic [2:0] funct3,
    input logic [6:0] funct7,
	output rv32i_control_word control_word
    
);

// making these internal signals simply for readability of the code (don't have to put "control_word. in front of everything)
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
alu_ops aluop;
logic load_regfile;
branch_funct3_t cmpop;
logic data_mem_read;
logic data_mem_write;

assign control_word.opcode = opcode;
assign control_word.aluop = aluop;
assign control_word.cmpop = cmpop;
assign control_word.alumux1_sel	= alumux1_sel;
assign control_word.alumux2_sel	= alumux2_sel;
assign control_word.regfilemux_sel = regfilemux_sel;
assign control_word.cmpmux_sel = cmpmux_sel;
assign control_word.load_regfile = load_regfile;
assign control_word.data_mem_read = data_mem_read;
assign control_word.data_mem_write = data_mem_write;

function void set_defaults();
	
	aluop = alu_ops'(funct3);
	cmpop = branch_funct3_t'(funct3);
	alumux1_sel	= alumux::rs1_out;
	alumux2_sel	= alumux::i_imm;
	regfilemux_sel = regfilemux::alu_out;
	cmpmux_sel = cmpmux::rs2_out;
	load_regfile = 1'b0;
	data_mem_read = 1'b0;
	data_mem_write = 1'b0;
	
endfunction

always_comb begin

	set_defaults();

	case(opcode)
				
		op_lui: begin
			load_regfile = 1'b1;
			regfilemux_sel = regfilemux::u_imm;
		end
		
		op_auipc: begin
			alumux1_sel = alumux::pc_out;
			alumux2_sel = alumux::u_imm;
			load_regfile = 1'b1;
			aluop = alu_add;
		end
		
		op_jal: begin
			alumux1_sel = alumux::pc_out;
			alumux2_sel = alumux::j_imm;
			aluop = alu_add;
			regfilemux_sel = regfilemux::pc_plus4;
			load_regfile = 1'b1;
		end
		
		op_jalr: begin
			alumux1_sel = alumux::rs1_out;
			alumux2_sel = alumux::i_imm;
			aluop = alu_add;
			regfilemux_sel = regfilemux::pc_plus4;
			load_regfile = 1'b1;
		end
		
		op_br: begin
			alumux1_sel = alumux::pc_out;
			alumux2_sel = alumux::b_imm;
			aluop = alu_add;
		end
		
		op_load: begin
			data_mem_read = 1'b1;
			aluop = alu_add;
			load_regfile = 1'b1;
			
			case(load_funct3_t'(funct3))
			
				lb: begin
					regfilemux_sel = regfilemux::lb;
				end
				
				lbu: begin
					regfilemux_sel = regfilemux::lbu;
				end
				
				lh: begin
					regfilemux_sel = regfilemux::lh;
				end
				
				lhu: begin
					regfilemux_sel = regfilemux::lhu;
				end
				
				lw: begin
					regfilemux_sel = regfilemux::lw;
				end
				
				default: begin
					regfilemux_sel = regfilemux::lw;
				end
				
			endcase
		end
		
		op_store: begin
			aluop = alu_add;
			data_mem_write = 1'b1;
			alumux2_sel = alumux::s_imm;
		end
		
		op_imm: begin
			load_regfile = 1'b1;
			
			case(funct3)
				slt: begin //SLTI
					cmpop = blt;
					regfilemux_sel = regfilemux::br_en;
					cmpmux_sel = cmpmux::i_imm;
				end
				
				sltu: begin //SLTIU
					cmpop = bltu;
					regfilemux_sel = regfilemux::br_en;
					cmpmux_sel = cmpmux::i_imm;
				end
				
				sr: begin //SRAI
					if(funct7[5] == 1'b1) begin
						aluop = alu_sra;
					end

				end
				
				default: begin
					aluop = alu_ops'(funct3);
				end
				
			endcase
		end
		
		op_reg: begin
			load_regfile = 1'b1;
			alumux1_sel = alumux::rs1_out;
			alumux2_sel = alumux::rs2_out;
			
			case(funct3)
				add: begin
					if(funct7[5] == 1'b1) begin
						aluop = alu_sub;
					end
					else aluop = alu_add;
				end
				
				sr: begin
					if(funct7[5] == 1'b1) begin
						aluop = alu_sra;
					end
					else aluop = alu_srl;
				end
				
				slt: begin
					cmpop = blt;
					regfilemux_sel = regfilemux::br_en;
				end
				
				sltu: begin
					cmpop = bltu;
					regfilemux_sel = regfilemux::br_en;
				end
				
				default:  begin
					aluop = alu_ops'(funct3);
				end
			endcase
			
			if(funct7 == 7'b0000001) begin //if muldiv
				regfilemux_sel = regfilemux::alu_out;
			end
			
		end
		
		op_csr: begin
			// not implemented
		end
				
	endcase

end



endmodule : control_rom