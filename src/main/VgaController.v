`timescale 1ns / 1ps

module VgaController(
	input clk,
	input rst,
	output reg [2:0] color,
	output reg vSync, hSync	
	);

	parameter vDisplay = 480, vFrontPorch = 10, vSyncWidth = 02, vBackPorch = 33,
	          hDisplay = 640, hFrontPorch = 16, hSyncWidth = 96, hBackPorch = 48;

	reg [9:0] hCounter;
	reg [9:0] vCounter;
	reg vSyncComplete, hSyncComplete;
	reg clkDiv;

	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			hCounter <= 0;
			vCounter <= 0;
			vSyncComplete <= 1;
			hSyncComplete <= 0;
			
			vSync <= 1;
			hSync <= 0;
			
			color <= 3'b100;
		end
		else if( clkDiv )begin
			hCounter <= hCounter + 1;
			if( !hSyncComplete ) begin
				if( hCounter == hSyncWidth - 1 ) hSync <= 1;
				if( hCounter == hSyncWidth + hBackPorch - 1 ) begin
					hSyncComplete <= 1;
					hCounter <= 0;
				end
			end else begin
				if( hCounter == hDisplay - 1 ) hSyncComplete <= 0;
			end
			if( hCounter == hDisplay + hFrontPorch - 1 ) begin
				hCounter <= 0;
				vCounter <= vCounter + 1;
				if( vCounter == vDisplay - 1 ) vSyncComplete <= 0;
				else if( vSyncComplete ) hSync <= 0;
				if( vCounter == vDisplay + vBackPorch - 1 ) vSync <= 0;
				if( vCounter == vDisplay + vBackPorch + vSyncWidth - 1 ) vSync <= 1;
				if( vCounter == vDisplay + vBackPorch + vSyncWidth + vFrontPorch - 1 ) begin
					vCounter <= 0;
					vSyncComplete <= 1;
					hSync <= 0;
				end
			end
		end
	end
	
	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			clkDiv <= 1;
		end
		else begin
			clkDiv <= ~clkDiv;
		end
	end
endmodule
