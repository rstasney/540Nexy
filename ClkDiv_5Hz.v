`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Josh Sackos
// converted by Randon Stasney, Dakota Ward, Naveen Yalla, Kajal Zatale
// Create Date:    07/11/2012
// Module Name:    ClkDiv_5Hz
// Project Name: 	 PmodJSTK_Demo
// Target Devices: Nexys4DDR
// Tool versions:  Vivado 2015
// Description: Converts input 65MHz clock signal to a 5Hz clock signal.
//
// Revision History: 
// 						Revision 1.01 - File Created (Josh Sackos)
//	Modified to run Dungeon crawler from a 65 MHz clock 					
//////////////////////////////////////////////////////////////////////////////////

// ============================================================================== 
// 										  Define Module
// ==============================================================================
module ClkDiv_5Hz(
    CLK,											// 65MHz sysclk
    RST,											// Reset
    CLKOUT										// New clock output
    );

// ===========================================================================
// 										Port Declarations
// ===========================================================================
	input CLK;
	input RST;
	output CLKOUT;

// ===========================================================================
// 							  Parameters, Regsiters, and Wires
// ===========================================================================
	
	// Output register
	reg CLKOUT;
	
	// Value to toggle output clock at
	parameter cntEndVal = 24'h756013;
	// Current count
	reg [23:0] clkCount = 24'h000000;
	

// ===========================================================================
// 										Implementation
// ===========================================================================

	//-------------------------------------------------
	//	5Hz Clock Divider Generates Send/Receive signal
	//-------------------------------------------------
	always @(posedge CLK) begin

			// Reset clock
			if(RST == 1'b1) begin
					CLKOUT <= 1'b0;
					clkCount <= 24'h000000;
			end
			else begin

					if(clkCount == cntEndVal) begin
							CLKOUT <= ~CLKOUT;
							clkCount <= 24'h000000;
					end
					else begin
							clkCount <= clkCount + 1'b1;
					end

			end

	end

endmodule
