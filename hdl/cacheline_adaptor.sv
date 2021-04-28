module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic [3:0][63:0] buffer;
logic [3:0][63:0] buffer_w;
logic [3:0][63:0] buffer_w_in;
logic [1:0] buffer_idx;
logic [1:0] buffer_idx_next;
logic [63:0] burst_o_in;
logic [1:0] buffer_idx_w;
logic [31:0] address;
logic load_buffer;

enum int unsigned {
    /* List of states */
	s_idle,
	s_reading,
	s_writing,
	s_done_reading,
	s_done_writing
	
} state, next_state;

function void set_defaults();
	resp_o = 1'b0;
	address_o = address;
	read_o = 1'b0;
	write_o = 1'b0;
	load_buffer = 1'b0;
	buffer_idx_next = buffer_idx;
	
	buffer_w_in[0] = buffer_w[0];
	buffer_w_in[1] = buffer_w[1];
	buffer_w_in[2] = buffer_w[2];
	buffer_w_in[3] = buffer_w[3];
	
	burst_o_in = burst_o;
endfunction

always_ff  @(posedge clk) begin
	address <= address_i;
end

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
	
	
    /* Actions for each state */
	case(state)
	
		s_idle: begin
			buffer_idx_next = 2'b00;
			
			buffer_w_in[3] = line_i[255:192];
			buffer_w_in[2] = line_i[191:128];
			buffer_w_in[1] = line_i[127:64];
			buffer_w_in[0] = line_i[63:0];
			
			burst_o_in = line_i[63:0];
		end
		
		s_reading: begin
			read_o = 1'b1;
			if(resp_i) begin
				buffer_idx_next = buffer_idx + 2'b01;
				load_buffer = 1'b1;
			end
		end
		
		s_writing: begin
			write_o = 1'b1;
			
			buffer_w_in[3] = line_i[255:192];
			buffer_w_in[2] = line_i[191:128];
			buffer_w_in[1] = line_i[127:64];
			buffer_w_in[0] = line_i[63:0];
			
			if(resp_i) begin
				buffer_idx_next = buffer_idx + 2'b01;
				burst_o_in = buffer_w[buffer_idx + 2'b01];
			end
			
		end
		
		s_done_reading: begin
			resp_o = 1'b1;
		end
		
		s_done_writing: begin
			resp_o = 1'b1;
		end
	endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	 
	 // default
	 next_state = state;
	 
	 if(reset_n == 1'b0) begin
		next_state = s_idle;
	 end
	 
	 else begin
	 
		 case(state)
	
			s_idle: begin
				if (read_i == 1'b1) next_state = s_reading;
				else if (write_i == 1'b1) next_state = s_writing;
			end
			
			s_reading: begin
				if(buffer_idx == 2'b11) next_state = s_done_reading;
			end
			
			s_writing: begin
				if(buffer_idx == 2'b11) next_state = s_done_writing;
			end
			
			s_done_reading: begin
				next_state = s_idle;
			end
			
			s_done_writing: begin
				next_state = s_idle;
			end
		endcase
	 end
end

always_comb begin

	line_o[255:192] = buffer[3];
	line_o[191:128] = buffer[2];
	line_o[127:64] = buffer[1];
	line_o[63:0] = buffer[0];

end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_state;
	buffer_idx <= buffer_idx_next;
	if(load_buffer == 1'b1) buffer[buffer_idx] <= burst_i;
	
	buffer_w[0] <= buffer_w_in[0];
	buffer_w[1] <= buffer_w_in[1];
	buffer_w[2] <= buffer_w_in[2];
	buffer_w[3] <= buffer_w_in[3];
	
	burst_o <= burst_o_in;
end


endmodule : cacheline_adaptor
