`timescale 1ns / 1ps

module RowCalculator(
	input clkDiv, rst, noise, drawRequest, reading,
	input [639:0] readRow,
	input displayActive,
	input [8:0] row,
	input [9:0] column,
	output [639:0] writeRow
	);
	
	reg readPrevious;

	reg [639:0] row0;
	reg [639:0] row1;

	reg drawNext, draw;

	wire [15:0] random;
	Random randomGenerator(
		.clk( clkDiv ),
		.rst( rst ),
		.noise( noise ),
		.random( random )
	);

	assign writeRow = row1;

	always @( posedge clkDiv or posedge rst ) begin
		if( rst ) begin
			readPrevious <= 0;
			row0 <= 0;
			row1 <= 0;

			drawNext <= 0;
			draw <= 0;
		end else begin
			readPrevious <= reading;
			if( reading && !readPrevious ) begin
				row0 <= row1;
				row1 <= readRow;
			end
			
			if( displayActive && draw )
				row1[column] <= random[0];

			if( drawRequest )
				drawNext <= 1;
			if( drawNext && row == 481 ) begin
				draw <= 1;
				drawNext <= 0;
			end
			if( draw && row == 480 )
				draw <= 0;
		end
	end

endmodule
