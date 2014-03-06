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
	reg starting;
	
	reg [2:0] command;
	reg [2:0] state, nextState;
	reg [3:0] delay;
	
	assign sd_RAS = command[2];
	assign sd_CAS = command[1];
	assign sd_WE = command[0];

	parameter loadModeRegister = 3'b000, autoRefresh = 3'b001, precharge = 3'b010,
		selectBankActivateRow = 3'b011, writeCommand = 3'b100, readCommand = 3'b101,
		noop = 3'b111;

	parameter noopS = 0,
		prechargeS = 1,
		loadExtendedModeS = 2,
		loadModeS = 3,
		autoRefreshS = 4,
		autoRefreshInitialS = 5,
		finalLoadModeS = 6,
		initCompleteS = 7;
	
	// Values from the datasheet
	parameter tRP = 3, tMRD = 2, tRFC = 11;
		

	always @( posedge clk25 or posedge rst ) begin
		if( rst ) begin
			startupDelay <= 0;
			starting <= 1;
			delay <= 0;
		end else begin
			startupDelay <= startupDelay + 1;
			if( startupDelay == 5000 ) begin
				starting <= 0;
			end
		end
	end
	
	always @( posedge clk133_n or posedge starting ) begin
		if( starting ) begin
			sd_CKE <= 0;
			sd_CS <= 1;
			command <= 0;
			state <= noopS;
			nextState <= 0;
			sd_A <= 0;
			sd_BA <= 0;
		end else begin
			sd_CKE <= 1;
			sd_CS <= 0;
			
			delay <= delay + 1;
			case( state )
				noopS: begin
					command <= noop;
					state <= prechargeS;
					nextState <= loadExtendedModeS;
					delay <= 0;
				end prechargeS: begin
					if( delay == 0 ) begin
						command <= precharge;
						sd_A[10] <= 1;
					end else
						command <= noop;
					if( delay == tRP - 1 ) begin
						state <= nextState;
						delay <= 0;
					end
				end loadExtendedModeS: begin
					if( delay == 0 ) begin
						command <= loadModeRegister;
						sd_BA <= 2'b01;
						sd_A <= 0;
					end else
						command <= noop;
					if( delay == tMRD - 1 ) begin
						state <= loadModeS;
						delay <= 0;
					end
				end loadModeS: begin
					if( delay == 0 ) begin
						command <= loadModeRegister;
						sd_BA <= 2'b00;
						sd_A <= 13'b0000_0_0_010_0_001;
					end else
						command <= noop;
					if( delay == tMRD - 1 ) begin
						state <= prechargeS;
						nextState <= autoRefreshInitialS;
						delay <= 0;
					end
				end autoRefreshS: begin
					if( delay == 0 )
						command <= autoRefresh;
					else
						command <= noop;
					if( delay == tRFC - 1 ) begin
						state <= nextState;
						delay <= 0;
					end
				end autoRefreshInitialS: begin
					if( delay == 0 )
						command <= autoRefresh;
					else
						command <= noop;
					if( delay == tRFC - 1 ) begin
						state <= autoRefreshS;
						nextState <= finalLoadModeS;
						delay <= 0;
					end
				end finalLoadModeS: begin
					if( delay == 0 ) begin
						command <= loadModeRegister;
						sd_BA <= 2'b00;
						sd_A <= 13'b0000_0_0_010_0_001;
					end else
						command <= noop;
					if( delay == tMRD - 1 ) begin
						state <= initCompleteS;
						delay <= 0;
					end
				end
			endcase
		end
	end
endmodule
