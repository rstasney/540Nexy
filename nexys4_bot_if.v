//nexys4_if.v - Reference design for ECE 540 Project 2
//
// Copyright John Lynch and Roy Kravitz, 2014-2015, 2016
// 
// Created By:		Roy Kravitz, John Lynch modified by Randon Stasney and Dakota Ward
// Last Modified:	Randon Stasney 5/7/2016
//
// Revision History:
// -----------------
// Dec-2006		JL		Created this module for ECE 540
// Dec-2013		RK		Cleaned up the formatting.  No functional changes
// Aug-2014		RK		Parameterized module.  Modified for Vivado and Nexys4
// Apr-2016		RS		Modified for project 1 to include compass and chase
// May-2016		RS		Modified for project 2 to connect proj2demo
//
// Description:
// ------------
// This module is now the  ECE 540 Project 2.  This is the interface between the the I/O
// ports and the picoblaze cores.  The ports act as global variables and allow the picoblaze 
// instantiations to communicate with one another.  In particular this allows the proj2demo 
// to communicate with the bot to allow the rojobot to drive along the black line in the 
// world map
// 
///////////////////////////////////////////////////////////////////////////
module nexys4_bot_if
#(
parameter integer RESET_POLARITY_LOW = 1
)
(
// interface to the Picoblaze
input write_strobe,			// Write strobe –assertto write I/O 
// data
read_strobe,				// Read strobe -asserted to read I/O 
// data
input [7:0] port_id,		// I/O port address
input [7:0] io_data_in,		// data from PicoBlaze to be written to 
// I/O register
output reg[7:0] io_data_out,// data from I/O register to PicoBlaze
input interrupt_ack,		// interrupt acknowledge from PicoBlaze
output reg interrupt,		// interrupt request to PicoBlaze
// interface to the Nexys4
input sysclk,				// system clock
input sysreset,				// system reset (asserted high)

input[7:0]PORT_00,			// (i) pushbuttons inputs
input[7:0]PORT_01,			// (i) slide switches
input[7:0]PORT_10,			// (i) pushbutton inputs alternate port address
input[7:0]PORT_11,			// (i) slide switches 15:8 (high byte of switches

// Rojobot interface registers
output reg[7:0]PORT_09,		//		; (o) Rojobot motor control output from system
input[7:0]PORT_0A, 			//		; (i) X coordinate of rojobot location
input[7:0]PORT_0B, 			//		; (i) Y coordinate of rojobot location
input[7:0]PORT_0C, 			//		; (i) Rojobot info register
input[7:0]PORT_0D, 			//		; (i) Sensor register
input[7:0]PORT_0E, 			//		; (i) Y coor uppper bits

output reg[7:0]PORT_02,		// LEDS [7:0]
output reg[7:0]PORT_03,		// (o) digit 3 port address
output reg[7:0]PORT_04,		// (o) digit 2 port address
output reg[7:0]PORT_05,		// (o) digit 1 port address
output reg[7:0]PORT_06,		// (o) digit 0 port address
output reg[7:0]PORT_07,		// (o) decimal points 3:0 port address
output reg[7:0]PORT_08,		// (o) *RESERVED* port address
output reg[7:0]PORT_12,		// (o) LEDs 15:8 (high byte of switches)
output reg[7:0]PORT_13,		// (o) digit 7 port address
output reg[7:0]PORT_14,		// (o) digit 6 port address
output reg[7:0]PORT_15,		// (o) digit 5 port address
output reg[7:0]PORT_16,		// (o) digit 4 port address
output reg[7:0]PORT_17,		// (o) decimal points 7:4 port address
output reg[7:0]PORT_18,		// (o) *RESERVED* alternate port address

input interrupt_request		// Interrupt request input
);


// reset -asserted high
wire reset_in = RESET_POLARITY_LOW ? ~sysreset : sysreset;

/////////////////////////////////////////////////////////////////////////////////
// General Purpose Input Ports.
/////////////////////////////////////////////////////////////////////////////////
//
//
// The inputs connect via a pipelined multiplexer. For optimum implementation, 
// the input selection control of the multiplexer is limited to only those
// signals of 'port_id' that are necessary. In this case, only 2-bits are 
// required to identify each of four input ports to be read by KCPSM6.
//
// Note that 'read_strobe' only needs to be used when whatever supplying 
// information to KCPSM6 needs to know when that information has been read. For 
// example, when reading a FIFO a read signal would need to be generated when
//that port is readsuch that the FIFO would know to present the next oldest 
// information.
//// Note:  The input registers are binary encoded per kcpsm6_design_template.v
//
always @ (posedge sysclk) begin
case (port_id[3:0]) 

4'b0000 : io_data_out <= PORT_00; 	// pushbutton
4'b1010 : io_data_out <= PORT_0A;	// x loc
4'b1011 : io_data_out <= PORT_0B;	// y loc
4'b1100 : io_data_out <= PORT_0C;	// rojobot info
4'b1101 : io_data_out <= PORT_0D;	// sensor
4'b1110 : io_data_out <= PORT_0E;	// y upper
default : io_data_out <= 8'bXXXXXXXX ;  
endcase
end
/////////////////////////////////////////////////////////////////////////////////
// General Purpose Output Ports 
/////////////////////////////////////////////////////////////////////////////////
//
//
//Output ports must capture the value presented on the 'out_port' based on the
// value of 'port_id' when 'write_strobe' is High.
//
// Note: The output registers are one-hot encoded per kcpsm6_design_template.v
//
always @ (posedge sysclk) begin
// 'write_strobe' is used to qualify all writes to general output ports.
if (write_strobe == 1'b1) begin
case (port_id[4:0]) 


// LEDS [7:0]
5'b00010 : PORT_02 <= io_data_in;
// digit 3 port address
5'b00011 : PORT_03 <= io_data_in;
// digit 2 port address
5'b00100 : PORT_04 <= io_data_in;
// digit 1 port address
5'b00101 : PORT_05 <= io_data_in;
// digit 0 port address
5'b00110 : PORT_06 <= io_data_in;
// (o) decimal points 3:0 port address
5'b00111 : PORT_07 <= io_data_in;
// motor control in
5'b01001 : PORT_09 <= io_data_in;
// LEDs 15:8 
5'b10010 : PORT_12 <= io_data_in;
// digit 7 port address
5'b10011 : PORT_13 <= io_data_in;
// digit 6 port address
5'b10100 : PORT_14 <= io_data_in;
// digit 5 port address
5'b10101 : PORT_15 <= io_data_in;
// digit 4 port address
5'b10110 : PORT_16 <= io_data_in;
// (o) decimal points 7:4 port address
5'b10111 : PORT_17 <= io_data_in;
 
endcase


end
end
/////////////////////////////////////////////////////////////////////////////////
// Recommended 'closed loop' interrupt interface (when required).
///////////////////////////////////////////////////////////////////////////////////
// Interrupt becomes active when 'int_request' is observed and then remains 
// active until 
// acknowledged by KCPSM6. Please see description and waveforms in documentation.
//
always @ (posedge sysclk) begin
if (interrupt_ack == 1'b1) begin
interrupt <= 1'b0;
end
else if (interrupt_request == 1'b1) begin
interrupt <= 1'b1;
end
else begin
interrupt <= interrupt;
end
end // always
endmodule