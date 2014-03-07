`timescale 1ns / 1ps

module Display(
	input clkRaw, rstRaw, clk133Fb, noise, rotA, rotB, rotCenter,
	output wire [2:0] color,
	output wire vSync, hSync,
	output wire [7:0] led,

	//DDR Signals
	/*output [12:0] sd_A,
	inout [15:0] sd_DQ,
	output [1:0] sd_BA,
	output sd_RAS,
	output sd_CAS,
	output sd_WE,
	output sd_CKE,
	output sd_CS,
	output sd_LDM, sd_UDM,
	inout sd_LDQS, sd_UDQS,*/
	output sd_CK_P, sd_CK_N
	);

	// VGA Controller Outputs
	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;
	
	// Rotary Button outputs
	wire left, right, down;
	
	// Digital Clock Manager outputs
	wire clkLocked, clk, clkDiv, clk133_p, clk133_n, clk133_90, clk133_270;
	assign sd_CK_P = clk133_p;
	assign sd_CK_N = clk133_n;
	
	wire rst;
	assign rst = rstRaw | !clkLocked;

	assign led[7:1] = 7'b1111111;
	assign led[0] = clkLocked;
	
	VgaController vgaController(
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
	
	ClkGen clkGen (
		.clkRaw( clkRaw ),
		.rstRaw( rstRaw ),
		.clk133Fb( clk133Fb ),
		.clk( clk ),
		.clkDiv( clkDiv ),
		.clk133_p( clk133_p ),
		.clk133_n( clk133_n ),
		.clkLocked( clkLocked )
	);
endmodule
