`default_nettype none

module dda (
    input clk,
    input rst_n,
	input en,
    output [N-1:0] v1, v2,
    input [N-1:0] ic1, ic2,
    input [N-1:0] vK_M, vD_M,
    input [N-1:0] dt
);
parameter N = 16;
parameter ES = 2;

// 2nd order system state variables
// wire [N-1:0] v1, v2;

wire [N-1:0] v1xK_M, v2xD_M;

reg [N-1:0] dv2_dt_sum;
wire [N-1:0] dv2_dt;

posit_mult #(.N(N),.ES(ES)) K_M(.in1(v1), .in2(vK_M), .out(v1xK_M)); // Multiply v1 by k/m
posit_mult #(.N(N),.ES(ES)) D_M(.in1(v2), .in2(vD_M), .out(v2xD_M)); // Multiply v2 by d/m

// Calculate (-k/m)*v1 - (d/m)*v2 
// first add v1xK_M and v2xD_M
posit_add #(.N(N),.ES(ES)) dv2_dt_sum0(.in1(v1xK_M), .in2(v2xD_M), .out(dv2_dt_sum));
// and then multiply by -1
assign dv2_dt = {~dv2_dt_sum[N-1],dv2_dt_sum[N-2:0]};


// Damped spring-mass equations
// dv1/dt = v2
// dv2/dt = (-k/m)*v1 - (d/m)*v2
euler_integrator  #(.N(N),.ES(ES)) int1(.out(v1), .funct(v2), .dt(dt), .ic(ic1), .clk(clk), .rst_n(rst_n), .en(en));
euler_integrator  #(.N(N),.ES(ES)) int2(.out(v2), .funct(dv2_dt), .dt(dt), .ic(ic2), .clk(clk), .rst_n(rst_n), .en(en));

endmodule

/// Euler integrator
module euler_integrator(out, funct, en, clk, rst_n, dt, ic);
	parameter N = 16;
	parameter ES = 2;

	input clk, rst_n, en;
	output [N-1:0] out; // state variable
	input [N-1:0] funct; // the dV/dt function
	input [N-1:0] dt; // time step
	input [N-1:0] ic; // initial condition

	wire [N-1:0] out, v1new;
	reg [N-1:0] v1;

	wire [N-1:0] out_mult;
	reg zero_mult, inf_mult;
	reg zero_add, inf_add;

	// compute new state variable with dt 
	// v1(n+1) = v1(n) = dt*funct(n)

	posit_mult  #(
		.N(N),
		.ES(ES)
	) mult (
		.in1(funct),
		.in2(dt),
		.out(out_mult),
		.inf(inf_mult),
		.zero(zero_mult)
	);

	posit_add #(
		.N(N),
		.ES(ES)
	)
	posit_add0(
		.in1(out_mult),
		.in2(v1),
		.out(v1new),
		.inf(inf_add),
		.zero(zero_add)
	);

	always @(posedge clk)
	begin
		if(en) begin	
			if (!rst_n)
				v1 <= ic;
			else
				v1 <= v1new;
		end
	end
	assign out = v1;

endmodule

