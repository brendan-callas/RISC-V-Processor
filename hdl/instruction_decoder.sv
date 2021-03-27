import rv32i_types::*;

module instruction_decoder
(
    input [31:0] in,
    output instruction_decoded_t out
);

logic [31:0] data;

assign out.funct3 = data[14:12];
assign out.funct7 = data[31:25];
assign out.opcode = rv32i_opcode'(data[6:0]);
assign out.i_imm = {{21{data[31]}}, data[30:20]};
assign out.s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign out.b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign out.u_imm = {data[31:12], 12'h000};
assign out.j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign out.rs1 = data[19:15];
assign out.rs2 = data[24:20];
assign out.rd = data[11:7];


always_comb
begin
    data = in;
end

endmodule : instruction_decoder
