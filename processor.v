module proc(Data, Reset, w, Clock, F, Rx, Ry, Done, BusWires);
	input[7:0] Data;
	input Reset, w, Clock;
	input [1:0]F, Rx, Ry;
	output wire [7:0]BusWires;
	output Done;
	reg [0:3] Rin, Rout;
	reg [7:0] Sum;
	wire Clear, AddSub, Extern, Ain, Gin, Gout, FRin;
	wire [1:0]Count;
	wire [0:3]T, I, Xreg, Y;
	wire [7:0]R0, R1, R2, R3, A, G;
	wire [1:6]Func, FuncReg;
	integer k;
	
	upcount counter(Clear, Clock, Count);
	dec2to4 decT(Count, 1'b1, T);
	
	assign Clear = Reset | Done | (~w & T[0]);
	assign Func = {F, Rx, Ry};
	assign FRin = w & T[0];
	
	regn functionreg(Func, FRin, Clock, FuncReg);
		defparam functionreg.n = 6;
	dec2to4 decI(FuncReg[1:2], 1'b1, Xreg);
	dec2to4 decX(FuncReg[3:4], 1'b1, Xreg);
	dec2to4 decY(FuncReg[5:6], 1'b1, Y);
	
	assign Extern = I[0] & T[1];
	assign Done = ((I[0] | I[1])& T[1]) | ((I[2] | I[3]) & T[3]);
	assign Ain = (I[2] | I[3]) & T[1];
	assign Gin = (I[2] | I[3]) & T[2];
	assign Gout = (I[2] | I[3]) & T[3];
	assign AddSub = I[3];