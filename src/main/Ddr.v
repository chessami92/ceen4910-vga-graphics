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
	output [31:0] readData,

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

	reg write, read;

	reg writeActive, writeLowWord;
	reg [15:0] readLowWord, readHighWord;
	reg readActive;
	reg dqsActive, dqsChange, dqsHigh, dqsLow;

	assign sd_RAS = command[2];
	assign sd_CAS = command[1];
	assign sd_WE = command[0];

	parameter writeData = 32'h76543210;

	assign sd_DQ = writeActive ? ( writeLowWord ? writeData[15:0] : writeData[31:16] ) : 16'hZZZZ;
	assign readData = {readHighWord, readLowWord};
	assign sd_LDQS = dqsActive ? ( dqsHigh != dqsLow ) : 1'bZ;
	assign sd_UDQS = dqsActive ? ( dqsHigh != dqsLow ) : 1'bZ;
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
	parameter writeLength = 5, readLength = 9;

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
			readActive <= 0;
			dqsActive <= 0;
			dqsChange <= 0;

			write <= 1;
			read <= 1;

			sd_CKE <= 0;
			sd_CS <= 1;
			sd_A <= 0;
			sd_BA <= 0;
		end else begin
			sd_CKE <= 1;
			sd_CS <= 0;

			if( state == mainReadS && delay == readLength - 3 )
				readActive <= 1;
			else
				readActive <= 0;

			dqsChange <= dqsActive;
			if( state == mainWriteS && delay == writeLength - 1 )
				dqsActive <= 1;
			else if( state == mainWriteS && delay == writeLength - 3 )
				dqsActive <= 0;

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
					if( write || read ) begin
						state <= mainActiveS;
						`ddrActivate
						sd_A <= 13'b0000000000000;
						sd_BA <= 2'b00;
					end
				end mainActiveS: begin
					if( write ) begin
						state <= mainWriteS;
						`ddrWrite
					end else if( read ) begin
						state <= mainReadS;
						`ddrRead
					end
					sd_A <= 13'b0010000000000;
					sd_BA <= 2'b00;
				end mainWriteS: begin
					state <= mainIdleS;
					write <= 0;
				end mainReadS: begin
					state <= mainIdleS;
					read <= 0;
				end
				endcase
			end
		end
	end

	always @( negedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			writeActive <= 0;
		end else begin
			if( state == mainWriteS && delay == writeLength - 2 )
				writeActive <= 1;
			else
				writeActive <= 0;
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
			dqsHigh <= 0;
		end else begin
			if( delay == writeLength - 3 ) begin
				dqsHigh <= 0;
			end
			if( dqsChange )
				dqsHigh <= ~dqsHigh;
		end
	end
	always @( negedge clk133_p or posedge starting ) begin
		if( starting ) begin
			dqsLow <= 0;
		end else begin
			if( dqsChange )
				dqsLow <= ~dqsLow;
			else
				dqsLow <= 0;
		end
	end

	always @( posedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			readLowWord <= 0;
		end else begin
			if( readActive )
				readLowWord <= sd_DQ;
		end
	end
	always @( negedge clk133_90 or posedge starting ) begin
		if( starting ) begin
			readHighWord <= 0;
		end else begin
			if( readActive )
				readHighWord <= sd_DQ;
		end
	end
endmodule
