module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

// assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = (rvfi.pc_wdata == rvfi.pc_rdata) && rvfi.commit;   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

logic [31:0] ex_mem_rs1_rdata;
logic [31:0] ex_mem_rs2_rdata;
logic [31:0] mem_wb_rs1_rdata;
logic [31:0] mem_wb_rs2_rdata;
logic [31:0] mem_wb_pc_wdata;
logic [31:0] mem_wb_mem_addr;
logic [3:0] mem_wb_mem_wmask;
logic [3:0] mem_wb_mem_rmask;
logic [31:0] mem_wb_mem_wdata;
logic [31:0] mem_wb_mem_rdata;

logic stall_pc;

assign stall_pc = dut.datapath.stall_pc;
always_ff @(posedge itf.clk) begin
      if (~stall_pc) begin
            ex_mem_rs1_rdata <= dut.datapath.rs1mux_out;
            mem_wb_rs1_rdata <= dut.datapath.rs1mux_out;
            mem_wb_rs2_rdata <= dut.datapath.wdatamux_out;
            mem_wb_mem_addr <= dut.data_addr;
            mem_wb_mem_wdata <= dut.data_wdata;
            mem_wb_mem_rdata <= dut.data_rdata;
			if (dut.datapath.control_word_ex_mem.data_mem_read) begin
				mem_wb_mem_rmask <= dut.data_mbe;
			end
			else mem_wb_mem_rmask <= '0;
			
			if (dut.datapath.control_word_ex_mem.data_mem_write) begin
				mem_wb_mem_wmask <= dut.data_mbe;
			end
			else mem_wb_mem_wmask <= '0;
			
      end
end

always_comb begin // rvfi signals
      
      rvfi.inst = dut.datapath.instruction_mem_wb;
      rvfi.trap = 1'b0;
      rvfi.rs1_addr = dut.datapath.instruction_decoded_mem_wb.rs1;
      rvfi.rs2_addr = dut.datapath.instruction_decoded_mem_wb.rs2;
      rvfi.rs1_rdata = mem_wb_rs1_rdata;
      rvfi.rs2_rdata = mem_wb_rs2_rdata;
      rvfi.load_regfile = dut.datapath.control_word_mem_wb.load_regfile;
      rvfi.rd_addr = dut.datapath.instruction_decoded_mem_wb.rd;
      rvfi.rd_wdata = dut.datapath.regfile.in;
      rvfi.pc_rdata = dut.datapath.pc_mem_wb;
      rvfi.pc_wdata = 32'hxxxx;
      rvfi.mem_addr = mem_wb_mem_addr;
      rvfi.mem_rmask = mem_wb_mem_rmask;
      rvfi.mem_wmask = mem_wb_mem_wmask;
      rvfi.mem_rdata = mem_wb_mem_rdata;
      rvfi.mem_wdata = mem_wb_mem_wdata;
	  if (dut.datapath.instruction_decoded_mem_wb.opcode) begin
            rvfi.commit = (~(dut.datapath.stall_mem_wb));
      end else rvfi.commit = 1'b0;

//     logic [15:0] errcode;
end

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

	/* I Cache Ports */
    assign itf.inst_read = dut.inst_read;
    assign itf.inst_addr = dut.inst_addr;
    assign itf.inst_resp = dut.inst_resp;
    assign itf.inst_rdata = dut.inst_rdata;

    /* D Cache Ports */
	assign itf.data_read = dut.data_read;
	assign itf.data_write = dut.data_write;
	assign itf.data_mbe = dut.data_mbe;
	assign itf.data_addr = dut.data_addr;
	assign itf.data_wdata = dut.data_wdata;
	assign itf.data_resp = dut.data_resp;
	assign itf.data_rdata = dut.data_rdata;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.datapath.regfile.data; //'{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(

	.clk(itf.clk),
	.rst(itf.rst),
	
	
	
	.pmem_resp(itf.mem_resp),
	.pmem_rdata(itf.mem_rdata),
	
	.pmem_read(itf.mem_read),
	.pmem_write(itf.mem_write),
	.pmem_address(itf.mem_addr),
	.pmem_wdata(itf.mem_wdata)
	
	

);
/***************************** End Instantiation *****************************/

endmodule
