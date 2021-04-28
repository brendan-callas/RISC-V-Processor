import rv32i_types::*;

module us_multiplier(
	input clk,
	input rst,
	
	input logic start,
	output logic fin,
	input logic [31:0] multiplier,
	input logic [31:0] multiplicand,
	output logic [63:0] product
	
);

logic [31:0] partial_plier;
logic [31:0] partial_plicand;
logic [63:0] partial_p;
logic [5:0] idx;
logic [5:0] idx2;

enum int unsigned {
    /* List of states */
	idle,
	mult,
	done
	
} state, next_state;

always_comb
begin : state_actions
	
    /* Actions for each state */
	case(state)
		
		idle: begin
			fin = 1'b0;
			idx2 = 6'b100000;
			partial_p = 64'b0;
			partial_plier = multiplier;
			partial_plicand = multiplicand;
		end
		
		mult: begin
		
			fin = 1'b0;
		
			if(partial_plicand[0]) begin
				partial_p = partial_p + partial_plier;
			end else begin
				partial_p = product;
			end
			
			partial_plier = partial_plier << 1;
			partial_plicand = partial_plicand >> 1;
			
			idx2 = idx - 1'b1;
			
		end
		
		done: begin
			idx2 = 6'b100000; //reset intermediate values
			partial_p = 64'b0;
			partial_plier = 32'b0;
			partial_plicand = 32'b0;
			fin = 1'b1;
		end
		
		default: begin
			fin = 1'b0;
			idx2 = 6'b100000;
			partial_p = 64'b0;
			partial_plier = multiplier;
			partial_plicand = multiplicand;
		end
		
	endcase
	
end



always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	 
	 // default
	 next_state = state;
	 
	case(state)
	
		idle: begin
			if(start == 1'b1) begin
				next_state = mult;
			end else begin
				next_state = idle;
			end
		end
		
		mult: begin
			if(idx == 6'b0) begin
				next_state = done;
			end else begin
				next_state = mult;
			end
		end
		
		done: begin
			next_state = idle;
		end
	
	endcase
end



always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	if(rst == 1'b1) begin //reset
		state <= idle;
		product <= 64'b0;
	end else begin //set product to current tmp value
		state <= next_state;
		product <= partial_p;
		idx <= idx2;
	end
end

endmodule



module multiplier(

	input clk,
	input rst,
	
	input mex_funct3_t op,

	input logic start,
	output logic fin,
	input logic [31:0] multiplier,
	input logic [31:0] multiplicand,
	output logic [63:0] product
);

logic [31:0] plier;
logic [31:0] plicand;
logic [63:0] pro;

us_multiplier usm(

	.clk,
	.rst,

	.start,
	.fin,
	.multiplier(plier),
	.multiplicand(plicand),
	.product(pro)

);

always_comb begin

	plier = multiplier;
	plicand = multiplicand;
	product = pro;

	case(op) 
	
		mul: begin
			if(multiplier[31]) begin 
				plier = (~multiplier) + 32'b1; //2's complement
			end else begin
				plier = multiplier;
			end
			
			if(multiplicand[31]) begin 
				plicand = (~multiplicand) + 32'b1; //2's complement
			end else begin
				plicand = multiplicand;
			end
			
			if(multiplier[31] ^ multiplicand[31]) begin 
				product = (~pro) + 32'b1; //2's complement
			end else begin
				product = pro;
			end
			
		end
		
		
		mulh: begin
			if(multiplier[31]) begin 
				plier = (~multiplier) + 32'b1; //2's complement
			end else begin
				plier = multiplier;
			end
			
			if(multiplicand[31]) begin 
				plicand = (~multiplicand) + 32'b1; //2's complement
			end else begin
				plicand = multiplicand;
			end
			
			if(multiplier[31] ^ multiplicand[31]) begin 
				product = (~pro) + 32'b1; //2's complement
			end else begin
				product = pro;
			end
			
		end
		
		
		mulhsu: begin
			if(multiplier[31]) begin 
				plier = (~multiplier) + 32'b1; //2's complement
			end else begin
				plier = multiplier;
			end
			
			if(multiplier[31]) begin 
				product = (~pro) + 32'b1; //2's complement
			end else begin
				product = pro;
			end
		end
		
		
		mulhu: begin
			plier = multiplier;
			plicand = multiplicand;
			product = pro;
		end
		
		
		default: begin //assume unsigned just in case
			plier = multiplier;
			plicand = multiplicand;
			product = pro;
		end
	
	endcase
end

endmodule