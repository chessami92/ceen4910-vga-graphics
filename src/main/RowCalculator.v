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
	reg [2:0] leftColumn, centerColumn, rightColumn, nextLiveCount;

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
			leftColumn <= 0;
			rightColumn <= 0;
			nextLiveCount <= 0;

			drawNext <= 0;
			draw <= 0;
		end else begin
			readPrevious <= reading;
			if( reading && !readPrevious ) begin
				row0 <= row1;
				row1 <= readRow;
			end

			leftColumn <= centerColumn;
			centerColumn <= rightColumn;
			if( column == 637 ) begin
				rightColumn[0] <= row0[0];
				rightColumn[1] <= row1[0];
				rightColumn[2] <= row2[0];
			end else if( column == 797 ) begin
				rightColumn[0] <= row0[0];
				rightColumn[1] <= row1[0];
				rightColumn[2] <= row2[0];
			end else if( column == 798 ) begin
				rightColumn[0] <= row0[1];
				rightColumn[1] <= row1[1];
				rightColumn[2] <= row2[1];
			end else if( column == 799 ) begin
				rightColumn[0] <= row0[2];
				rightColumn[1] <= row1[2];
				rightColumn[2] <= row2[2];
			end else begin
				rightColumn[0] <= row0[column + 3];
				rightColumn[1] <= row1[column + 3];
				rightColumn[2] <= row2[column + 3];
			end
			
			nextLiveCount <= leftColumn[0] + leftColumn[1] + leftColumn[2] + centerColumn[0] + centerColumn[2] + rightColumn[0] + rightColumn[1] + rightColumn[2];

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
				6: row0[column] <= 1;
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
