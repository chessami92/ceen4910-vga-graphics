`timescale 1ns / 1ps

module ClkGen(
	input clkRaw, rstRaw, clk133Fb,
	output clk, clkDiv, clk133_p, clk133_n, clk133_90, clk133_270, clkLocked
	);

	wire clkMul133Locked, clkPhase133Locked;
	wire clkMul133LockedN;
	wire clk133;

	assign clkMul133LockedN = !clkMul133Locked;
	assign clkLocked = clkMul133Locked & clkPhase133Locked;

	ClkMul133 clkMul133 (
		.CLKIN_IN( clkRaw ),
		.RST_IN( rstRaw ),
		.CLKDV_OUT( clkDiv ),
		.CLKFX_OUT( clk133 ),
		.CLK0_OUT( clk ),
		.LOCKED_OUT( clkMul133Locked )
	);

	ClkPhase133 instance_name (
		.CLKFB_IN( clk133Fb ),
		.CLKIN_IN( clk133 ),
		.RST_IN( clkMul133LockedN ),
		.CLK0_OUT( clk133_p ),
		.CLK90_OUT( clk133_90 ),
		.CLK180_OUT( clk133_n ),
		.CLK270_OUT( clk133_270 ),
		.LOCKED_OUT( clkPhase133Locked )
	);
endmodule
