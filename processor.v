module processor(Data, w, Sys_Clock, PB, PB2, Done, BusWires, hex5, hex2, hex1, hex0);
	
	input w, Sys_Clock, PB, PB2;
	input [7:0]Data;
	output wire[7:0]BusWires;
	output Done;
	wire Clk, Clk2;
	wire [1:0]Count;
	wire [2:0]I_Display;
	output [0:6]hex5, hex2, hex1, hex0;
	wire[7:0]Bus_Reg;
	
	debouncer(Sys_Clock, PB, Clk);
	debouncer(Sys_Clock, PB2, Clk2);

	proc(Data, w, Clk, Clk2, Data[6:4], Data[3:2], Data[1:0], Done, BusWires, Count, Bus_Reg);
	
	regn instruction(Data[6:4], {~Count & w}, Clk, I_Display); 
		defparam instruction.n = 3;
	
	
	seg7 I_Step(Count, hex5);
	seg7 Instruct_Display(I_Display, hex2);
	seg7 LEFT_SEG(Bus_Reg[7:4], hex1);
	seg7 RIGHT_SEG(Bus_Reg[3:0], hex0);
	
	
endmodule

module proc(Data, w, Clock, Clock2, F, Rx, Ry, Done, BusWires, Count, Bus_Reg);
	input[7:0] Data;
	input w, Clock, Clock2;
	input [2:0]F;
	input [1:0]Rx, Ry;
	output wire [7:0]BusWires;
	output reg [7:0]Bus_Reg;
	output Done;
	reg [0:3] Rin, Rout;
	reg [7:0] Sum;
	wire Clear, Extern, Ain, Gin, Gout, FRin;
	output wire [1:0]Count;
	wire [0:3]T, Xreg, Y;
	wire [0:6]I;
	wire [7:0]R0, R1, R2, R3, A, G;
	wire [6:0]Func, FuncReg;
	wire [2:0]Instruction;
	integer k;
	//output [2:0]I_Display;
	
	upcount counter(Clear, Clock, Count);
	dec2to4 decT(Count, 1'b1, T);
	
	assign Clear = Done | (~w & T[0]);
	assign Func = {F, Rx, Ry};
	assign FRin = w & T[0];
	
	regn case_reg(F, FRin, Clock, Instruction);
		defparam case_reg.n = 3;

	regn functionreg(Func, FRin, Clock, FuncReg);
		defparam functionreg.n = 7;

	dec3to8 decI(FuncReg[6:4], 1'b1, I);
	dec2to4 decX(FuncReg[3:2], 1'b1, Xreg);
	dec2to4 decY(FuncReg[1:0], 1'b1, Y);
	
	assign Extern = I[0] & T[1];
	assign Done = ((I[0] | I[1])& T[1]) | ((I[2] | I[3] | I[4] | I[5]) & T[3]) | (I[6] & T[2]);
	assign Ain = (I[2] | I[3] | I[4] | I[5]) & T[1];
	assign Gin = ((I[2] | I[3] | I[4] | I[5]) & T[2]) | (I[6] & T[1]);
	assign Gout = ((I[2] | I[3] | I[4] | I[5]) & T[3]) | (I[6] & T[2]);

	

	always @(I, T, Xreg, Y)
		for(k = 0; k < 4; k = k+1)
		begin
			Rin[k] =((I[0] | I[1]) & T[1] & Xreg[k]) | ((I[2] | I[3] | I[4] | I[5]) & T[3] & Xreg[k]) | (I[6] & (T[2] & Xreg[k]));
			Rout[k] =(I[1]  & T[1] & Y[k]) | ((I[2] | I[3] | I[4] | I[5]) & ((T[1] & Xreg[k]) | (T[2] & Y[k]))) | (I[6] & (T[1] & Xreg[k]));
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
	always @(Instruction, A, BusWires)
	begin
	
		case(Instruction)
			2: Sum = A + BusWires;
							
			3: Sum = A - BusWires;
							
			4: Sum = A || BusWires;

			5: Sum = A && BusWires;
						
			6: Sum =  ~BusWires;	
		endcase
	end

		always@(R0, R1, R2, R3, BusWires)
		begin
			if(~Clock2)
				case(Func[1:0])
					0: Bus_Reg = R0;
					1: Bus_Reg = R1;
					2: Bus_Reg = R2;
					3: Bus_Reg = R3;
				endcase
			else
				Bus_Reg = BusWires;
		end
		
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
	
