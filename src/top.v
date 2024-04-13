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
	// assign uio_out = 0;
	assign uio_oe = 8'b00100000;
	assign uo_out  = 0;
	assign uio_out[7] = 1'b0;
	assign uio_out[6] = 1'b0;
	assign uio_out[5] = 1'b0;
	assign uio_out[4] = 1'b0;
	assign uio_out[3] = 1'b0;
	assign uio_out[1] = 1'b0;
	assign uio_out[0] = 1'b0;

	parameter N = 16;
	parameter ES = 1;
	parameter REG_SIZE = 4; // Register file size in 16-bits slots
	// parameter CLK_FREQ = 12000000; // Clock frequency (12 MHz)
	// parameter BAUD_RATE = 9600; // UART baud rate

	reg rst;
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
	reg spi_rx_dv, spi_tx_dv;
	reg [7:0] spi_tx_byte, spi_rx_byte;

	// SPI
	spi_slave spi0(
		.i_Rst_L(rst_n),
		.i_Clk(clk),
		.o_RX_DV(spi_rx_dv),
		.o_RX_Byte(spi_rx_byte),
		.i_TX_DV(spi_tx_dv),
		.i_TX_Byte(spi_tx_byte),
		.i_SPI_Clk(uio_in[3]),
		.o_SPI_MISO(uio_out[2]),
		.i_SPI_MOSI(uio_in[1]),
		.i_SPI_CS_n(uio_in[0]) // active low
	);

	
	// Dynamical system parameters
	wire [N-1:0] icx, icy;
    wire [N-1:0] k,d;
	reg en_dda;

	// state variables
	wire [N-1:0] x,y;

	//Lorenz  DDA instance
	dda #(.N(N), .ES(ES)) spring_mass (
		.clk(clk),
		.rst(rst),
		.en(en_dda),
		.x(x),
		.y(y),
		.icx(icx),
		.icy(icy),
		.k(k),
		.d(d)
	);

	reg [N-1:0] parameters [REG_SIZE];
	// reg [7:0] rx_counter, tx_counter;
	reg[3:0] tx_counter;
	wire [7:0] state [4];

	always @(posedge clk) begin
		if (rst) begin
			// rx_counter <= 1'b0;
			tx_counter <= 1'b0;
			en_dda <= 1'b1;
			spi_tx_dv <= 1'b1;

			// Initial settings
			parameters[0] <= 16'hC000;  // icx = -1.0
			parameters[1] <= 16'h14CD;  // icy = 0.1
			parameters[2] <= 16'h14DD;  // k = 
			parameters[3] <= 16'h14DD;  // d = 
		end
		// Update parameters
		// if(spi_rx_dv) begin
			
		// end

		// Transmit state
		spi_tx_byte <= state[tx_counter];
		// uart_transmit <= 1'b1;
		// if (tx_counter < OUT_SIZE) begin
		// 	uart_tx_byte <= state[tx_counter];
		// 	tx_counter <= tx_counter + 1;
		// end else begin
		// 	tx_counter <= 0;
		// end
	end

	// 2 state variables
	assign state[0] = x[15:8];
	assign state[1] = x[7:0];
	assign state[2] = y[15:8];
	assign state[3] = y[7:0];

	// 7 parameters
	assign icx = parameters[0];
	assign icy = parameters[1];
	assign k = parameters[2];
	assign d = parameters[3];

	

endmodule
