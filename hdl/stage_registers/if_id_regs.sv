import rv32i_types::*;

module if_id_regs
(
    input clk,
    input rst,
    input load,
    input logic [31:0] pc_i,
	input rv32i_word instruction_i,
    output logic [31:0] pc_o,
	output rv32i_word instruction_o
);

// internal registers
logic [31:0] pc;
rv32i_word instruction;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        pc <= '0;
		instruction <= '0;
    end
    else if (load)
    begin
        pc <= pc_i;
		instruction <= instruction_i;
    end
    else
    begin
        pc <= pc;
		instruction <= instruction;
    end
end

always_comb
begin
    pc_o = pc;
	instruction_o = instruction;
end

endmodule : if_id_regs
