`timescale 1ns / 1ps

module GameOfLife(
	input clk, clkDiv, rst, displayActive, noise, increment, decrement, drawAgain,
	input [8:0] row,
	input [9:0] column,
	output wire [2:0] color
	);

	reg [3:0] memory[639:0];
	reg [3:0] memoryRead;
	reg displayActiveOld;
	reg [8:0] divideBy;
	reg [8:0] divideCounter;
	reg [9:0] dividedColumn;

	reg [9:0] columnIndex;
	reg draw;

	wire [15:0] random;
	Random randomGenerator(
		.clk( clkDiv ),
		.rst( rst ),
		.noise( noise ),
		.random( random )
	);
	
	assign color = displayActiveOld ? memoryRead[2:0] : 0;
	
	always @( negedge clkDiv or posedge rst ) begin
		if( rst ) begin
			displayActiveOld <= 0;
			divideBy <= 0;
			divideCounter <= 0;
			dividedColumn <= 0;
		end else begin
			if( increment ) divideBy <= divideBy + 1;
			if( decrement ) divideBy <= divideBy - 1;
			
			if( column == 640 ) begin
				divideCounter <= divideBy;
				dividedColumn <= 0;
			end
			if( displayActive ) begin
				divideCounter <= divideCounter + 1;
				if( divideCounter == divideBy ) begin
					divideCounter <= 0;
					dividedColumn <= dividedColumn + 1;
					memoryRead <= memory[dividedColumn];
				end
			end
			
			displayActiveOld <= displayActive;
		end
	end
	
		always @( negedge clk or posedge rst ) begin
		if( rst ) begin
			draw <= 1;
			columnIndex <= 0;
		end else begin
			if( drawAgain ) draw <= 1;
			if( draw ) begin
				memory[columnIndex] <= random[3:0];
				columnIndex <= columnIndex + 1;
				if( columnIndex == 640 - 1 ) draw <= 0;
			end
		end
	end
endmodule
