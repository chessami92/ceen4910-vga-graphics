`timescale 1ns / 1ps

module Display(
	input clkRaw, clk133Fb, rstRaw, rotA, rotB, rotCenter,
	input [3:0] sw,
	output wire [2:0] color,
	output wire vSync, hSync,
	output wire [7:0] led,

	//DDR Signals
	output [12:0] sd_A,
	inout [15:0] sd_DQ,
	output [1:0] sd_BA,
	output sd_RAS,
	output sd_CAS,
	output sd_WE,
	output sd_CKE,
	output sd_CS,
	output sd_LDM, sd_UDM,
	inout sd_LDQS, sd_UDQS,
	output sd_CK_P, sd_CK_N
	);

	wire rst;

	// VGA Controller Outputs
	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;

	// Rotary Button outputs
	wire left, right, down;

	// Digital Clock Manager outputs
	wire clk, clkDiv, clk133_p, clk133_n, clk133_90, clk133_270;
	assign sd_CK_P = clk133_p;
	assign sd_CK_N = clk133_n;

	// DDR busses
	wire [31:0] readData;

	assign led[7:0] = sw[1] ? ( sw[0] ? readData[31:24] : readData[23:16] ) : ( sw[0] ? readData[15:8] : readData[7:0] );

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
		.noise( rotCenter ),
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
		.rst( rst ),
		.clkDiv( clkDiv ),
		.clk133_p( clk133_p ),
		.clk133_n( clk133_n ),
		.clk133_90( clk133_90 ),
		.clk133_270( clk133_270 )
	);

	Ddr ddr (
		.clk133_p( clk133_p ),
		.clk133_n( clk133_n ),
		.clk133_90( clk133_90 ),
		.clk133_270( clk133_270 ),
		.rst( rst ),
		.readData( readData ),
		.sd_A( sd_A ),
		.sd_DQ( sd_DQ ),
		.sd_BA( sd_BA ),
		.sd_RAS( sd_RAS ),
		.sd_CAS( sd_CAS ),
		.sd_WE( sd_WE ),
		.sd_CKE( sd_CKE ),
		.sd_CS( sd_CS ),
		.sd_LDM( sd_LDM ),
		.sd_UDM( sd_UDM ),
		.sd_LDQS( sd_LDQS ),
		.sd_UDQS( sd_UDQS )
	);

	/*reg [31:0] clk133Div;
	reg ledReg;
	assign led[7:2] = 6'b111111;
	assign led[1] = ledReg;
	assign led[0] = rst;

	always @( posedge clk133_p or posedge rst ) begin
		if( rst ) begin
			clk133Div <= 0;
			ledReg <= 0;
		end else begin
			clk133Div <= clk133Div + 1;
			if( clk133Div == 1330000000 ) begin
				clk133Div <= 0;
				ledReg <= ~ledReg;
			end
		end
	end*/
endmodule
