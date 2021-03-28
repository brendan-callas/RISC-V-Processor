module cmp
(
	input branch_funct3_t cmpop,
	input logic [31:0] a,
	input logic [31:0] b,
	output logic br_en

);

// cmp logic
always_comb begin
	unique case (cmpop)
		beq: br_en = (a == b);
		bne: br_en = (a != b);
		blt: br_en = ($signed(a) < $signed(b));
		bge: br_en = ($signed(a) >= $signed(b));
		bltu: br_en = (a[31:0] < b[31:0]); // use bit range to ensure unsigned comparison
		bgeu: br_en = (a[31:0] >= b[31:0]);
		default: ;
		
	endcase

end


endmodule : cmp