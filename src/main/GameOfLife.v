`timescale 1ns / 1ps

module GameOfLife(
	input clk, clkDiv, rst, displayActive, noise, drawRequest,
	input left, right,
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

	reg [2:0] deadColor, liveColor;

	reg read, readPrevious;
	reg [23:0] readAddress;
	wire readAcknowledge;
	wire [15:0] readData;
	reg write, writeThisRow;
	reg [23:0] writeAddress;
	wire writeAcknowledge;
	reg [15:0] writeData;
	reg refresh;
	wire refreshAcknowledge;

	wire [639:0] drawRow;
	wire [639:0] writeRow;
	reg [639:0] readRow;
	reg [8:0] nextReadRow;

	reg highLife;
	reg [31:0] highLifeCounter;

	RowCalculator rowCalculator (
		.clkDiv( clkDiv ),
		.rst( rst ),
		.noise( noise ),
		.drawRequest( drawRequest ),
		.reading( read ),
		.readRow( readRow ),
		.highLife( highLife ),
		.displayActive( displayActive ),
		.row( row ),
		.column( column ),
		.drawRow( drawRow ),
		.writeRow( writeRow )
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
		.refreshAcknowledge( refreshAcknowledge ),
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
			highLife <= 0;
			highLifeCounter <= 0;
		end else begin
			highLifeCounter <= highLifeCounter + 1;
			if( highLifeCounter == 750000000 ) begin
				highLifeCounter <= 0;
				highLife <= ~highLife;
			end
		end
	end

	always @( posedge clkDiv or posedge rst ) begin
		if( rst ) begin
			color <= 0;
			deadColor <= 0;
			liveColor <= 3'b010;

			nextReadRow <= 0;
			writeThisRow <= 0;
		end else begin
			if( column == 630 ) begin
				if( displayActive ) begin
					if( row == 478 )
						nextReadRow <= 0;
					else
						nextReadRow <= row + 2;
				end else begin
					if( row == 10 )
						nextReadRow <= 479;
					if( row == 11 )
						nextReadRow <= 0;
					else if( row == 12 )
						nextReadRow <= 1;
					else
						nextReadRow <= 0;
				end

				if( displayActive )
					writeThisRow <= 1;
				else
					writeThisRow <= 0;
			end

			if( displayActive && drawRow[column] ) begin
				color <= liveColor;
			end else if( displayActive && !drawRow[column] ) begin
				color <= deadColor;
			end else begin
				color <= 0;
			end

			if( left )
				deadColor <= deadColor + 1;
			if( right )
				liveColor <= liveColor + 1;
		end
	end
	
	always @( negedge clk133_p or posedge rst ) begin
		if( rst ) begin
			write <= 0;
			writeAddress <= 0;
			read <= 0;
			readAddress <= 0;
			refresh <= 0;
			readRow <= 0;
		end else begin
			if( refreshAcknowledge )
				refresh <= 0;

			if( column == 640 ) begin
				if( writeThisRow )
					write <= 1;
				else
					read <= 1;
				refresh <=1;
				writeAddress <= {9'b000000000, row, 6'b000000};
				writeData <= writeRow[31:16];
				readAddress <= {9'b000000000, nextReadRow, 6'b000000};
			end
			if( writeAcknowledge ) begin
				case( writeAddress[5:0] )
					0: writeData <= writeRow[47:32];
					1: writeData <= writeRow[63:48];
					2: writeData <= writeRow[79:64];
					3: writeData <= writeRow[95:80];
					4: writeData <= writeRow[111:96];
					5: writeData <= writeRow[127:112];
					6: writeData <= writeRow[143:128];
					7: writeData <= writeRow[159:144];
					8: writeData <= writeRow[175:160];
					9: writeData <= writeRow[191:176];
					10: writeData <= writeRow[207:192];
					11: writeData <= writeRow[223:208];
					12: writeData <= writeRow[239:224];
					13: writeData <= writeRow[255:240];
					14: writeData <= writeRow[271:256];
					15: writeData <= writeRow[287:272];
					16: writeData <= writeRow[303:288];
					17: begin
						writeData <= writeRow[319:304];
						refresh <= 1;
					end
					18: writeData <= writeRow[335:320];
					19: writeData <= writeRow[351:336];
					20: writeData <= writeRow[367:352];
					21: writeData <= writeRow[383:368];
					22: writeData <= writeRow[399:384];
					23: writeData <= writeRow[415:400];
					24: writeData <= writeRow[431:416];
					25: writeData <= writeRow[447:432];
					26: writeData <= writeRow[463:448];
					27: writeData <= writeRow[479:464];
					28: writeData <= writeRow[495:480];
					29: writeData <= writeRow[511:496];
					30: writeData <= writeRow[527:512];
					31: writeData <= writeRow[543:528];
					32: writeData <= writeRow[559:544];
					33: writeData <= writeRow[575:560];
					34: writeData <= writeRow[591:576];
					35: writeData <= writeRow[607:592];
					36: writeData <= writeRow[623:608];
					37: writeData <= writeRow[639:624];
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
					0: readRow[15:0] <= readData;
					1: readRow[31:16] <= readData;
					2: readRow[47:32] <= readData;
					3: readRow[63:48] <= readData;
					4: readRow[79:64] <= readData;
					5: readRow[95:80] <= readData;
					6: readRow[111:96] <= readData;
					7: readRow[127:112] <= readData;
					8: readRow[143:128] <= readData;
					9: readRow[159:144] <= readData;
					10: readRow[175:160] <= readData;
					11: readRow[191:176] <= readData;
					12: readRow[207:192] <= readData;
					13: readRow[223:208] <= readData;
					14: readRow[239:224] <= readData;
					15: readRow[255:240] <= readData;
					16: readRow[271:256] <= readData;
					17: readRow[287:272] <= readData;
					18: readRow[303:288] <= readData;
					19: begin
						readRow[319:304] <= readData;
						refresh <= 1;
					end
					20: readRow[335:320] <= readData;
					21: readRow[351:336] <= readData;
					22: readRow[367:352] <= readData;
					23: readRow[383:368] <= readData;
					24: readRow[399:384] <= readData;
					25: readRow[415:400] <= readData;
					26: readRow[431:416] <= readData;
					27: readRow[447:432] <= readData;
					28: readRow[463:448] <= readData;
					29: readRow[479:464] <= readData;
					30: readRow[495:480] <= readData;
					31: readRow[511:496] <= readData;
					32: readRow[527:512] <= readData;
					33: readRow[543:528] <= readData;
					34: readRow[559:544] <= readData;
					35: readRow[575:560] <= readData;
					36: readRow[591:576] <= readData;
					37: readRow[607:592] <= readData;
					38: readRow[623:608] <= readData;
					39: begin
						readRow[639:624] <= readData;
						read <= 0;
					end
				endcase
				readAddress <= readAddress + 1;
			end
		end
	end
endmodule
