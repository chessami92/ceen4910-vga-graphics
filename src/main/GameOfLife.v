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

	reg read, readPrevious;
	reg [23:0] readAddress;
	wire readAcknowledge;
	wire [15:0] readData;
	reg write;
	reg [23:0] writeAddress;
	wire writeAcknowledge;
	reg [15:0] writeData;
	reg refresh;

	reg drawRequest, draw;

	reg [639:0] row0;
	reg [639:0] row1;
	reg [639:0] row2;
	reg [8:0] nextReadRow;

	wire [15:0] random;

	Random randomGenerator(
		.clk( clk133_p ),
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
		.readData( readData ),
		.write( write ),
		.writeAcknowledge( writeAcknowledge ),
		.writeAddress( writeAddress ),
		.writeData( writeData ),
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
	
	always @( posedge clkDiv or posedge rst ) begin
		if( rst ) begin
			color <= 0;

			nextReadRow <= 0;
		end else begin
			if( column == 630 ) begin
				if( displayActive )
					nextReadRow <= row + 2;
				else if( !displayActive && row == 11 )
					nextReadRow <= 0;
				else if( !displayActive && row == 12 )
					nextReadRow <= 1;
			end

			if( displayActive && row2[column] ) begin
				color <= 3'b010;
			end else begin
				color <= 0;
			end
		end
	end

	always @( posedge clkDiv or posedge rst ) begin
		if( rst ) begin
			readPrevious <= 0;
			row0 <= 0;
			row1 <= 0;

			drawRequest <= 0;
			draw <= 0;
			led <= 0;
		end else begin
			readPrevious <= read;
			if( read && !readPrevious ) begin
				row0 <= row1;
				row1 <= row2;
			end

			if( displayActive && draw )
				row1[column] <= random[0];

			if( drawAgain )
				drawRequest <= 1;
			if( drawRequest && row == 481 ) begin
				draw <= 1;
				drawRequest <= 0;
			end
			if( draw && row == 480 )
				draw <= 0;
		end
	end
	
	always @( negedge clk133_p or posedge rst ) begin
		if( rst ) begin
			write <= 0;
			writeAddress <= 0;
			read <= 0;
			readAddress <= 0;
			refresh <= 0;
			row2 <= 0;
		end else begin
			if( refresh )
				refresh <= 0;
			if( displayActive )
				refresh <= 1;

			if( column == 640 && !write ) begin
				write <= 1;
				writeAddress <= {9'h000, row, 6'h00};
				writeData <= row1[31:16];
				readAddress <= {9'h000, nextReadRow, 6'h00};
			end
			if( writeAcknowledge ) begin
				case( writeAddress[5:0] )
					//0: writeData <= row1[31:16];
					0: writeData <= row1[47:32];
					1: writeData <= row1[63:48];
					2: writeData <= row1[79:64];
					3: writeData <= row1[95:80];
					4: writeData <= row1[111:96];
					5: writeData <= row1[127:112];
					6: writeData <= row1[143:128];
					7: writeData <= row1[159:144];
					8: writeData <= row1[175:160];
					9: writeData <= row1[191:176];
					10: writeData <= row1[207:192];
					11: writeData <= row1[223:208];
					12: writeData <= row1[239:224];
					13: writeData <= row1[255:240];
					14: writeData <= row1[271:256];
					15: writeData <= row1[287:272];
					16: writeData <= row1[303:288];
					17: begin
						writeData <= row1[319:304];
						refresh <= 1;
					end
					18: writeData <= row1[335:320];
					19: writeData <= row1[351:336];
					20: writeData <= row1[367:352];
					21: writeData <= row1[383:368];
					22: writeData <= row1[399:384];
					23: writeData <= row1[415:400];
					24: writeData <= row1[431:416];
					25: writeData <= row1[447:432];
					26: writeData <= row1[463:448];
					27: writeData <= row1[479:464];
					28: writeData <= row1[495:480];
					29: writeData <= row1[511:496];
					30: writeData <= row1[527:512];
					31: writeData <= row1[543:528];
					32: writeData <= row1[559:544];
					33: writeData <= row1[575:560];
					34: writeData <= row1[591:576];
					35: writeData <= row1[607:592];
					36: writeData <= row1[623:608];
					37: writeData <= row1[639:624];
					38: begin
						write <= 0;
						refresh <= 1;
						read <= 1;
					end
				endcase
				writeAddress <= writeAddress + 1;
			end
			if( readAcknowledge ) begin
				case( readAddress[5:0] )
					0: row2[15:0] <= readData;
					1: row2[31:16] <= readData;
					2: row2[47:32] <= readData;
					3: row2[63:48] <= readData;
					4: row2[79:64] <= readData;
					5: row2[95:80] <= readData;
					6: row2[111:96] <= readData;
					7: row2[127:112] <= readData;
					8: row2[143:128] <= readData;
					9: row2[159:144] <= readData;
					10: row2[175:160] <= readData;
					11: row2[191:176] <= readData;
					12: row2[207:192] <= readData;
					13: row2[223:208] <= readData;
					14: row2[239:224] <= readData;
					15: row2[255:240] <= readData;
					16: row2[271:256] <= readData;
					17: row2[287:272] <= readData;
					18: row2[303:288] <= readData;
					19: begin
						row2[319:304] <= readData;
						refresh <= 1;
					end
					20: row2[335:320] <= readData;
					21: row2[351:336] <= readData;
					22: row2[367:352] <= readData;
					23: row2[383:368] <= readData;
					24: row2[399:384] <= readData;
					25: row2[415:400] <= readData;
					26: row2[431:416] <= readData;
					27: row2[447:432] <= readData;
					28: row2[463:448] <= readData;
					29: row2[479:464] <= readData;
					30: row2[495:480] <= readData;
					31: row2[511:496] <= readData;
					32: row2[527:512] <= readData;
					33: row2[543:528] <= readData;
					34: row2[559:544] <= readData;
					35: row2[575:560] <= readData;
					36: row2[591:576] <= readData;
					37: row2[607:592] <= readData;
					38: row2[623:608] <= readData;
					39: begin
						row2[639:624] <= readData;
						read <= 0;
						refresh <= 1;
					end
				endcase
				readAddress <= readAddress + 1;
			end
		end
	end
endmodule
