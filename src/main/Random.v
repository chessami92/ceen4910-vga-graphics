`timescale 1ns / 1ps

module Random(
	input clk, rst, noise,
	output reg [7:0] random
	);
	
	reg lastNoise;
	
	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			lastNoise <= 0;
			random <= 0;
		end else begin
			random <= {random[6:0], ( random[3] ^ random[4] ^ random[5] ^ random[7] ) | ( lastNoise ^ noise )};
			lastNoise <= noise;
		end
	end
endmodule
