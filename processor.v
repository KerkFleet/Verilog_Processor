module processor(Data, w, Sys_Clock, PB, Done, BusWires, CurI);
	
	input w, Sys_Clock, PB;
	input [7:0]Data;
	output wire[7:0]BusWires;
	output Done;
	output [0:6]CurI;
	wire empty;
	wire Clk;
	assign empty = 0;
	
	debouncer(Sys_Clock, PB, Clk);

	proc(Data, w, Clk, Data[6:4], Data[3:2], Data[1:0], Done, BusWires);
	
	
endmodule

module proc(Data, w, Clock, F, Rx, Ry, Done, BusWires);
	input[7:0] Data;
	input w, Clock;
	input [2:0]F;
	input [1:0]Rx, Ry;
	output wire [7:0]BusWires;
	output Done;
	reg [0:3] Rin, Rout;
	reg [7:0] Sum;
	wire Clear, AddSub, And, Or, complement, Extern, Ain, Gin, Gout, FRin;
	wire [1:0]Count;
	wire [0:3]T, Xreg, Y;
	wire [0:6]I;
	wire [7:0]R0, R1, R2, R3, A, G;
	wire [6:0]Func, FuncReg;
	integer k;
	
	upcount counter(Clear, Clock, Count);
	dec2to4 decT(Count, 1'b1, T);
	
	assign Clear = Done | (~w & T[0]);
	assign Func = {F, Rx, Ry};
	assign FRin = w & T[0];
	
	regn functionreg(Func, FRin, Clock, FuncReg);
		defparam functionreg.n = 7;
	dec3to8 decI(FuncReg[6:4], 1'b1, I);
	dec2to4 decX(FuncReg[3:2], 1'b1, Xreg);
	dec2to4 decY(FuncReg[1:0], 1'b1, Y);
	
	assign Extern = I[0] & T[1];
	assign Done = ((I[0] | I[1])& T[1]) | ((I[2] | I[3]) & T[3]);
	assign Ain = (I[2] | I[3]) & T[1];
	assign Gin = (I[2] | I[3]) & T[2];
	assign Gout = (I[2] | I[3]) & T[3];
	assign AddSub = I[3];
	

	always @(I, T, Xreg, Y)
		for(k = 0; k < 4; k = k+1)
		begin
			Rin[k] =((I[0] | I[1]) & T[1] & Xreg[k]) | ((I[2] | I[3]) & T[3] & Xreg[k]);
			Rout[k] =(I[1] & T[1] & Y[k]) | ((I[2] | I[3]) & ((T[1] & Xreg[k])| (T[2] & Y[k])));
		end

	trin tri_ext (Data, Extern, BusWires);
	regn reg_0 (BusWires, Rin[0], Clock, R0);
	regn reg_1 (BusWires, Rin[1], Clock, R1);
	regn reg_2 (BusWires, Rin[2], Clock, R2);
	regn reg_3 (BusWires, Rin[3], Clock, R3);

	trin tri_0 (R0, Rout[0], BusWires);
	trin tri_1 (R1, Rout[1], BusWires);
	trin tri_2 (R2, Rout[2], BusWires);
	trin tri_3 (R3, Rout[3], BusWires);
	regn reg_A (BusWires, Ain, Clock, A);

	//alu
	always @(AddSub, A, BusWires)
		if(!AddSub)
			Sum = A + BusWires;
		else 
			Sum = A - BusWires;

		regn reg_G(Sum, Gin, Clock, G);
		trin tri_G(G, Gout, BusWires);

endmodule
	
					 //upcount module
	module upcount (Clear, Clock, Q);
		input Clear, Clock;
		output reg [1:0] Q;

		always @(posedge Clock)
			if (Clear)
				Q <= 0;
			else
				Q <= Q + 1;

	endmodule
	
		//behavioral 2_4 decoder
	module dec2to4(w, en, y);

		input en;
		input [1:0]w;
		output reg [3:0]y;
		
		always@(w, en)
			if(en == 0)
				y = 4'b0000;
			else
				case(w)
					0: y <= 4'b1000;
					1: y <= 4'b0100;
					2: y <= 4'b0010;
					3: y <= 4'b0001;
				endcase
	endmodule
	
	module dec3to8(w, en, y);
	
	input en;
	input [2:0]w;
	output reg [6:0]y;
	
	always@(w, en)
		if(en == 0)
			y = 7'b0000000;
		else
			case(w)
				0: y <= 7'b1000000;
				1: y <= 7'b0100000;
				2: y <= 7'b0010000;
				3: y <= 7'b0001000;
				4: y <= 7'b0000100;
				5: y <= 7'b0000010;
				6: y <= 7'b0000001;
			endcase
	endmodule
	
	
	//regn module
	module regn(R, L, Clock, Q);
		parameter n =8;
		input [n-1:0]R;
		input L, Clock;
		output reg [n - 1:0]Q;

		always @ (posedge Clock)
			if(L)
				Q <= R;

	endmodule


	//trin module
	module trin(Y, E, F);
		parameter n = 8;
		input [n-1:0]Y;
		input E;
		output wire [n-1:0]F;

		assign F = E ? Y : 'bz;

	endmodule
	
module debouncer(
    input clk, //this is a 50MHz clock provided on FPGA pin PIN_Y2
    input PB,  //this is the input to be debounced
     output reg PB_state  //this is the debounced switch
	);
	
	/*This module debounces the pushbutton PB.
	 *It can be added to your project files and called as is:
	 *DO NOT EDIT THIS MODULE
	 */

	// Synchronize the switch input to the clock
	reg PB_sync_0;
	always @(posedge clk) 
		PB_sync_0 <= PB; 
		
	reg PB_sync_1;
	always @(posedge clk) 
		PB_sync_1 <= PB_sync_0;

	// Debounce the switch
	reg [15:0]PB_cnt;
	
	always @(posedge clk)
	if(PB_state==PB_sync_1)
		PB_cnt <= 0;
	else
	begin
		PB_cnt <= PB_cnt + 1'b1;  
		if(PB_cnt == 16'hffff) PB_state <= ~PB_state;  
	end
	
endmodule


//7-segment display
module seg7 (hex, leds);
	input [3:0] hex;
	output reg [1:7] leds;
	always @(hex)
		case (hex) //abcdefg
			0: leds = 7'b0000001;
			1: leds = 7'b1001111;
			2: leds = 7'b0010010;
			3: leds = 7'b0000110;
			4: leds = 7'b1001100;
			5: leds = 7'b0100100;
			6: leds = 7'b0100000;
			7: leds = 7'b0001111;
			8: leds = 7'b0000000;
			9: leds = 7'b0000100;
			10: leds = 7'b0001000;
			11: leds = 7'b1100000;
			12: leds = 7'b0110001;
			13: leds = 7'b1000010;
			14: leds = 7'b0110000;
			15: leds = 7'b0111000;
		endcase
endmodule
