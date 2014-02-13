`timescale 1ns / 1ps

module Display(
	input clk, rst, noise, rotA, rotB, rotCenter,
	output wire [2:0] color,
	output wire vSync, hSync
	);

	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;
	wire left, right, down;

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
		.clkDiv( clkDiv ),
		.rst( rst ),
		.displayActive( displayActive ),
		.noise( noise ),
		.increment( right ),
		.decrement( left ),
		.drawAgain( down ),
		.row( row ),
		.column( column ),
		.color( color )
	);
	
	RotaryButton rotaryButton (
		.clk( clk ), 
		.rst( rst ),
		.rotA( rotA ),
		.rotB( rotB ),
		.rotCenter( rotCenter ), 
		.left( left ),
		.right( right ),
		.down( down )
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
