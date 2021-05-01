/* A special register array specifically for your
data arrays. This module supports a write mask to
help you update the values in the array. */

module l2_data_array #(
    parameter s_offset = 5,
    parameter s_index = 3
)
(
    clk,
    rst,
    read,
    write_en,
    rindex,
    windex,
    datain,
    dataout
);

localparam s_mask   = 2**s_offset;
localparam s_line   = 8*s_mask;
localparam num_sets = 2**s_index;

input clk;
input rst;
input read;
input [s_mask-1:0] write_en;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [s_line-1:0] datain;
output logic [s_line-1:0] dataout;
/*
logic [s_line-1:0] data [num_sets-1:0] //synthesis ramstyle = "logic" ;
logic [s_line-1:0] _dataout;
*/
//assign dataout = _dataout;
/*
always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i)
            data[i] <= '0;
    end
    else begin
        if (read)
            for (int i = 0; i < s_mask; i++)
                _dataout[8*i +: 8] <= (write_en[i] & (rindex == windex)) ?
                                      datain[8*i +: 8] : data[rindex][8*i +: 8];

        for (int i = 0; i < s_mask; i++)
        begin
            data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] :
                                                    data[windex][8*i +: 8];
        end
    end
end
*/
genvar i;
generate
    for (i=0; i<=31; i=i+1) begin : generate_block_identifier // <-- example block name
		bram row(
			.address(rindex),
			.inclock(clk),
			.data(datain[(i+1)*8 - 1 : i*8]),
			.wren(write_en[i]),
			.rden(1'b1),
			.q(dataout[(i+1)*8 - 1 : i*8])
		);
end 
endgenerate
/*
bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row1(
	.address(rindex),
	.clock(clk),
	.data(datain[15:8]),
	.wren(write_en[1]),
	.q(dataout[15:8])
);

bram row2(
	.address(rindex),
	.clock(clk),
	.data(datain[23:16]),
	.wren(write_en[2]),
	.q(dataout[23:16])
);

bram row3(
	.address(rindex),
	.clock(clk),
	.data(datain[31:24]),
	.wren(write_en[3]),
	.q(dataout[31:24])
);

bram row4(
	.address(rindex),
	.clock(clk),
	.data(datain[39:32]),
	.wren(write_en[4]),
	.q(dataout[39:32])
);

bram row5(
	.address(rindex),
	.clock(clk),
	.data(datain[47:40]),
	.wren(write_en[5]),
	.q(dataout[47:40])
);

bram row6(
	.address(rindex),
	.clock(clk),
	.data(datain[55:48]),
	.wren(write_en[6]),
	.q(dataout[55:48])
);

bram row7(
	.address(rindex),
	.clock(clk),
	.data(datain[63:56]),
	.wren(write_en[7]),
	.q(dataout[63:56])
);

bram row8(
	.address(rindex),
	.clock(clk),
	.data(datain[71:64]),
	.wren(write_en[8]),
	.q(dataout[71:64])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);

bram row0(
	.address(rindex),
	.clock(clk),
	.data(datain[7:0]),
	.wren(write_en[0]),
	.q(dataout[7:0])
);
*/
endmodule : l2_data_array
