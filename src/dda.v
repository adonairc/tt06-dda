module dda (
    input clk,
    input rst,
	input en,
    output [N-1:0] x,y, // Dynamic system state variables
    input [N-1:0] icx, icy, // Initial conditions
    input [N-1:0] k,d// Parameters
);

// Posit parameters
parameter N = 16;
parameter ES = 1;

// Multiplications
wire [N-1:0] w_mult1, w_mult2;

posit_mult #(.N(N),.ES(ES)) mult1(.in1(k), .in2(x), .out(w_mult1)); // Multiply k*x
posit_mult #(.N(N),.ES(ES)) mult2(.in1(d), .in2(y), .out(w_mult2)); // Multiply d*y

// Subtraction
wire [N-1:0] w_sub1;

posit_add #(.N(N),.ES(ES)) sub_1(.in1(w_mult1), .in2(w_mult2), .out(w_sub1)); // Subtract k*x - d*y

// Take the negative
wire [N-1:0] w_neg_sub1;
assign w_neg_sub1 = {~w_sub1[N-1], ~w_sub1[N-2:0]+1'b1};

euler_integrator  #(.N(N),.ES(ES)) int1(.out(x), .funct(y), .ic(icx), .clk(clk), .rst(rst), .en(en));
euler_integrator  #(.N(N),.ES(ES)) int2(.out(y), .funct(w_neg_sub1), .ic(icy), .clk(clk), .rst(rst), .en(en));

endmodule

// // Substracts two posits
// module posit_sub (
// 	input [N-1:0] in1, in2,
// 	output [N-1:0] out
// );
// 	parameter N = 16;
// 	parameter ES = 1;

// 	wire [N-1:0] minus_in2;
// 	assign minus_in2 = {~in2[N-1],~in2[N-2:0]+1'b1};

// 	posit_add #(.N(N),.ES(ES)) sub(.in1(in1), .in2(minus_in2), .out(out));
// endmodule



/// Euler integrator
module euler_integrator(out, funct, en, clk, rst, ic);
	parameter N = 16;
	parameter ES = 1;

	input clk, rst, en;
	output [N-1:0] out; // state variable
	input [N-1:0] funct; // the dV/dt function
	input [N-1:0] ic; // initial condition

	wire [N-1:0] out, v1new;
	reg [N-1:0] v1;

	wire [N-1:0] out_mult;

	// compute new state variable with dt 
	// v1(n+1) = v1(n) + dt*funct(n)

	posit_mult  #(
		.N(N),
		.ES(ES)
	) mult (
		.in1(funct),
		.in2(16'h7240), // dt = 1/256
		.out(out_mult)
	);

	posit_add #(
		.N(N),
		.ES(ES)
	)
	add(
		.in1(out_mult),
		.in2(v1),
		.out(v1new)
	);

	always @(posedge clk)
	begin
		if(en) begin	
			if (rst)
				v1 <= ic;
			else
				v1 <= v1new;
		end
	end
	assign out = v1;

endmodule

