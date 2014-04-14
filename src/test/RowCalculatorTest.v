`timescale 1ns / 1ps

module RowCalculatorTest;
	reg clkDiv;
	reg rst;
	reg noise;
	reg drawRequest;
	reg reading;
	reg [639:0] readRow;
	reg displayActive;
	reg [8:0] row;
	reg [9:0] column;

	wire [639:0] drawRow;
	wire [639:0] writeRow;

	RowCalculator uut (
		.clkDiv( clkDiv ),
		.rst( rst ),
		.noise( noise ),
		.drawRequest( drawRequest ),
		.reading( reading ),
		.readRow( readRow ),
		.displayActive( displayActive ),
		.row( row ),
		.column( column ),
		.drawRow( drawRow ),
		.writeRow( writeRow )
	);

	initial begin
		clkDiv = 0;
		rst = 1;
		noise = 0;
		drawRequest = 0;
		reading = 0;
		displayActive = 1;
		row = 0;
		column = 0;

		#5 rst = 0;

		readRow[0] = 0;
		readRow[639] = 1;
		#40 reading = 1;
		#40 reading = 0;
		readRow[0] = 1;
		readRow[639] = 0;
		#40 reading = 1;
		#40 reading = 0;
		readRow[0] = 0;
		readRow[639] = 1;
		#40 column = 637;
		#40 column = 638;
		#40 column = 639;
	end

	always begin
		#20 clkDiv = ~clkDiv;
	end
endmodule

