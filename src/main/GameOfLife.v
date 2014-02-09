`timescale 1ns / 1ps

module GameOfLife(
	input clk, rst, displayActive, noise,
	input [8:0] row,
	input [9:0] column,
	output wire [2:0] color
	);

	reg [3:0] memory[639:0];
	reg [3:0] memoryRead;
	reg displayActiveOld;

	reg [9:0] columnIndex;
	reg draw;

	wire [15:0] random;
	Random randomGenerator(
		.clk( clk ),
		.rst( rst ),
		.noise( noise ),
		.random( random )
	);
	
	assign color = displayActiveOld ? memoryRead[2:0] : 0;
	
	always @( negedge clk or posedge rst ) begin
		if( rst ) begin
			draw <= 0;
			columnIndex <= 0;
		end
		else begin
			displayActiveOld <= displayActive;
			if( displayActive ) memoryRead <= memory[column];
			if( !draw ) begin
				memory[columnIndex] <= random[3:0];
				columnIndex <= columnIndex + 1;
				if( columnIndex == 640 - 1 ) draw <= 1;
			end
		end
	end
endmodule
