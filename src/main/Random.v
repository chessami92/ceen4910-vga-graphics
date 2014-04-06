`timescale 1ns / 1ps

module Random(
	input clk, rst, noise,
	output reg [15:0] random
	);
	
	reg lastNoise;
	
	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			lastNoise <= 0;
			//fullRandom <= 0; // Don't do this except for during testing for more randomness!
		end else begin
			random <= {random[14:0], ( random[10] ^ random[12] ^ random[13] ^ random[15] ) | ( lastNoise ^ noise )};
			lastNoise <= noise;
		end
	end
endmodule
