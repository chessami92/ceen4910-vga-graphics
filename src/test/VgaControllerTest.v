`timescale 1ns / 1ps
`define assert(condition) if(!(condition)) $finish;

module VgaControllerTest;
	reg clk;
	reg rst;

	wire vSync, hSync;
	wire [8:0] row;
	wire [9:0] column;
	wire displayActive;
	
	reg vSyncChange, hSyncChange;
	integer i;

	VgaController uut (
		.clk( clk ), 
		.rst( rst ), 
		.vSync( vSync ),
		.hSync( hSync ),
		.row( row ),
		.column( column ),
		.displayActive( displayActive )
	);

	initial begin
		clk = 1;
		rst = 1;
		vSyncChange = 1;
		hSyncChange = 1;

		#25 `assert( hSync == 0 && vSync == 1 );
		rst = 0;
		vSyncChange = 0;
		hSyncChange = 0;
		
		/* Initial hSyncPulse */
		#3814 hSyncChange = 1; /* hSyncWidth */
		#2 hSyncChange = 0;

		while( 1 ) begin
			for( i = 0; i < 479; i = i + 1 ) begin
				#28158 hSyncChange = 1; /* hFrontPorch, hDisplay, and hBackPorch */
				#2 hSyncChange = 0;
				#3838 hSyncChange = 1; /* hSyncWidth */
				#2 hSyncChange = 0;
			end
			#28160 /* hBackPorch, hDisplay, and hFrontPorch */

			#1055998; vSyncChange = 1; /* vBackPorch */
			#2 vSyncChange = 0;
			#63998 vSyncChange = 1; /* vSyncWidth */
			#2 vSyncChange = 0;
			#319998 hSyncChange = 1; /* vFrontPorch */
			#2 hSyncChange = 0;
			#3838 hSyncChange = 1; /* hSyncWidth */
			#2 hSyncChange = 0;
		end
	end
	
	always @( vSync ) begin
		`assert( vSyncChange );
	end
	
	always @( hSync ) begin
		`assert( hSyncChange );
	end
	
	always begin
		#10 clk = ~clk;
	end
endmodule

