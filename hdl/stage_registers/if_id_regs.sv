import rv32i_types::*;

module if_id_regs
(
    input clk,
    input rst,
    input load,
    input logic [31:0] pc_i,
	input rv32i_word instruction_i,
    output logic [31:0] pc_o,
	output rv32i_word instruction_o,
	
	input logic halt_i,
	output logic halt_o
);

// internal registers
logic [31:0] pc;
rv32i_word instruction;

logic halt;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        pc <= '0;
		instruction <= '0;
		halt <= halt_i; //dont squah halt
    end
    else if (load)
    begin
        pc <= pc_i;
		instruction <= instruction_i;
		halt <= halt_i;
    end
    else
    begin
        pc <= pc;
		instruction <= instruction;
		halt <= halt;
    end
end

always_comb
begin
    pc_o = pc;
	instruction_o = instruction;
	halt_o = halt;
end

endmodule : if_id_regs
