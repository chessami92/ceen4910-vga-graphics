`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module VgaControllerTest;
	reg clk;
	reg rst;

	wire [2:0] color;
	wire vSync, hSync;
	
	reg vSyncChange, hSyncChange;
	integer i;

	VgaController uut (
		.clk( clk ), 
		.rst( rst ), 
		.color( color ),
		.vSync( vSync ),
		.hSync( hSync )
	);

	initial begin
		clk = 1;
		rst = 1;
		vSyncChange = 1'b1;
		hSyncChange = 1'b1;

		#25 `assert( hSync == 1'b0 && vSync == 1'b1 );
		rst = 0;
		vSyncChange = 1'b0;
		hSyncChange = 1'b0;
		
		/* Initial hSyncPulse */
		#3814 hSyncChange = 1'b1; /* hSyncWidth */
		#2 hSyncChange = 1'b0;

		while( 1 ) begin
			for( i = 0; i < 479; i = i + 1 ) begin
				#28158 hSyncChange = 1'b1; /* hFrontPorch, hDisplay, and hBackPorch */
				#2 hSyncChange = 1'b0;
				#3838 hSyncChange = 1'b1; /* hSyncWidth */
				#2 hSyncChange = 1'b0;
			end
			#28160 /* hBackPorch, hDisplay, and hFrontPorch */

			#1055998; vSyncChange = 1'b1; /* vBackPorch */
			#2 vSyncChange = 1'b0;
			#63998 vSyncChange = 1'b1; /* vSyncWidth */
			#2 vSyncChange = 1'b0;
			#319998 hSyncChange = 1'b1; /* vFrontPorch */
			#2 hSyncChange = 1'b0;
			#3838 hSyncChange = 1'b1; /* hSyncWidth */
			#2 hSyncChange = 1'b0;
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

