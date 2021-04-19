//import rv32i_types::*;

module forward_hazard(
	
	// inputs for forwarding
	input logic [4:0] rs1_id_ex, // register inputs here are indexes of the register (not the data in the register)
	input logic [4:0] rs2_id_ex,
	input logic [4:0] rs2_ex_mem,
	input logic [4:0] rd_ex_mem,
	input logic [4:0] rd_mem_wb,
	input logic load_regfile_ex_mem,
	input logic load_regfile_mem_wb,
	input logic mem_write_ex_mem,
	
	// inputs for hazard detection
	input logic [4:0] rd_id_ex,
	input logic [4:0] rs1_if_id,
	input logic [4:0] rs2_if_id,
	input logic mem_read_id_ex,
	input logic inst_mem_resp,
	input logic data_mem_resp,
	input logic inst_mem_read,
	input logic data_mem_read,
	input logic data_mem_write,
	input logic mem_write_if_id,
	
	
	
	// outputs for forwarding
	output rs1mux::rs1mux_sel_t rs1mux_sel,
	output rs2mux::rs2mux_sel_t rs2mux_sel,
	output wdatamux::wdatamux_sel_t wdatamux_sel,
	
	// outputs for hazard detection (stalling)
	
	// Comments below are preliminary descriptions
	output logic stall_pc, // don't load pc reg
	output logic stall_if_id, // don't load IF/ID stage registers
	output logic stall_id_ex, // don't load registers
	output logic stall_ex_mem, // don't load EX/MEM registers. Still want to assert mem_read/mem_write (if stalling due to a cache miss)
	output logic stall_mem_wb, // don't load MEM/WB registers . Probably set load_regfile=0, although this probably doesn't actually make a difference
	output logic bubble_control // override control word with 0s (make a bubble)
	

);

function void set_defaults();
	
	rs1mux_sel = rs1mux::rs1_out;
	rs2mux_sel = rs2mux::rs2_out;
	wdatamux_sel = wdatamux::rs2_out;
	stall_pc = 1'b0;
	stall_if_id = 1'b0;
	stall_id_ex = 1'b0;
	stall_ex_mem = 1'b0;
	stall_mem_wb = 1'b0;
	bubble_control = 1'b0;
	
endfunction

always_comb begin

	set_defaults(); 

	/********* forwarding for rs1mux *********/

	// the if/else flow here is so that if there is a dependency with both stages, the most recent value will be used

	/* we are checking:
	* if we load the regfile in a previous instruction
	* if that register is NOT R0
	* if the register being loaded is the same as the one being used in the "current" stage (current is ID/EX).
	*/

	// forward from EX/MEM
	if ( (load_regfile_ex_mem == 1'b1) && (rd_ex_mem != 5'b0) && (rd_ex_mem == rs1_id_ex)) begin
		rs1mux_sel = rs1mux::ex_mem_forwarded;
	end
	// forward from MEM/WB
	else if ( (load_regfile_mem_wb == 1'b1) && (rd_mem_wb != 5'b0) && (rd_mem_wb == rs1_id_ex)) begin
		rs1mux_sel = rs1mux::mem_wb_forwarded;
	end
	
	/********* forwarding for rs2mux *********/

	// forward from EX/MEM
	if ( (load_regfile_ex_mem == 1'b1) && (rd_ex_mem != 5'b0) && (rd_ex_mem == rs2_id_ex)) begin
		rs2mux_sel = rs2mux::ex_mem_forwarded;
	end
	// forward from MEM/WB
	else if ( (load_regfile_mem_wb == 1'b1) && (rd_mem_wb != 5'b0) && (rd_mem_wb == rs2_id_ex)) begin
		rs2mux_sel = rs2mux::mem_wb_forwarded;
	end
	
	// forwarding for wdatamux
	// related to  loading hazards
	if ( (mem_write_ex_mem == 1'b1) && (rd_mem_wb == rs2_ex_mem) && (rd_mem_wb != 5'b0) && (load_regfile_mem_wb == 1'b1) ) begin
		wdatamux_sel = wdatamux::mem_wb_forwarded;
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
	// Don't bubble if we have a store-after-load
	if ( (mem_read_id_ex==1'b1) && ( (rd_id_ex == rs1_if_id) || (rd_id_ex == rs2_if_id) ) && (mem_write_if_id == 1'b0) ) begin // 
		stall_pc = 1'b1;
		stall_if_id = 1'b1;
		bubble_control = 1'b1;
	end

end






endmodule : forward_hazard