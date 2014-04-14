`timescale 1ns / 1ps


module GameOfLifeTest;
	reg clk;
	reg clkDiv;
	reg rst;
	reg displayActive;
	reg noise;
	reg drawRequest;
	reg left;
	reg right;
	reg [8:0] row;
	reg [9:0] column;
	reg clk133_p;

	wire [2:0] color;
	wire [7:0] led;
	wire [12:0] sd_A;
	wire [1:0] sd_BA;
	wire sd_RAS;
	wire sd_CAS;
	wire sd_WE;
	wire sd_CKE;
	wire sd_CS;
	wire sd_LDM;
	wire sd_UDM;

	wire [15:0] sd_DQ;
	wire sd_LDQS;
	wire sd_UDQS;

	GameOfLife uut (
		.clk(clk),
		.clkDiv(clkDiv),
		.rst(rst),
		.displayActive(displayActive),
		.noise(noise),
		.drawRequest(drawRequest),
		.left(left),
		.right(right),
		.row(row),
		.column(column),
		.color(color),
		.led(led),
		.clk133_p(clk133_p),
		.sd_A(sd_A),
		.sd_DQ(sd_DQ),
		.sd_BA(sd_BA),
		.sd_RAS(sd_RAS),
		.sd_CAS(sd_CAS),
		.sd_WE(sd_WE),
		.sd_CKE(sd_CKE),
		.sd_CS(sd_CS),
		.sd_LDM(sd_LDM),
		.sd_UDM(sd_UDM),
		.sd_LDQS(sd_LDQS),
		.sd_UDQS(sd_UDQS)
	);

	initial begin
		clk = 0;
		clkDiv = 0;
		rst = 1;
		displayActive = 0;
		noise = 0;
		drawRequest = 0;
		left = 0;
		right = 0;
		row = 0;
		column = 0;
		clk133_p = 0;

		#5 rst = 0;
		#499995 column = 630;
		displayActive = 1;
		#40 column = 640;
		displayActive = 0;
		#40 column = 641;
	end
	
	always begin
		#3.7594 clk133_p = ~clk133_p;
	end
	
	always begin
		#20 clkDiv = ~clkDiv;
	end
endmodule

