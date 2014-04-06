`timescale 1ns / 1ps

module GameOfLife(
	input clk, clkDiv, rst, displayActive, noise, drawAgain,
	input [8:0] row,
	input [9:0] column,
	output reg [2:0] color,

	output reg [7:0] led,

	input clk133_p,
	output [12:0] sd_A,
	inout [15:0] sd_DQ,
	output [1:0] sd_BA,
	output sd_RAS, sd_CAS, sd_WE,
	output sd_CKE, sd_CS,
	output sd_LDM, sd_UDM,
	inout sd_LDQS, sd_UDQS
	);

	reg read;
	wire [23:0] readAddress;
	wire readAcknowledge;
	reg [15:0] currentPixels;
	wire [15:0] nextPixels;
	reg write;
	wire [23:0] writeAddress;
	wire writeAcknowledge;

	reg drawRequest, draw;

	wire [15:0] random;
	Random randomGenerator(
		.clk( clkDiv ),
		.rst( rst ),
		.noise( noise ),
		.random( random )
	);

	Ddr ddr (
		.clk133_p( clk133_p ),
		.rst( rst ),
		.read( read ),
		.readAcknowledge( readAcknowledge ),
		.readAddress( readAddress ),
		.readData( nextPixels ),
		.write( write ),
		.writeAcknowledge( writeAcknowledge ),
		.writeAddress( writeAddress ),
		.writeData( random ),
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

	assign readAddress = {9'h000, row, column[9:4]};
	assign writeAddress = {9'h000, row, column[9:4]};
	
	always @( negedge clkDiv or posedge rst ) begin
		if( rst ) begin
			currentPixels <= 0;
			read <= 0;
			write <= 0;
			color <= 0;
			drawRequest <= 0;
			draw <= 0;
			led <= 0;
		end else begin
			if( drawAgain )
				drawRequest <= 1;
			if( drawRequest && row == 480 ) begin
				draw <= 1;
				drawRequest <= 0;
			end
			if( draw && row == 479 )
				draw <= 0;

			if( readAcknowledge )
				read <= 0;
			if( writeAcknowledge )
				write <= 0;

			if( displayActive && currentPixels[column[3:0]] ) begin
				color <= 3'b111;
			end else begin
				color <= 0;
			end

			if( displayActive && column[3:0] == 4'hF ) begin
				currentPixels <= nextPixels;
				read <= 1;

				if( draw ) begin
					write <= 1;
				end
			end
		end
	end
endmodule
