module dda (
    input clk,
    input rst,
	input en,
    output [N-1:0] x,y,z, // Dynamic system state variables
    input [N-1:0] icx, icy, icz, // Initial conditions
    input [N-1:0] sigma, beta, rho, // Parameters
    input [N-1:0] dt // Time step
);
// Posit parameters
parameter N = 16;
parameter ES = 1;

// Multiplications
wire [N-1:0] w_mult_sigma_sub_y_x,  w_mult_x_sub_rho_z, w_mult_beta_z, w_mult_x_y;

// Subtractions
wire [N-1:0] w_sub_y_x, w_sub_rho_z, w_sub_xy_betaz, w_sub_mult_x_sub_rho_z_y;

posit_sub #(.N(N),.ES(ES)) sub_y_x(.in1(y), .in2(x), .out(w_sub_y_x)); // Subtract y - x
posit_sub #(.N(N),.ES(ES)) sub_rho_z(.in1(rho), .in2(z), .out(w_sub_rho_z)); // Subtract rho - z
posit_sub #(.N(N),.ES(ES)) sub_xy_betaz(.in1(w_mult_x_y), .in2(w_mult_beta_z), .out( w_sub_xy_betaz)); // Subtract xy - beta z
posit_sub #(.N(N),.ES(ES)) sub_mult_x_sub_rho_z_y(.in1(w_mult_x_sub_rho_z), .in2(y), .out( w_sub_mult_x_sub_rho_z_y)); // Subtract x(rho - z) -y

posit_mult #(.N(N),.ES(ES)) mult_sigma_sub_y_x(.in1(sigma), .in2(w_sub_y_x), .out(w_mult_sigma_sub_y_x)); // Multiply sigma(y-x)
posit_mult #(.N(N),.ES(ES)) mult_x_sub_rho_z(.in1(x), .in2(w_sub_rho_z), .out(w_mult_x_sub_rho_z)); // Multiply x(rho - z)
posit_mult #(.N(N),.ES(ES)) mult_beta_z(.in1(z), .in2(beta), .out(w_mult_beta_z)); // Multiply beta z
posit_mult #(.N(N),.ES(ES)) mult_x_y(.in1(x), .in2(y), .out(w_mult_x_y)); // Multiply x y

// Lorenz equation
// dx/dt = sigma*(y - x)
// dy/dt = x*(rho - z) - y
// dz/dt = x*y - beta*z

euler_integrator  #(.N(N),.ES(ES)) int1(.out(x), .funct(w_mult_sigma_sub_y_x), .dt(dt), .ic(icx), .clk(clk), .rst(rst), .en(en));
euler_integrator  #(.N(N),.ES(ES)) int2(.out(y), .funct(w_sub_mult_x_sub_rho_z_y), .dt(dt), .ic(icy), .clk(clk), .rst(rst), .en(en));
euler_integrator  #(.N(N),.ES(ES)) int3(.out(z), .funct(w_sub_xy_betaz), .dt(dt), .ic(icz), .clk(clk), .rst(rst), .en(en));

endmodule

// Substracts two posits
module posit_sub (
	input [N-1:0] in1, in2,
	output [N-1:0] out
);
	parameter N = 16;
	parameter ES = 1;

	wire [N-1:0] minus_in2;
	assign minus_in2 = {~in2[N-1],~in2[N-2:0]+1'b1};

	posit_add #(.N(N),.ES(ES)) sub(.in1(in1), .in2(minus_in2), .out(out));
endmodule



/// Euler integrator
module euler_integrator(out, funct, en, clk, rst, dt, ic);
	parameter N = 16;
	parameter ES = 1;

	input clk, rst, en;
	output [N-1:0] out; // state variable
	input [N-1:0] funct; // the dV/dt function
	input [N-1:0] dt; // time step
	input [N-1:0] ic; // initial condition

	wire [N-1:0] out, v1new;
	reg [N-1:0] v1;

	wire [N-1:0] out_mult;
	wire inf_add, inf_mult;

	// compute new state variable with dt 
	// v1(n+1) = v1(n) + dt*funct(n)

	posit_mult  #(
		.N(N),
		.ES(ES)
	) mult (
		.in1(funct),
		.in2(dt),
		.out(out_mult),
		.inf(inf_mult)
	);

	posit_add #(
		.N(N),
		.ES(ES)
	)
	add(
		.in1(out_mult),
		.in2(v1),
		.out(v1new),
		.inf(inf_add)
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

