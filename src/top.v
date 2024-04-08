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
	assign uo_out[5] = 0;
	assign uo_out[6] = 0;
	assign uo_out[7] = 0;



	parameter N = 16;
	parameter ES = 2;
	parameter REG_SIZE = 10; // Register file size in bytes
	parameter OUT_SIZE = 4; // Output size in bytes
	parameter CLK_FREQ = 5000000; // Clock frequency (5 MHz)
	parameter BAUD_RATE = 9600; // UART baud rate

	integer i;

	// Register the reset on the negative edge of clock for safety
	reg rst_reg_n;
	always @(negedge clk) rst_reg_n <= rst_n;

	// Connect UART with RP4020
	wire uart_tx, uart_rx;
	assign  uart_rx = ui_in[3];
	assign  uart_tx = uo_out[4];

	// UART interface
	reg uart_transmit;
	reg [7:0] uart_tx_byte;
	reg uart_received;
	reg [7:0] uart_rx_byte;
	wire uart_is_receiving;
	wire uart_is_transmitting;
	wire uart_recv_error;

	uart #(
		.BAUD_RATE(BAUD_RATE),                 // The baud rate in kilobits/s
		.CLK_FREQ(CLK_FREQ)           // The master clock frequency (6 MHz)
	)
	uart0(
		.clk(clk),                    // The master clock for this module
		.rst_n(rst_reg_n),                      // Synchronous reset
		.rx(uart_rx),                // Incoming serial line
		.tx(uart_tx),                // Outgoing serial line
		.transmit(uart_transmit),              // Signal to transmit
		.tx_byte(uart_tx_byte),                // Byte to transmit
		.received(uart_received),              // Indicated that a byte has been received
		.rx_byte(uart_rx_byte),                // Byte received
		.is_receiving(uart_is_receiving),      // Low when receive line is idle
		.is_transmitting(uart_is_transmitting),// Low when transmit line is idle
		.recv_error(uart_recv_error)           // Indicates error in receiving packet
	);


	// Dynamical system parameters
	wire [N-1:0] ic1, ic2;
    wire [N-1:0] vK_M, vD_M;
    wire [N-1:0] dt;
	reg en_dda;

	// state variables (v1 and v2)
	wire [N-1:0] v1, v2;

	// DDA instance
	dda #(.N(N), .ES(ES)) dda0(
		.clk(clk),
		.rst_n(rst_reg_n),
		.en(en_dda),
		.v1(v1),
		.v2(v2),
		.ic1(ic1),
		.ic2(ic2),
		.vK_M(vK_M),
		.vD_M(vD_M),
		.dt(dt)
	);

	reg [7:0] registers [REG_SIZE];
	reg [2:0] rx_counter, tx_counter;

	wire [7:0] state [4];

	always @(posedge clk) begin
		if (!rst_reg_n) begin
			rx_counter <= 1'b0;
			tx_counter <= 1'b0;

			en_dda <= 1'b0;
			uart_transmit <= 1'b0;
			
			for (i = 0; i < REG_SIZE; i = i + 1) begin
			 registers[i] <= 8'h00;
			end			
		end

		if (rx_counter < REG_SIZE) begin
			if (uart_received) begin // Receisves byte and store at the register file
				registers[rx_counter] <= uart_rx_byte;
				rx_counter <= rx_counter + 1;
			end
			uart_transmit <= 1'b0;
			tx_counter <= 1'b0;
			en_dda <= 1'b0;
		end

		else begin
			if (tx_counter < OUT_SIZE+1 && !uart_is_transmitting) begin // Transmit output bytes
				uart_transmit <= 1'b1;
				uart_tx_byte <= state[tx_counter];
				tx_counter <= tx_counter + 1;
			end
			if (tx_counter == OUT_SIZE+1) begin 
				rx_counter <= 1'b0; // All output data was sent, starts receiving again
				en_dda <= 1'b1;
			end
		end
	end

	assign state[0] = v1[15:8];
	assign state[1] = v1[7:0];
	assign state[2] = v2[15:8];
	assign state[3] = v2[7:0];
	
	assign ic1 = {registers[0], registers[1]};
	assign ic2 = {registers[2], registers[3]};
	assign vK_M = {registers[4], registers[5]};
	assign vD_M = {registers[6], registers[7]};
	assign dt = {registers[8], registers[9]};
endmodule
