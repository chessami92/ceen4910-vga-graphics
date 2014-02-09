`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module VgaControllerTest;
	reg clk;
	reg rst;

	wire vSync, hSync;
	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;
	
	reg vSyncChange, hSyncChange;
	integer i;

	VgaController uut (
		.clk( clk ), 
		.rst( rst ), 
		.vSync( vSync ),
		.hSync( hSync ),
		.row( row ),
		.column( column ),
		.displayActive( displayActive )
	);

	initial begin
		clk = 1;
		rst = 1;
		vSyncChange = 1;
		hSyncChange = 1;

		#25;
		rst = 0;
		vSyncChange = 0;
		hSyncChange = 0;
	end
	
	always @( vSync ) begin
		`assert( vSyncChange );
	end
	
	always @( hSync ) begin
		`assert( hSyncChange );
	end
	
	always begin
		#15679999 vSyncChange = 1;
		#2 vSyncChange = 0;
		#63998 vSyncChange = 1;
		#2 vSyncChange = 0;
		#1055999;
	end
	
	always begin
		#26239 hSyncChange = 1;
		#2 hSyncChange = 0;
		#3838 hSyncChange = 1;
		#2 hSyncChange = 0;
		#1919;
	end
	
	always begin
		#10 clk = ~clk;
	end
endmodule

