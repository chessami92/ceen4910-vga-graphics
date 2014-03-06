`timescale 1ns / 1ps

module Ddr(
	input clk25, clk133_p, clk133_n, rst,
	output reg [12:0] sd_A,
	inout [15:0] sd_DQ,
	output reg [1:0] sd_BA,
	output wire sd_RAS, sd_CAS, sd_WE,
   output reg sd_CKE, sd_CS, sd_LDM, sd_UDM,
	inout sd_LDQS, sd_UDQS
	);

	reg [12:0] startupDelay;
	reg starting, initComplete;

	reg [2:0] command;
	reg [2:0] state;
	reg [2:0] initState;
	reg [3:0] delay;

	reg [12:0] nextSd_A;
	reg [1:0] nextSd_BA;

	assign sd_RAS = command[2];
	assign sd_CAS = command[1];
	assign sd_WE = command[0];

	parameter loadModeRegister = 3'b000, autoRefresh = 3'b001, precharge = 3'b010,
		selectBankActivateRow = 3'b011, writeCommand = 3'b100, readCommand = 3'b101,
		noop = 3'b111;

	parameter noopS = 0,
		prechargeS = 1,
		loadModeS = 2,
		autoRefreshS = 3;

	parameter initNoopS = 0,
		initPrecharge0S = 1,
		initLoadExtendedModeS = 2,
		initLoadMode0S = 3,
		initPrecharge1 = 4,
		autoRefresh0S = 5,
		autoRefresh1S = 6,
		initLoadMode1S = 7;

	// Values from the datasheet
	parameter tRP = 3, tMRD = 2, tRFC = 11;

	always @( posedge clk25 or posedge rst ) begin
		if( rst ) begin
			startupDelay <= 0;
			starting <= 1;
			initComplete <= 0;
		end else begin
			startupDelay <= startupDelay + 1;
			if( startupDelay == 5000 )
				starting <= 0;
			else if( startupDelay == 5046 )
				initComplete <= 1;
		end
	end

	always @( delay or starting ) begin
		if( starting ) begin
			initState = initNoopS;
			state = noopS;
			nextSd_A = 0;
			nextSd_BA = 0;
		end else if( delay == 0 && initComplete == 0 ) begin
			case( initState )
				initNoopS: begin
					initState = initPrecharge0S;
					state = prechargeS;
					nextSd_A[10] = 1;
				end initPrecharge0S: begin
					initState = initLoadExtendedModeS;
					state = loadModeS;
					nextSd_A = 13'b00000000000_0_0;
					nextSd_BA = 2'b01;
				end initLoadExtendedModeS: begin
					initState = initLoadMode0S;
					state = loadModeS;
					nextSd_A = 13'b0000_0_0_010_0_001;
					nextSd_BA = 2'b00;
				end initLoadMode0S: begin
					initState = initPrecharge1;
					state = prechargeS;
					nextSd_A[10] = 1;
				end initPrecharge1: begin
					initState = autoRefresh0S;
					state = autoRefreshS;
				end autoRefresh0S: begin
					initState = autoRefresh1S;
					state = autoRefreshS;
				end autoRefresh1S: begin
					initState = initLoadMode1S;
					state = loadModeS;
					nextSd_A = 13'b0000_0_0_010_0_001;
					nextSd_BA = 2'b00;
				end initLoadMode1S: begin
					state = noopS;
				end
			endcase
		end else begin
			state = noopS;
		end
	end

	always @( posedge clk133_n or posedge starting ) begin
		if( starting ) begin
			command <= 0;
			delay <= 5;
			sd_CKE <= 0;
			sd_CS <= 1;
			sd_A <= 0;
			sd_BA <= 0;
		end else begin
			sd_CKE <= 1;
			sd_CS <= 0;

			delay <= delay - 1;
			sd_A <= nextSd_A;
			sd_BA <= nextSd_BA;

			case( state )
				prechargeS: begin
					command <= precharge;
					delay <= tRP - 1;
				end loadModeS: begin
					command <= loadModeRegister;
					delay <= tMRD - 1;
				end autoRefreshS: begin
					command <= autoRefresh;
					delay <= tRFC - 1;
				end default:
					command <= noop;
			endcase
		end
	end
endmodule
