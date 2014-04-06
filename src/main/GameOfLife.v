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
	reg [23:0] readAddress;
	wire readAcknowledge;
	reg [15:0] currentPixels;
	wire [15:0] nextPixels;
	reg write;
	wire [23:0] writeAddress;
	wire writeAcknowledge;
	reg refresh;

	reg drawRequest, draw;

	reg [639:0] row0;
	reg [639:0] row1;
	reg [639:0] row2;

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
		.refresh( refresh ),
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

	assign writeAddress = {9'h000, row, column[9:4]};
	
	always @( negedge clkDiv or posedge rst ) begin
		if( rst ) begin
			currentPixels <= 0;
			write <= 0;
			color <= 0;
			drawRequest <= 0;
			draw <= 0;
			led <= 0;

			row0 <= 0;
			row1 <= 0;
		end else begin
			if( drawAgain )
				drawRequest <= 1;
			if( drawRequest && row == 480 ) begin
				draw <= 1;
				drawRequest <= 0;
			end
			if( draw && row == 479 )
				draw <= 0;

			if( writeAcknowledge )
				write <= 0;

			if( column == 640 ) begin
				row0 <= row1;
				row1 <= row2;
			end

			if( displayActive && row1[column] ) begin
				color <= 3'b010;
			end else begin
				color <= 0;
			end

			if( displayActive && column[3:0] == 4'hF ) begin
				currentPixels <= nextPixels;

				if( draw ) begin
					write <= 1;
				end
			end
		end
	end
	
	always @( negedge clk133_p or posedge rst ) begin
		if( rst ) begin
			read <= 0;
			readAddress <= 0;
			refresh <= 0;
			row2 <= 0;
		end else begin
			if( refresh )
				refresh <= 0;
			if( column == 640 ) begin
				read <= 1;
				if( row == 525 )
					readAddress <= 0;
				else
					readAddress <= {9'h0000, row + 2, 6'h00};
			end
			if( readAcknowledge ) begin
				case( readAddress[5:0] )
					0: row2[15:0] <= nextPixels;
					1: row2[31:16] <= nextPixels;
					2: row2[47:32] <= nextPixels;
					3: row2[63:48] <= nextPixels;
					4: row2[79:64] <= nextPixels;
					5: row2[95:80] <= nextPixels;
					6: row2[111:96] <= nextPixels;
					7: row2[127:112] <= nextPixels;
					8: row2[143:128] <= nextPixels;
					9: row2[159:144] <= nextPixels;
					10: row2[175:160] <= nextPixels;
					11: row2[191:176] <= nextPixels;
					12: row2[207:192] <= nextPixels;
					13: row2[223:208] <= nextPixels;
					14: row2[239:224] <= nextPixels;
					15: row2[255:240] <= nextPixels;
					16: row2[271:256] <= nextPixels;
					17: row2[287:272] <= nextPixels;
					18: row2[303:288] <= nextPixels;
					19: row2[319:304] <= nextPixels;
					20: row2[335:320] <= nextPixels;
					21: row2[351:336] <= nextPixels;
					22: row2[367:352] <= nextPixels;
					23: row2[383:368] <= nextPixels;
					24: row2[399:384] <= nextPixels;
					25: row2[415:400] <= nextPixels;
					26: row2[431:416] <= nextPixels;
					27: row2[447:432] <= nextPixels;
					28: row2[463:448] <= nextPixels;
					29: row2[479:464] <= nextPixels;
					30: row2[495:480] <= nextPixels;
					31: row2[511:496] <= nextPixels;
					32: row2[527:512] <= nextPixels;
					33: row2[543:528] <= nextPixels;
					34: row2[559:544] <= nextPixels;
					35: row2[575:560] <= nextPixels;
					36: row2[591:576] <= nextPixels;
					37: row2[607:592] <= nextPixels;
					38: row2[623:608] <= nextPixels;
					39: begin
						row2[639:624] <= nextPixels;
						read <= 0;
						refresh <= 1;
					end
				endcase
				readAddress <= readAddress + 1;
			end
		end
	end
endmodule
