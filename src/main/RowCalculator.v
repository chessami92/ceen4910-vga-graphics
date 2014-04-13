`timescale 1ns / 1ps

`define thisAndNextColumn row0[column] + row1[column] + row2[column] + row0[column + 1] + row2[column + 1]

module RowCalculator(
	input clkDiv, rst, noise, drawRequest, reading,
	input [639:0] readRow,
	input displayActive,
	input [8:0] row,
	input [9:0] column,
	output [639:0] drawRow,
	output [639:0] writeRow
	);
	
	reg readPrevious;

	reg [639:0] row0;
	reg [639:0] row1;
	wire [639:0] row2;
	reg [2:0] nextLiveCount;

	reg drawNext, draw;

	wire [15:0] random;
	Random randomGenerator(
		.clk( clkDiv ),
		.rst( rst ),
		.noise( noise ),
		.random( random )
	);

	assign row2 = readRow;
	assign drawRow = row1;
	assign writeRow = row0;

	always @( posedge clkDiv or posedge rst ) begin
		if( rst ) begin
			readPrevious <= 0;
			row0 <= 0;
			row1 <= 0;
			nextLiveCount <= 0;

			drawNext <= 0;
			draw <= 0;
		end else begin
			readPrevious <= reading;
			if( reading && !readPrevious ) begin
				row0 <= row1;
				row1 <= readRow;
			end

			if( displayActive ) begin
				if( column == 638 )
					nextLiveCount <= `thisAndNextColumn + row0[0] + row1[0] + row2[0];
				else
					nextLiveCount <= `thisAndNextColumn + row0[column + 2] + row1[column + 2] + row2[column + 2];
			end else
				nextLiveCount <= row0[639] + row1[639] + row2[639] + row0[0] + row2[0] + row0[1] + row1[1] + row2[1];

			if( displayActive && draw )
				row0[column] <= random[0];
			else if( displayActive ) begin
				case( nextLiveCount )
				2: begin
					if( row1[column] )
						row0[column] <= 1;
					else
						row0[column] <= 0;
				end
				3: row0[column] <= 1;
				default: row0[column] <= 0;
				endcase
			end

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
