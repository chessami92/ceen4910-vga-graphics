`timescale 1ns / 1ps

module RotaryButton(
	input clk, rst, rotA, rotB, rotCenter,
	output reg left, right, down
	);
	
	reg rotaryQ1, rotaryQ2, rotaryQ1Delay, downAck;
	reg [8:0] debounce;
	
	always @( posedge clk or posedge rst ) begin
		if( rst ) begin
			rotaryQ1 <= 1;
			rotaryQ2 <= 0;
			rotaryQ1Delay <= 1;
			debounce <= 0;
		end else begin
			//Inputs when turning the knob according to the datasheet
			case ( {rotB, rotA} )
				2'b00: begin 
					rotaryQ1 <= 0; 
					rotaryQ2 <= rotaryQ2; 
				end
				2'b01: begin 
					rotaryQ1 <= rotaryQ1;
					rotaryQ2 <= 0;
				end
				2'b10: begin
					rotaryQ1 <= rotaryQ1;
					rotaryQ2 <= 1;
				end
				2'b11: begin
					rotaryQ1 <= 1;
					rotaryQ2 <= rotaryQ2;
				end
			endcase 
			
			rotaryQ1Delay <= rotaryQ1;
			//Interpretation of state machine according to datasheet
			if( rotaryQ1 == 1 && rotaryQ1Delay == 0 ) begin
				if( rotaryQ2 == 1 ) begin
					left <= 0;
					right <= 1;
				end else if( rotaryQ2 == 0 ) begin
					left <= 1;
					right<= 0;
				end
			end else begin //if(rotaryQ1 == 0) begin
				left <= 0;
				right <= 0;
			end
			
			//Debouncing for rotary button press
			if( rotCenter == 0 ) begin
				debounce <= 0;
				down <= 0;
				downAck <= 0;
			end else if(debounce == 9'hFFF && downAck == 0) begin
				down <= 1;
				downAck <= 1;
			end else if(downAck == 1) begin
				down <= 0;
			end else begin
				debounce <= debounce + 1;
			end
		end
	end
endmodule
