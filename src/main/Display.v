`timescale 1ns / 1ps

module Display(
	input clk, rst,
	output reg [2:0] color,
	output vSync, hSync
	);
	
	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;
	
	VgaController vgaController (
		.clk( clk ), 
		.rst( rst ), 
		.vSync( vSync ),
		.hSync( hSync ),
		.row( row ),
		.column( column )
	);
	
	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			color <= 0;
		end
	end

endmodule
