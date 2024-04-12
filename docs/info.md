<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The DDA core expects to receive via UART port a list of 4 parameters (including values for initial conditions and time step) encoded in posit (16,2). When all parameters are received the integrators are enabled and solutions for the state variables are transmitted back serially via UART and output ports for each time step. Simulation can be stopped by sending any byte via UART. 


## How to test

. After reset the register file is set to zero and 
## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
