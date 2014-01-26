`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module VgaControllerTest;
	reg clk;
	reg rst;

	wire vgaRed, vgaGreen, vgaBlue;
	wire vSync, hSync;
	
	reg vSyncChange, hSyncChange;
	integer i;

	VgaController uut (
		.clk( clk ), 
		.rst( rst ), 
		.vgaRed( vgaRed ),
		.vgaGreen( vgaGreen ),
		.vgaBlue( vgaBlue ),
		.vSync( vSync ),
		.hSync( hSync )
	);

	initial begin
		clk = 1;
		rst = 0;
		vSyncChange = 1'b1;
		hSyncChange = 1'b1;

		#25 `assert( hSync == 1'b1 && vSync == 1'b1 );
		rst = 1;
		vSyncChange = 1'b0;
		hSyncChange = 1'b0;

		/* Initial vSync Pulse */
		#319974 vSyncChange = 1'b1;
		#2 vSyncChange = 1'b0;
		#63998 vSyncChange = 1'b1;
		#2 vSyncChange = 1'b0;
		#928000; /* vSync back porch */

		while( 1 ) begin
			for( i = 0; i < 480; i = i + 1 ) begin
				#25600 #638 hSyncChange = 1'b1;
				#2 hSyncChange = 1'b0;
				#3838 hSyncChange = 1'b1;
				#2 hSyncChange = 1'b0;
				#1920; /* hSync back porch */
			end

			#319998 vSyncChange = 1'b1;
			#2 vSyncChange = 1'b0;
			#63998 vSyncChange = 1'b1;
			#2 vSyncChange = 1'b0;
			#928000; /* vSync back porch */
		end
	end
	
	always @( vSync ) begin
		`assert( vSyncChange == 1'b1 );
	end
	
	always @( hSync ) begin
		`assert( hSyncChange == 1'b1 );
	end
	
	always begin
		#10 clk = ~clk;
	end
endmodule

