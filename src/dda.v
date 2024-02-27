/*
 * Copyright (c) 2023 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_dda (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

// All output pins must be assigned. If not used, assign to 0.
assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
assign uio_out = 0;
assign uio_oe  = 0;

wire signed [26:0] v1, v2;

// 2nd order systyem state variables
// wire signed [26:0] v1, v2;

// signed mult output
wire signed [26:0] v1xK_M, v2xD_M;
wire [3:0] dt;
wire [26:0] ic1,ic2;

assign dt = 4'b1001;
assign ic2 = 27'b000101000000000000000000000;
assign ic1 = 27'b000000000000000000000000000;

signed_mult K_M(v1xK_M, v1, 27'h0080000); // Mult v1 by k/m
signed_mult D_M(v2xD_M, v2, 27'h0040000); // Mult v2 by d/m

// Damped spring-mass equations
// dv1/dt = v2
// dv2/dt = (-k/m)*v1 - (d/m)*v2
euler_integrator int1(.out(v1), .funct(v2), .dt(dt), .ic(ic1), .clk(clk), .rst_n(rst_n));
euler_integrator int2(.out(v2), .funct(-v1xK_M-v2xD_M), .dt(dt), .ic(ic2), .clk(clk), .rst_n(rst_n));

endmodule

/// Euler integration
module euler_integrator(out, funct, en, clk, rst_n, dt, ic);
	output signed [26:0] out; // state variable
	input signed [26:0] funct; // the dV/dt function
	input clk, rst, en;
	input [3:0] dt; // time step in units of SHIFT right
	input signed [26:0] ic; // initial conditions

	wire signed [26:0] out, v1new;
	reg signed [26:0] v1;

	always @(posedge clk)
	begin
		if(en)
		begin	
			if (!rst_n)
				v1 <= ic;
			else
				v1 <= v1new;
		end
	end
	// compute new state variable with dt = 2>>dt
	// v1(n+1) = v1(n) = dt*funct(n)
	assign v1new = v1 + (funct>>>9);
	assign out = v1;
endmodule

/// signed multiplication of 7.20 fixed point 2' complement

module signed_mult (out,a,b);
	output signed [26:0] out;
	input signed [26:0] a;
	input signed [26:0] b;

	// intermediate full bit length
	// wire signed [26:0]	out;
	wire signed [53:0] mult_out;
	
	assign mult_out = a * b;
	// select bits for 7.20 fixed point
	assign out = {mult_out[53], mult_out[45:20]};
endmodule


