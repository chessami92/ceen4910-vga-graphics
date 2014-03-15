`timescale 1ns / 1ps
`define sendDdrCommand( ddrCommand, commandDelay ) command <= ddrCommand; delay <= commandDelay - 1;
`define ddrPrecharge `sendDdrCommand( prechargeCommand, tRP )
`define ddrLoadMode `sendDdrCommand( loadModeCommand, tMRD )
`define ddrAutoRefresh `sendDdrCommand( autoRefreshCommand, tRFC )
`define ddrActivate `sendDdrCommand( activateCommand, tRCD )
`define ddrWrite `sendDdrCommand( writeCommand, writeLength )
`define ddrRead `sendDdrCommand( readCommand, readLength )
`define ddrNoop command <= noopCommand;

module Ddr(
	input clk133_p, clk133_n, clk133_90, clk133_270, rst,
	output reg [31:0] readData,

	output reg [12:0] sd_A,
	inout [15:0] sd_DQ,
	output reg [1:0] sd_BA,
	output wire sd_RAS, sd_CAS, sd_WE,
	output reg sd_CKE, sd_CS,
	output wire sd_LDM, sd_UDM,
	inout sd_LDQS, sd_UDQS
	);

	reg [14:0] longDelay;
	reg starting, initComplete;

	reg [2:0] command;
	reg [3:0] state;
	reg [3:0] delay;

	reg writeActive, writeLowWord;
	reg readActive, readActiveDelay;
	reg dqsActive, dqsChange, dqsHigh, dqsLow;

	assign sd_RAS = command[2];
	assign sd_CAS = command[1];
	assign sd_WE = command[0];

	parameter writeData = 32'h5555AAAA;

	assign sd_DQ = writeActive ? ( writeLowWord ? writeData[15:0] : writeData[31:16] ) : 16'hZZZZ;
	assign sd_LDQS = dqsActive ? ( dqsHigh != dqsLow ) : 1'bZ;
	assign sd_UDQS = sd_LDQS;
	assign sd_LDM = 0;
	assign sd_UDM = 0;

	parameter loadModeCommand = 3'b000, autoRefreshCommand = 3'b001, prechargeCommand = 3'b010,
		activateCommand = 3'b011, writeCommand = 3'b100, readCommand = 3'b101,
		noopCommand = 3'b111;

	parameter initNoopS = 0,
		initPrecharge0S = 1,
		initLoadExtendedModeS = 2,
		initLoadMode0S = 3,
		initPrecharge1 = 4,
		initAutoRefresh0S = 5,
		initAutoRefresh1S = 6,
		initLoadMode1S = 7,
		mainIdleS = 8,
		mainActiveS = 9,
		mainWriteS = 10,
		mainReadS = 11,
		mainPrechargeS = 12;

	// Values from the datasheet
	parameter tRP = 3, tMRD = 2, tRFC = 11, tRCD = 3;
	parameter writeLength = 3, readLength = 4;

	always @( posedge clk133_p or posedge rst ) begin
		if( rst ) begin
			longDelay <= 0;
			starting <= 1;
			initComplete <= 0;
		end else begin
			longDelay <= longDelay + 1;
			if( longDelay == 26600 )
				starting <= 0;
			else if( longDelay == 26820 )
				initComplete <= 1;
		end
	end

	always @( posedge clk133_n or posedge starting ) begin
		if( starting ) begin
			state <= initNoopS;

			command <= 0;
			delay <= 5;

			sd_CKE <= 0;
			sd_CS <= 1;
			sd_A <= 0;
			sd_BA <= 0;
		end else begin
			sd_CKE <= 1;
			sd_CS <= 0;

			if( delay != 0 ) begin
				delay <= delay - 1;
				`ddrNoop
			end else begin
				case( state )
				initNoopS: begin
					state <= initPrecharge0S;
					`ddrPrecharge
					sd_A[10] <= 1;
				end initPrecharge0S: begin
					state <= initLoadExtendedModeS;
					`ddrLoadMode
					sd_A <= 13'b00000000000_0_0;
					sd_BA <= 2'b01;
				end initLoadExtendedModeS: begin
					state <= initLoadMode0S;
					`ddrLoadMode
					sd_A <= 13'b0000_0_0_010_0_001;
					sd_BA <= 2'b00;
				end initLoadMode0S: begin
					state <= initPrecharge1;
					`ddrPrecharge
					sd_A[10] <= 1;
				end initPrecharge1: begin
					state <= initAutoRefresh0S;
					`ddrAutoRefresh
				end initAutoRefresh0S: begin
					state <= initAutoRefresh1S;
					`ddrAutoRefresh
				end initAutoRefresh1S: begin
					state <= initLoadMode1S;
					`ddrLoadMode
					sd_A <= 13'b0000_0_0_010_0_001;
					sd_BA <= 2'b00;
				end initLoadMode1S: begin
					if( initComplete )
						state <= mainIdleS;
				end mainIdleS: begin
					state <= mainActiveS;
					`ddrActivate
					sd_A <= 13'b0000000000000;
					sd_BA <= 2'b00;
				end mainActiveS: begin
					state <= mainWriteS;
					`ddrWrite
					sd_A <= 13'b0000000000000;
					sd_BA <= 2'b00;
				end mainWriteS: begin
					state <= mainReadS;
					`ddrRead
					sd_A <= 13'b0000000000000;
					sd_BA <= 2'b00;
				end mainReadS: begin
					state <= mainPrechargeS;
					`ddrPrecharge
					sd_A[10] <= 1;
				end /* mainPrechargeS: begin
					state <= mainIdleS;
				end*/
				endcase
			end
		end
	end

	always @( negedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			writeActive <= 0;
		end else begin
			if( delay == 0 )
				writeActive <= 0;
			else if( state == mainWriteS && delay == writeLength - 2 )
				writeActive <= 1;
		end
	end
	always @( posedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			writeLowWord <= 1;
		end else begin
			writeLowWord <= ~writeActive;
		end
	end

	always @( posedge clk133_p or posedge starting ) begin
		if( starting ) begin
			dqsActive <= 0;
			dqsHigh <= 0;
		end else begin
			if( delay == 0 ) begin
				dqsActive <= 0;
				dqsHigh <= 0;
			end else if( state == mainWriteS && delay == writeLength - 1 )
				dqsActive <= 1;
			
			if( dqsChange )
				dqsHigh <= ~dqsHigh;
		end
	end
	always @( posedge clk133_n or posedge starting ) begin
		if( starting ) begin
			dqsChange <= 0;
			dqsLow <= 0;
		end else begin
			dqsChange <= dqsActive;
			if( dqsChange )
				dqsLow <= ~dqsLow;
			else
				dqsLow <= 0;
		end
	end

	always @( negedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			readActive <= 0;
			readActiveDelay <= 0;
			readData[31:16] <= 0;
		end else begin
			readActiveDelay <= readActive;
			if( delay == 1 )
				readActive <= 0;
			else if( state == mainReadS && delay == readLength - 2 )
				readActive <= 1;
			if( readActiveDelay )
				readData[31:16] <= sd_DQ;
		end
	end
	always @( posedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			readData[15:0] <= 0;
		end else begin
			if( readActiveDelay )
				readData[15:0] <= sd_DQ;
		end
	end
endmodule
