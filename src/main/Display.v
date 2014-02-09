`timescale 1ns / 1ps

module Display(
	input clk, rst, noise,
	output wire [2:0] color,
	output vSync, hSync
	);

	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;

	reg clkDiv;

	VgaController vgaController(
		.clk( clk ),
		.clkDiv( clkDiv ),
		.rst( rst ),
		.vSync( vSync ),
		.hSync( hSync ),
		.row( row ),
		.column( column ),
		.displayActive( displayActive )
	);

	GameOfLife colorGenerator(
		.clk( clk ),
		.rst( rst ),
		.displayActive( displayActive ),
		.noise( noise ),
		.row( row ),
		.column( column ),
		.color( color )
	);

	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			clkDiv <= 0;
		end
		else begin
			clkDiv <= ~clkDiv;
		end
	end
endmodule
