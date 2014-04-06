`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module DdrTest;
	reg clk133_p, clk133_n, clk133_90, clk133_270, rst;

	reg read;
	reg displayData;
	reg [23:0] readAddress;
	wire readAcknowledge;
	wire [15:0] readData;
	reg write;
	reg [23:0] writeAddress;
	wire writeAcknowledge;
	reg [15:0] writeData;

	wire [12:0] sd_A;
	wire [1:0] sd_BA;
	wire sd_RAS, sd_CAS, sd_WE, sd_CKE, sd_CS, sd_LDM, sd_UDM;

	// Bidirs
	wire [15:0] sd_DQ;
	wire sd_LDQS, sd_UDQS;

	Ddr uut (
		.clk133_p( clk133_p ),
		.clk133_n( clk133_n ),
		.clk133_90( clk133_90 ),
		.clk133_270( clk133_270 ),
		.rst( rst ),
		.read( read ),
		.readAddress( readAddress ),
		.readAcknowledge( readAcknowledge ),
		.readData( readData ),
		.write( write ),
		.writeAddress( writeAddress ),
		.writeAcknowledge( writeAcknowledge ),
		.writeData( writeData ),
		.sd_A( sd_A ),
		.sd_DQ( sd_DQ ),
		.sd_BA( sd_BA ),
		.sd_RAS( sd_RAS ),
		.sd_CAS( sd_CAS ),
		.sd_WE( sd_WE ),
		.sd_CKE( sd_CKE ),
		.sd_CS( sd_CS ),
		.sd_LDM( sd_LDM ),
		.sd_UDM( sd_UDM ),
		.sd_LDQS( sd_LDQS ),
		.sd_UDQS( sd_UDQS )
	);

	wire [2:0] command;
	reg [15:0] readSd_DQ;
	reg reading;
	integer i, j;

	assign command[2] = sd_RAS;
	assign command[1] = sd_CAS;
	assign command[0] = sd_WE;
	
	assign sd_DQ = displayData ? readSd_DQ : 16'hZZZZ;

	initial begin
		clk133_p = 1;
		clk133_n = 0;
		clk133_90 = 0;
		clk133_270 = 1;
		rst = 1;
		read = 0;
		write = 0;
		displayData = 0;

		#5 rst = 0;
		`assert( sd_CKE == 0 );
		`assert( sd_DQ == 16'hZZZZ );
		`assert( sd_LDQS == 1'bZ );
		`assert( sd_UDQS == 1'bZ );
		
		// Wait 200us then noop
		#200049.56 `assert( sd_CKE == 1 && sd_CS == 0 && command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		// Precharge all
		#7.518 `assert( command == 3'b010 );
		`assert( sd_A[10] == 1 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		// Load extended mode register
		#7.518 `assert( command == 3'b000 );
		`assert( sd_BA == 2'b01 );
		`assert( sd_A == 13'b00000000000_0_0 );
		#7.518 `assert( command == 3'b111 );
		// Lode mode register
		#7.518 `assert( command == 3'b000 );
		`assert( sd_BA == 2'b00 );
		`assert( sd_A == 13'b0000_0_0_010_0_001 );
		#7.518 `assert( command == 3'b111 );
		// Precharge all
		#7.518 `assert( command == 3'b010 );
		`assert( sd_A[10] == 1 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		// Auto-refresh x2
		for( i = 0; i < 2; i = i + 1 ) begin
			#7.518 `assert( command == 3'b001 );
			for( j = 0; j < 10; j = j + 1 ) begin
				#7.518 `assert( command == 3'b111 );
			end
		end
		// Lode mode register
		#7.518 `assert( command == 3'b000 );
		`assert( sd_BA == 2'b00 );
		`assert( sd_A == 13'b0000_0_0_010_0_001 );
		#1383.312 `assert( command == 3'b111 );
		
		#3.759 write = 1;
		writeAddress = 24'h0F;
		writeData = 16'h3210;
		read = 1;
		readAddress = 13'hF0;
		// Write sequence
		// Active command
		#3.759 `assert( command == 3'b011 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		// Write command
		#7.518 `assert( command == 3'b100 );
		`assert( sd_A == 24'h41E );
		`assert( sd_LDQS == 0 && sd_UDQS == 0 );
		#7.518 #1.8795 `assert( sd_LDQS == 1 && sd_UDQS == 1 );
		#3.759 `assert( sd_LDQS == 0 && sd_UDQS == 0 );
		#1.8795;
		// Read sequence
		// Active command
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b011 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		// Read command
		#7.518 `assert( command == 3'b101 );
		`assert( sd_A == 24'h5E0 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		displayData = 1;
		readSd_DQ = 16'h0123;
		#7.518 `assert( command == 3'b111 );
	end

	always begin
		#1.8795 clk133_90 = ~clk133_90;
		clk133_270 = ~clk133_270;
		#1.8795 clk133_p = ~clk133_p;
		clk133_n = ~clk133_n;
	end
endmodule
