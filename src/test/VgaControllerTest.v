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
		rst = 0;
		vSyncChange = 1'b1;
		hSyncChange = 1'b1;

		#25 `assert( hSync == 1'b1 && vSync == 1'b0 );
		rst = 1;
		vSyncChange = 1'b0;
		hSyncChange = 1'b0;

		/* Initial vSync Pulse */
		#63974 vSyncChange = 1'b1;
		#2 vSyncChange = 1'b0;

		while( 1 ) begin
			#927998; hSyncChange = 1'b1; /* vSync back porch */
			#2 hSyncChange = 1'b0;
			for( i = 0; i < 479; i = i + 1 ) begin
				#3838 hSyncChange = 1'b1; /* hSyncWidth */
				#2 hSyncChange = 1'b0;
				#28158 hSyncChange = 1'b1; /* hBackPorch, hDisplay, and hFrontPorch */
				#2 hSyncChange = 1'b0;
			end
			#3838 hSyncChange = 1'b1; /* hSyncWidth */
			#2 hSyncChange = 1'b0;
			#28160 /* hBackPorch, hDisplay, and hFrontPorch */

			#319998 vSyncChange = 1'b1; /* vFrontPorch */
			#2 vSyncChange = 1'b0;
			#63998 vSyncChange = 1'b1; /* vSyncWidth */
			#2 vSyncChange = 1'b0;
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

