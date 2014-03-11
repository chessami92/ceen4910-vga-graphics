`timescale 1ns / 1ps

module Ddr(
	input clk25, clk133_p, clk133_n, clk133_90, clk133_270, rst,
	output reg [15:0] readData,
	
	output reg [12:0] sd_A,
	inout [15:0] sd_DQ,
	output reg [1:0] sd_BA,
	output wire sd_RAS, sd_CAS, sd_WE,
	output reg sd_CKE, sd_CS,
	output wire sd_LDM, sd_UDM,
	inout sd_LDQS, sd_UDQS
	);

	reg [12:0] longDelay;
	reg starting, initComplete;

	reg [2:0] command;
	reg [2:0] state;
	reg [2:0] initState;
	reg [2:0] mainState;
	reg [3:0] delay;

	reg [12:0] nextSd_A;
	reg [1:0] nextSd_BA;
	reg writeActive, lowWordWrite;
	reg readActive;
	reg dqs, dqsActive;

	assign sd_RAS = command[2];
	assign sd_CAS = command[1];
	assign sd_WE = command[0];

	parameter writeData = 32'hAAAA5555;

	assign sd_DQ = writeActive ? ( lowWordWrite ? writeData[15:0] : writeData[31:16] ) : 16'hZZZZ;
	assign sd_LDQS = dqsActive ? dqs : 1'bZ;
	assign sd_UDQS = sd_LDQS;
	assign sd_LDM = 0;
	assign sd_UDM = 0;

	parameter loadModeRegister = 3'b000, autoRefresh = 3'b001, precharge = 3'b010,
		selectBankActivateRow = 3'b011, writeCommand = 3'b100, readCommand = 3'b101,
		noop = 3'b111;

	parameter noopS = 0,
		prechargeS = 1,
		loadModeS = 2,
		autoRefreshS = 3,
		activeS = 4,
		writeS = 5,
		readS = 6;

	parameter initNoopS = 0,
		initPrecharge0S = 1,
		initLoadExtendedModeS = 2,
		initLoadMode0S = 3,
		initPrecharge1 = 4,
		initAutoRefresh0S = 5,
		initAutoRefresh1S = 6,
		initLoadMode1S = 7;

	parameter mainIdleS = 0,
		mainActiveS = 1,
		mainWriteS = 2,
		mainReadS = 3,
		mainPrechargeS = 4;

	// Values from the datasheet
	parameter tRP = 3, tMRD = 2, tRFC = 11, tRCD = 3;
	parameter writeLength = 3, readLength = 4;

	always @( posedge clk25 or posedge rst ) begin
		if( rst ) begin
			longDelay <= 0;
			starting <= 1;
			initComplete <= 0;
		end else begin
			longDelay <= longDelay + 1;
			if( longDelay == 5000 )
				starting <= 0;
			else if( longDelay == 5046 )
				initComplete <= 1;
		end
	end

	always @( * ) begin
		if( starting ) begin
			state = noopS;
			initState = initNoopS;
			mainState = mainIdleS;
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
					initState = initAutoRefresh0S;
					state = autoRefreshS;
				end initAutoRefresh0S: begin
					initState = initAutoRefresh1S;
					state = autoRefreshS;
				end initAutoRefresh1S: begin
					initState = initLoadMode1S;
					state = loadModeS;
					nextSd_A = 13'b0000_0_0_010_0_001;
					nextSd_BA = 2'b00;
				end initLoadMode1S: begin
					state = noopS;
				end
			endcase
		end else if( delay == 0 && initComplete ) begin
			case( mainState )
				mainIdleS: begin
					mainState = mainActiveS;
					state = activeS;
					nextSd_A = 13'b0000000000000;
					nextSd_BA = 2'b00;
				end mainActiveS: begin
					mainState = mainWriteS;
					state = writeS;
					nextSd_A = 13'b0000000000000;
					nextSd_BA = 2'b00;
				end mainWriteS: begin
					mainState = mainReadS;
					state = readS;
					nextSd_A = 13'b0000000000000;
					nextSd_BA = 2'b00;
				end mainReadS: begin
					mainState = mainPrechargeS;
					state = prechargeS;
					nextSd_A[10] = 1;
				end /*mainPrechargeS: begin
					mainState = mainIdleS;
				end*/
			endcase
		end else begin
			state = noopS;
		end
	end

	always @( negedge clk133_p or posedge starting ) begin
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

			if( delay != 0 )
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
				end activeS: begin
					command <= selectBankActivateRow;
					delay <= tRCD - 1;
				end writeS: begin
					command <= writeCommand;
					delay <= writeLength - 1;
				end readS: begin
					command <= readCommand;
					delay <= readLength - 1;
				end default:
					command <= noop;
			endcase
		end
	end

	always @( negedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			writeActive <= 0;
		end else begin
			if( mainState != mainWriteS ) begin
				writeActive <= 0;
			end else if( delay == writeLength - 2 || writeActive ) begin
				writeActive <= 1;
			end
		end
	end
	always @( posedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			writeActive <= 0;
			lowWordWrite <= 0;
		end else begin
			lowWordWrite <= ~writeActive;
		end
	end

	always @( posedge clk133_p or negedge clk133_p or posedge starting ) begin
		if( starting || mainState != mainWriteS ) begin
			dqs <= 0;
			dqsActive <= 0;
		end else begin
			if( delay == writeLength - 1 ) begin
				dqsActive <= 1;
			end else	if( dqsActive ) begin
				dqs <= ~dqs;
			end
		end
	end

	always @( posedge clk133_90 or negedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			readActive <= 0;
		end else begin
			if( delay == readLength - 1 ) begin
				readActive <= 1;
			end else if( readActive ) begin
				if( mainState != mainReadS )
					readActive <= 0;
				readData <= sd_DQ;
			end
		end
	end
endmodule
