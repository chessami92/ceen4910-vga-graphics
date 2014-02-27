`timescale 1ns / 1ps

module Display(
	input clkRaw, rstRaw, noise, rotA, rotB, rotCenter,
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
	wire clkLocked, clk, clkDiv, clk2x_p, clk2x_n;
	assign sd_CK_P = clk2x_p;
	assign sd_CK_N = clk2x_n;
	
	wire rst;
	assign rst = rstRaw | !clkLocked;
	
	assign led[7:0] = 7'hFF;
	
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
		.CLKIN_IN( clkRaw ),
		.RST_IN( rstRaw ),
		.CLKDV_OUT( clkDiv ),
		.CLK0_OUT( clk ),
		.CLK2X_OUT( clk2x_p ),
		.CLK2X180_OUT( clk2x_n ),
		.LOCKED_OUT( clkLocked )
	);
endmodule
