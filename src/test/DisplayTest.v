`timescale 1ns / 1ps

module DisplayTest;
	reg clkRaw;
	reg rst;
	reg noise;
	
	wire [2:0] color;
	wire vSync;
	wire hSync;

	Display uut (
		.clkRaw(clkRaw),
		.rst(rst), 
		.noise(noise), 
		.color(color), 
		.vSync(vSync), 
		.hSync(hSync)
	);

	initial begin
		clkRaw = 0;
		rst = 1;
		noise = 1;
		
		#5 rst = 0;
	end

	always begin
		#10 clkRaw = ~clkRaw;
	end
endmodule

