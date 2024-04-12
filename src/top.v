/*
 * Copyright (c) 2023 Adonai Cruz
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
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
	// assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
	assign uio_out = 0;
	assign uio_oe  = 0;
	assign uo_out[0] = 0;
	assign uo_out[1] = 0;
	assign uo_out[2] = 0;
	assign uo_out[3] = 0;
	assign uo_out[4] = 0;
	assign uo_out[5] = 0;
	assign uo_out[6] = 0;
	assign uo_out[7] = 0;

	parameter N = 16;
	parameter ES = 1;
	parameter REG_SIZE = 14; // Register file size in bytes
	parameter OUT_SIZE = 6; // Output size in bytes
	parameter CLK_FREQ = 12000000; // Clock frequency (12 MHz)
	parameter BAUD_RATE = 9600; // UART baud rate

	wire rst;
	assign rst = ~rst_n;

	// // Connect UART pins
	// wire uart_tx, uart_rx;
	// assign  uart_rx = ui_in[3];
	// assign  uart_tx = uo_out[4];

	// // UART interface
	// reg uart_transmit;
	// reg [7:0] uart_tx_byte;
	// reg uart_received;
	// reg [7:0] uart_rx_byte;
	// wire uart_is_receiving;
	// wire uart_is_transmitting;
	// wire uart_recv_error;

	// uart #(
	// 	.BAUD_RATE(BAUD_RATE),                 // The baud rate in kilobits/s
	// 	.CLK_FREQ(CLK_FREQ)           // The master clock frequency (6 MHz)
	// )
	// uart0(
	// 	.clk(clk),                    // The master clock for this module
	// 	.rst(rst),                      // Synchronous reset
	// 	.rx(uart_rx),                // Incoming serial line
	// 	.tx(uart_tx),                // Outgoing serial line
	// 	.transmit(uart_transmit),              // Signal to transmit
	// 	.tx_byte(uart_tx_byte),                // Byte to transmit
	// 	.received(uart_received),              // Indicated that a byte has been received
	// 	.rx_byte(uart_rx_byte),                // Byte received
	// 	.is_receiving(uart_is_receiving),      // Low when receive line is idle
	// 	.is_transmitting(uart_is_transmitting),// Low when transmit line is idle
	// 	.recv_error(uart_recv_error)           // Indicates error in receiving packet
	// );


	// Dynamical system parameters
	wire [N-1:0] icx, icy, icz;
    wire [N-1:0] sigma,beta,rho;
    wire [N-1:0] dt;
	reg en_dda;

	// state variables
	wire [N-1:0] x,y,z;

	//Lorenz  DDA instance
	dda #(.N(N), .ES(ES)) lorenz(
		.clk(clk),
		.rst(rst),
		.en(en_dda),
		.x(x),
		.y(y),
		.z(z),
		.icx(icx),
		.icy(icy),
		.icz(icz),
		.sigma(sigma),
		.beta(beta),
		.rho(rho),
		.dt(dt)
	);

	reg [7:0] parameters [REG_SIZE];
	// reg [7:0] rx_counter, tx_counter;
	wire [7:0] state [OUT_SIZE];

	always @(posedge clk) begin
		if (rst) begin
			// rx_counter <= 1'b0;
			// tx_counter <= 1'b0;
			// uart_transmit <= 1'b1;
			en_dda <= 1'b1;

			// Initial settings
			parameters[0] <= 8'hC0; // icx = -1.0
			parameters[1] <= 8'h00;
			
			parameters[2] <= 8'h14;  // icy = 0.1
			parameters[3] <= 8'hCD; 
			
			parameters[4] <= 8'h72; // icz = 25.0
			parameters[5] <= 8'h40; 
			
			parameters[6] <= 8'h6A; // sigma = 10.0
			parameters[7] <= 8'h00; 
			
			parameters[8] <= 8'h55; // beta = 8/3
			parameters[9] <= 8'h55; 
			
			parameters[10] <= 8'h73; // rho = 28.0
			parameters[11] <= 8'h00; 
			
			parameters[12] <= 8'h04; // dt = 1/256
			parameters[13] <= 8'h00; 

		end

		// uart_transmit <= 1'b1;
		// if (tx_counter < OUT_SIZE) begin
		// 	uart_tx_byte <= state[tx_counter];
		// 	tx_counter <= tx_counter + 1;
		// end else begin
		// 	tx_counter <= 0;
		// end
	end

	// 3 state variables
	assign state[0] = x[15:8];
	assign state[1] = x[7:0];
	assign state[2] = y[15:8];
	assign state[3] = y[7:0];
	assign state[4] = z[15:8];
	assign state[5] = z[7:0];

	// 7 parameters
	assign icx = {parameters[0], parameters[1]};
	assign icy = {parameters[2], parameters[3]};
	assign icz = {parameters[4], parameters[5]};
	assign sigma = {parameters[6], parameters[7]};
	assign beta = {parameters[8], parameters[9]};
	assign rho = {parameters[10], parameters[11]};
	assign dt = {parameters[12], parameters[13]};
endmodule