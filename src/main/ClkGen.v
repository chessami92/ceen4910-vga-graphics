`timescale 1ns / 1ps

module ClkGen(
	input clkRaw, rstRaw, //clk133Fb,
	output clk, clkDiv, clk133_p, clk133_n, clkLocked
	);

	wire clkDivMulLocked, clkDiv33Locked, clkMul66Locked, clkMul133Locked;
	wire clkDivMulLockedN, clkDiv33LockedN, clkMul66LockedN;
	wire clk100, clk33, clk66;
	
	assign clkDivMulLockedN = !clkDivMulLocked;
	assign clkDiv33LockedN = !clkDiv33Locked;
	assign clkMul66LockedN = !clkMul66Locked;
	assign clkLocked = clkDivMulLocked & clkDiv33Locked & clkMul66Locked & clkMul133Locked;

	ClkDivMul clkDivMul (
		.CLKIN_IN( clkRaw ),
		.RST_IN( rstRaw ),
		.CLKDV_OUT( clkDiv ),
		.CLK0_OUT( clk ),
		.CLK2X_OUT( clk100 ), 
		.LOCKED_OUT( clkDivMulLocked )
	);
	
	ClkDiv33 clkDiv33 (
		.CLKIN_IN( clk100 ),
		.RST_IN( clkDivMulLockedN ),
		.CLKDV_OUT( clk33 ),
		.LOCKED_OUT( clkDiv33Locked )
	);
	
	ClkMul66 clkMul66 (
		.CLKIN_IN( clk33 ),
		.RST_IN( clkDiv33LockedN ),
		.CLK2X_OUT( clk66 ),
		.LOCKED_OUT( clkMul66Locked )
	);
	
	ClkMul133 clkMul133 (
		.CLKIN_IN( clk66 ),
		.RST_IN( clkMul66LockedN ),
		.CLK2X_OUT( clk133_p ),
		.CLK2X180_OUT( clk133_n ),
		.LOCKED_OUT( clkMul133Locked )
	);
endmodule
