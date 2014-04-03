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
	input read,
	input [23:0] readAddress,
	output reg readAcknowledge,
	output reg [15:0] readData,
	input write,
	input [23:0] writeAddress,
	output reg writeAcknowledge,
	input wire [15:0] writeData,

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

	reg dqs;

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
		mainPrechargeS = 12,
		mainAutoRefreshS = 13;

	// Values from the datasheet
	parameter tRP = 3, tMRD = 2, tRFC = 11, tRCD = 3;
	parameter writeLength = 3, readLength = 5;
	
	assign sd_RAS = command[2];
	assign sd_CAS = command[1];
	assign sd_WE = command[0];

	assign sd_DQ = ( state == mainWriteS ) ? writeData : 16'hZZZZ;
	assign sd_LDQS = ( state == mainWriteS ) ? dqs : 1'bz;
	assign sd_UDQS = ( state == mainWriteS ) ? dqs : 1'bz;
	assign sd_LDM = 0;
	assign sd_UDM = 0;

	always @( negedge clk133_p or posedge rst ) begin
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

	always @( negedge clk133_p or posedge starting ) begin
		if( starting ) begin
			state <= initNoopS;

			command <= 0;
			delay <= 5;

			dqs <= 0;
			readAcknowledge <= 0;
			writeAcknowledge <= 0;

			readData <= 0;

			sd_CKE <= 0;
			sd_CS <= 1;
			sd_A <= 0;
			sd_BA <= 0;
		end else begin
			sd_CKE <= 1;
			sd_CS <= 0;

			if( !read )
				readAcknowledge <= 0;

			if( !write )
				writeAcknowledge <= 0;

			if( state == mainReadS && sd_DQ != 0 )
				readData <= sd_DQ;

			if( state == mainWriteS )
				dqs <= ~dqs;
			else
				dqs <= 0;

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
					sd_A <= 13'b000000_010_0_001;
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
					sd_A <= 13'b000000_010_0_001;
					sd_BA <= 2'b00;
				end initLoadMode1S: begin
					if( initComplete )
						state <= mainIdleS;
				end mainIdleS: begin
					if( write && !writeAcknowledge ) begin
						state <= mainActiveS;
						`ddrActivate
						sd_A <= writeAddress[21:9];
						sd_BA <= writeAddress[23:22];
					end else if( read && !readAcknowledge ) begin
						state <= mainActiveS;
						`ddrActivate
						sd_A <= readAddress[21:9];
						sd_BA <= readAddress[23:22];
					end
				end mainActiveS: begin
					if( write && !writeAcknowledge ) begin
						state <= mainWriteS;
						sd_A <= {3'b001, writeAddress[8:0], 1'b0};
						`ddrWrite
					end else if( read && !readAcknowledge ) begin
						state <= mainReadS;
						sd_A <= {3'b001, readAddress[8:0], 1'b0};
						readData <= 0;
						`ddrRead
					end else begin
						state <= mainIdleS;
					end
					sd_BA <= 2'b00;
				end mainWriteS: begin
					state <= mainIdleS;
					writeAcknowledge <= 1;
				end mainReadS: begin
					state <= mainIdleS;
					readAcknowledge <= 1;
				end mainAutoRefreshS: begin
					state <= mainIdleS;
					`ddrAutoRefresh
				end
				endcase
			end
		end
	end
endmodule
