`timescale 1ns / 1ps

module Display(
	input clk, rst, noise,
	output reg [2:0] color,
	output vSync, hSync
	);
	
	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;
	
	wire [7:0] random;
	
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
	
	Random randomGenerator(
		.clk( clk ),
		.rst( rst ),
		.noise( noise ),
		.random( random )
	);
	
	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			color <= 0;
		end else if( clkDiv ) begin
			if( displayActive ) begin
				color <= color + 1;
			end else begin
				color <= 0;
			end
		end
	end
	
	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			clkDiv <= 0;
		end
		else begin
			clkDiv <= ~clkDiv;
		end
	end
endmodule
