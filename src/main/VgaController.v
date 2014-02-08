`timescale 1ns / 1ps

module VgaController(
	input clk,
	input rst,
	output reg [2:0] color,
	output reg vSync, hSync	
	);

	parameter vDisplay = 480, vFrontPorch = 10, vSyncWidth = 02, vBackPorch = 29,
	          hDisplay = 640, hFrontPorch = 16, hSyncWidth = 96, hBackPorch = 48;

	reg [9:0] hCounter;
	reg [9:0] vCounter;
	reg vSyncComplete, display;
	reg clkDiv;

	always @( posedge clkDiv or negedge rst ) begin
		if( rst == 1'b0 ) begin
			hCounter <= 0;
			vCounter <= 0;
			vSyncComplete <= 0;
			display <= 0;
			
			vSync <= 1;
			hSync <= 1;
			
			color <= 3'b100;
		end
		else begin
			hCounter <= hCounter + 1;
			if( vSyncComplete ) begin
				if( hCounter == hDisplay - 1 ) display <= 0;
				if( hCounter == hDisplay + hFrontPorch - 1 ) hSync <= 0;
				if( hCounter == hDisplay + hFrontPorch + hSyncWidth - 1 ) hSync <= 1;
				if( hCounter == hDisplay + hFrontPorch + hSyncWidth + hBackPorch - 1) display <= 1;
			end
			if( hCounter == 799 ) begin
				hCounter <= 0;
				vCounter <= vCounter + 1;
				if( vCounter == vFrontPorch - 1 ) vSync <= 0;
				if( vCounter == vFrontPorch + vSyncWidth - 1 ) vSync <= 1;
				if( vCounter == vFrontPorch + vSyncWidth + vBackPorch - 1 ) vSyncComplete <= 1;
				if( vCounter == vFrontPorch + vSyncWidth + vBackPorch + vDisplay - 1) begin
					vCounter <= 0;
					vSyncComplete <= 0;
				end
			end
		end
	end
	
	always @( posedge clk or negedge rst ) begin
		if( rst == 1'b0 ) begin
			clkDiv <= 0;
		end
		else begin
			clkDiv <= ~clkDiv;
		end
	end
endmodule
