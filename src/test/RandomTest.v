`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module RandomTest;
	reg clk, rst, noise;

	wire [15:0] random;
	integer i;

	Random uut (
		.clk(clk), 
		.rst(rst), 
		.noise(noise), 
		.random(random)
	);

	initial begin
		clk = 0;
		rst = 1;
		noise = 1;
		
		#5 rst = 0;
		
		#10 `assert( random == 1 );
		#20 `assert( random == 2 );
		noise = 0;
		#20 `assert( random == 5 );
		noise = 1;
		#20 `assert( random == 11 );
		
		/* Make sure it's maximum length. */
		for( i = 0; i < 65534; i = i + 1 ) begin
			#20 `assert( random != 11 );
		end
		#20 `assert( random == 11 );
	end
	
	always begin
		#10 clk = ~clk;
	end
endmodule
