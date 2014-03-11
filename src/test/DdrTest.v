`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module DdrTest;
	reg clk25, clk133_p, clk133_n, clk133_90, clk133_270, rst;

	wire [12:0] sd_A;
	wire [1:0] sd_BA;
	wire sd_RAS,  sd_CAS,  sd_WE,  sd_CKE,  sd_CS,  sd_LDM,  sd_UDM;

	// Bidirs
	wire [15:0] sd_DQ;
	wire sd_LDQS, sd_UDQS;
	
	wire [15:0] readData;

	Ddr uut (
		.clk25( clk25 ),
		.clk133_p( clk133_p ),
		.clk133_n( clk133_n ),
		.clk133_90( clk133_90 ),
		.clk133_270( clk133_270 ),
		.rst( rst ),
		.readData( readData ),
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
	
	assign sd_DQ = reading ? readSd_DQ : 16'bZZZZZZZZZZZZZZZZ;

	initial begin
		clk25 = 0;
		clk133_p = 1;
		clk133_n = 0;
		clk133_90 = 0;
		clk133_270 = 1;
		rst = 1;
		reading = 0;

		#5 rst = 0;
		`assert( sd_CKE == 0 );
		`assert( sd_DQ == 16'bZZZZZZZZZZZZZZZZ );
		`assert( sd_LDQS == 1'bZ );
		`assert( sd_UDQS == 1'bZ );
		
		// Wait 200us then noop
		#200019 `assert( sd_CKE == 1 && sd_CS == 0 && command == 3'b111 );
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
		// Active command
		#1564.714 `assert( command == 3'b011 );
		#7.518 `assert( command == 3'b111 );
		#7.518 `assert( command == 3'b111 );
		// Write command
		#7.518 `assert( command == 3'b100 );
		`assert( sd_A[10] == 0 );
		#1.8795 `assert( sd_LDQS == 0 && sd_UDQS == 0 );
		#1.8795 #3.759 `assert( sd_DQ == 16'h5555 );
		#1.8795 `assert( sd_LDQS == 1 && sd_UDQS == 1 );
		#1.8795 `assert( sd_DQ == 16'hAAAA );
		#1.8795 `assert( sd_LDQS == 0 && sd_UDQS == 0 );
		#1.8795 #7.518 `assert( command == 3'b101 );
		#7.518 #7.518 reading = 1;
		readSd_DQ = 15'h0F0F;
		#3.759 `assert( readData == 15'h0F0F );
		readSd_DQ = 15'hF0F0;
		#3.759 `assert( readData == 15'hF0F0 );
		reading = 0;
	end

	always begin
		#20 clk25 = ~clk25;
	end

	always begin
		#1.8795 clk133_90 = ~clk133_90;
		clk133_270 = ~clk133_270;
		#1.8795 clk133_p = ~clk133_p;
		clk133_n = ~clk133_n;
	end
endmodule
