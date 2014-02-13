`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module RotaryButtonTest;
	reg clk, rst, rotA, rotB, rotCenter;

	wire left, right, down;

	RotaryButton uut (
		.clk( clk ), 
		.rst( rst ),
		.rotA( rotA ),
		.rotB( rotB ),
		.rotCenter( rotCenter ), 
		.left( left ),
		.right( right ),
		.down( down )
	);

	initial begin
		rotA = 0;
		rotB = 0;
		rotCenter = 0;
		clk = 0;
		rst = 1;
		
		#5 rst = 0;
		
		#35 rotA = 1;
		#1500 rotB = 1;
		#40 `assert( left );
		#1500 rotA = 0;
		#1500 rotB = 0;
		
		#1500 rotB = 1;
		#1500 rotA = 1;
		#40 `assert( right );
		#1500 rotB = 0;
		#1500 rotA = 0;
		
		#1500 rotCenter = 1;
		#10250 `assert( down );
		#20 rotCenter = 0;
	end
	
	always begin
		#10 clk = ~clk;
	end
endmodule

