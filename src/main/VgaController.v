`timescale 1ns / 1ps

module VgaController(
	input clk,
	input rst,
	output reg vgaRed, vgaGreen, vgaBlue,
	output reg vSync, hSync	
	);

	parameter vFrontPorch = 3'b000, vPulse = 3'b001, vBackPorch = 3'b010,
	          hFrontPorch = 3'b011, hPulse = 3'b100, hBackPorch = 3'b101,
				 display = 3'b110;

	reg [9:0] hCounter;
	reg [9:0] vCounter;
	reg [2:0] state;
	reg clkDiv;

	always @( posedge clkDiv or negedge rst ) begin
		if( rst == 1'b0 ) begin
			state <= vFrontPorch;
			hCounter <= 10'b0;
			vCounter <= 10'b0;
			vgaRed <= 1'b1;
			vgaGreen <= 1'b0;
			vgaBlue <= 1'b0;
		end
		else begin
			hCounter <= hCounter + 10'b1;
			if( hCounter == 799 ) begin
				hCounter <= 10'b0;
				vCounter <= vCounter + 10'b1;
				if( ( state == vFrontPorch && vCounter == 9 ) || ( state == vPulse && vCounter == 1 ) || ( state == vBackPorch && vCounter == 28 ) ) begin
					state <= state + 1;
					vCounter <= 10'b0;
				end
			end
		end
	end
	
	always @( state ) begin
		vSync = 1'b1;
		hSync = 1'b1;
		case( state )
			vPulse: vSync = 1'b0;
			hPulse: hSync = 1'b0;
		endcase
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
