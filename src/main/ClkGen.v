`timescale 1ns / 1ps

module ClkGen(
	input clkRaw, rstRaw, clk133Fb,
	output clk, rst, clkDiv, clk133_p, clk133_n, clk133_90, clk133_270
	);

	reg [15:0] debounce;
	reg rstDebounced;

	reg [2:0] pos100Rot;
	reg [2:0] neg100Rot;

	wire clkMul100Locked, clkMul66Locked, clkMul133Locked, clkPhase133Locked, clkLocked;
	wire clkMul100LockedN, clkMul66LockedN, clkMul133LockedN;
	wire clk33, clk66, clk133;

	assign clk33 = pos100Rot[0] & neg100Rot[0];
	assign clkMul100LockedN = !clkMul100Locked;
	assign clkMul66LockedN = !clkMul66Locked;
	assign clkMul133LockedN = !clkMul133Locked;
	assign clkLocked = clkMul100Locked & clkMul66Locked & clkMul133Locked & clkPhase133Locked;
	assign rst = rstDebounced | !clkLocked;

	ClkMul100 clkMul100 (
		.CLKIN_IN( clkRaw ),
		.RST_IN( rstDebounced ),
		.CLKIN_IBUFG_OUT( clk ),
		.CLKDV_OUT( clkDiv ),
		.CLK2X_OUT( clk100 ),
		.LOCKED_OUT( clkMul100Locked )
	);

	always @( posedge clk100 or posedge clkMul100LockedN ) begin
		if( clkMul100LockedN ) begin
			pos100Rot <= 3'b011;
		end else begin
			pos100Rot <= {pos100Rot[1:0], pos100Rot[2]};
		end
	end

	always @( negedge clk100 or posedge clkMul100LockedN ) begin
		if( clkMul100LockedN ) begin
			neg100Rot <= 3'b011;
		end else begin
			neg100Rot <= {neg100Rot[1:0], neg100Rot[2]};
		end
	end

	ClkMul66 clkMul66 (
		.CLKIN_IN( clk33 ),
		.RST_IN( clkMul100LockedN ),
		.CLK2X_OUT( clk66 ),
		.LOCKED_OUT( clkMul66Locked )
	);

	ClkMul133 clkMul133 (
		.CLKIN_IN( clk66 ),
		.RST_IN( clkMul66LockedN ),
		.CLK2X_OUT( clk133 ),
		.LOCKED_OUT( clkMul133Locked )
	);

	ClkPhase133 clkPhase133 (
		.CLKFB_IN( clk133Fb ),
		.CLKIN_IN( clk133 ),
		.RST_IN( clkMul133LockedN ),
		.CLK0_OUT( clk133_p ),
		.CLK90_OUT( clk133_90 ),
		.CLK180_OUT( clk133_n ),
		.CLK270_OUT( clk133_270 ),
		.LOCKED_OUT( clkPhase133Locked )
	);

	always @( posedge clk or posedge rstRaw ) begin
		if( rstRaw ) begin
			debounce <= 0;
			rstDebounced <= 1;
		end else begin
			debounce <= debounce + 1;
			if( debounce == 16'hFFFF )
				rstDebounced <= 0;
		end
	end
endmodule
