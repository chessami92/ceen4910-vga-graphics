`timescale 1ns / 1ps

module VgaController(
	input clkDiv, rst,
	output reg vSync, hSync,
	output wire [8:0] row,
	output wire [9:0] column,
	output wire displayActive
	);

	parameter vDisplay = 480, vFrontPorch = 10, vSyncWidth = 02, vBackPorch = 33,
	          hDisplay = 640, hFrontPorch = 16, hSyncWidth = 96, hBackPorch = 48;

	reg [9:0] hCounter;
	reg [9:0] vCounter;
	reg vSyncComplete, hSyncComplete;
	
	assign row = vCounter[8:0];
	assign column = hCounter[9:0];
	assign displayActive = vSyncComplete & hSyncComplete;

	always @( posedge clkDiv or posedge rst ) begin
		if( rst ) begin
			hCounter <= 0;
			vCounter <= 0;
			vSyncComplete <= 1;
			hSyncComplete <= 1;
			vSync <= 1;
			hSync <= 1;
		end else begin
			hCounter <= hCounter + 1;
			if( hCounter == hDisplay - 1 ) hSyncComplete <= 0;
			if( hCounter == hDisplay + hFrontPorch - 1 ) hSync <= 0;
			if( hCounter == hDisplay + hFrontPorch + hSyncWidth - 1 ) hSync <= 1;
			if( hCounter == hDisplay + hFrontPorch + hSyncWidth + hBackPorch - 1 ) begin
				hCounter <= 0;
				vCounter <= vCounter + 1;
				hSyncComplete <= 1;
				if( vCounter == vDisplay - 1 ) vSyncComplete <= 0;
				if( vCounter == vDisplay + vFrontPorch - 1 ) vSync <= 0;
				if( vCounter == vDisplay + vFrontPorch + vSyncWidth - 1 ) vSync <= 1;
				if( vCounter == vDisplay + vFrontPorch + vSyncWidth + vBackPorch - 1 ) begin
					vCounter <= 0;
					vSyncComplete <= 1;
				end
			end
		end
	end
endmodule
