
module plru
(
    input clk,
    input rst,
    input logic load,
	input logic [2:0] set, // the set idx which is being accessed
    output logic [2:0] plru_idx // the index to replace if evicting
);


logic [7:0] data; //holds bits for bit-pLRU algo
logic [2:0] sum; //sum up the plru bits to know if they are all 1

always_comb begin
	
	// find the index to replace when evicting
	// Every access to a line sets its MRU-bit to 1, indicating that the line was recently used. 
	// Whenever the last remaining 0 bit of a set's status bits is set to 1, all other bits are reset to 0. 
	// At cache misses, the leftmost line whose MRU-bit is 0 is replaced
	
	//get leftmost 0-bit
	if(~data[0])
		plru_idx = 3'd0;
	else if(~data[1])
		plru_idx = 3'd1;
	else if(~data[2])
		plru_idx = 3'd2;
	else if(~data[3])
		plru_idx = 3'd3;
	else if(~data[4])
		plru_idx = 3'd4;
	else if(~data[5])
		plru_idx = 3'd5;
	else if(~data[6])
		plru_idx = 3'd6;
	else if(~data[7])
		plru_idx = 3'd7;
	else plru_idx = 3'd0;
		
	sum = data[0] + data[1] + data[2] + data[3] + data[4] + data[5] + data[6] + data[7];
	
end


always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < 8; ++i)
            data[i] <= '0;
    end
    else begin
        if(load)
            
			if(sum == 3'd6) begin //if all except one have a 1-bit, flip all bits
				data[0] <= ~data[0];
				data[1] <= ~data[1];
				data[2] <= ~data[2];
				data[3] <= ~data[3];
				data[4] <= ~data[4];
				data[5] <= ~data[5];
				data[6] <= ~data[6];
				data[7] <= ~data[7];
			end
			else begin //otherwise, just set the proper index to a 1
				data[set] <= 1'b1;
			end
			
    end
end



endmodule : plru
