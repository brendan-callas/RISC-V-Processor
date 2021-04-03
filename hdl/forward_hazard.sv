import rv32i_types::*;

module forward_hazard(
	
	// inputs for forwarding
	input rv32i_word rs1_id_ex, // register inputs here are indexes of the register (not the data in the register)
	input rv32i_word rs2_id_ex,
	input rv32i_word rd_ex_mem,
	input rv32i_word rd_mem_wb,
	input logic load_regfile_ex_mem,
	input logic load_regfile_mem_wb,
	
	// inputs for hazard detection
	input logic inst_mem_resp,
	input logic data_mem_resp,
	input logic inst_mem_read,
	input logic data_mem_read,
	input logic data_mem_write,
	
	// outputs for forwarding
	output rs1mux_sel_t rs1mux_sel,
	output rs2mux_sel_t rs2mux_sel,
	
	// outputs for hazard detection (stalling)
	
	// Comments below are preliminary descriptions
	output logic stall_pc, // don't load pc reg
	output logic stall_if_id, // don't load IF/ID stage registers
	output logic stall_id_ex, // override control word outputs with 0 (don't erase data in registers; just use a mux to output 0s instead of values, aka make a bubble)
	output logic stall_ex_mem, // don't load EX/MEM registers. Still want to assert mem_read/mem_write (if stalling due to a cache miss)
	output logic stall_mem_wb // don't load MEM/WB registers (except mem_data_out??). Probably don't load_regfile, although this probably doesn't actually make a difference
	

);

always_comb begin

	/********* forwarding for rs1mux *********/

	// the if/else flow here is so that if there is a dependency with both stages, the most recent value will be used

	/* we are checking:
	* if we load the regfile in a previous instruction
	* if that register is NOT R0
	* if the register being loaded is the same as the one being used in the "current" stage (current is ID/EX).
	*/

	// forward from EX/MEM
	if ( (load_regfile_ex_mem == 1'b1) && (rd_ex_mem != 32'b0) && (rd_ex_mem == rs1_id_ex)) begin
		rs1mux_sel = rs1mux::ex_mem_forwarded_out;
	end
	// forward from MEM/WB
	else if ( (load_regfile_mem_wb == 1'b1) && (rd_mem_wb != 32'b0) && (rd_mem_wb == rs1_id_ex)) begin
		rs1mux_sel = rs1mux::mem_wb_forwarded;
	end
	
	/********* forwarding for rs1mux *********/

	// forward from EX/MEM
	if ( (load_regfile_ex_mem == 1'b1) && (rd_ex_mem != 32'b0) && (rd_ex_mem == rs2_id_ex)) begin
		rs2mux_sel = rs2mux::ex_mem_forwarded_out;
	end
	// forward from MEM/WB
	else if ( (load_regfile_mem_wb == 1'b1) && (rd_mem_wb != 32'b0) && (rd_mem_wb == rs2_id_ex)) begin
		rs2mux_sel = rs2mux::mem_wb_forwarded;
	end
	
	/******** Stalling Logic ***********/
  
	// When we have a cache miss on either instruction or data, we want to stall the pipeline until memory responds
	// If there is a data hazard involving a load, we also want to stall until the data is ready.
	  
	if ( ( (inst_mem_read==1'b1) && (inst_mem_resp==1'b0) ) || ( (data_mem_read==1'b1) && (data_mem_resp==1'b0) ) || ( (data_mem_write==1'b1) && (data_mem_resp==1'b0) ) ) begin
		//stall_everything
		stall_pc = 1'b1;
		stall_if_id = 1'b1;
		stall_id_ex = 1'b1;
		stall_ex_mem = 1'b1;
		stall_mem_wb = 1'b1;
	end
		

	  
	// loading hazards
	// test to see if the instruction is a load
	// check to see if the destination register field of the load in the EX stage matches either source register of the instruction in the ID stage.
	// If the condition holds, the instruction stalls one clock cycle.
	if ( (data_mem_read==1'b1) && ( (rd_id_ex == rs1_if_id) || (rd_id_ex == rs2_if_id) ) ) begin
		stall_pc = 1'b1;
		stall_if_id = 1'b1;
		stall_id_ex = 1'b1;
	end

end






endmodule : forward_hazard