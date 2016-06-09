`timescale 1ns / 1ps
// audio_PWM.v -  design for ECE 540 final Project
//
// 
// 
// Created By:		Authors: Julian Mendoza, Wei Low, Nicholas McCoy 
// Modified By:		Randon Stasney, Dakota Ward, Naveen Yalla, Kajal Zatale
// Last Modified:	Randon Stasney 6/6/2016
//
// Revision History:
// -----------------
// created for 	fpglappy
// May-2016		RS		Modified for dungeon crawler
//
// Description:
// ------------
// This module adds up the memory contents of the audio file to determine
// the PWM output to the board.
//
///////////////////////////////////////////////////////////////////////////

module audio_PWM(
    input clk, 			// 65MHz clock.
    input reset,		// Reset assertion.
    input [7:0] music_data,	// 8-bit music sample
    output reg PWM_out		// PWM output. Connect this to ampPWM.
    );
    
    
    reg [7:0] pwm_counter = 8'd0;           // counts up to 255 clock cycles per pwm period
       
          
    always @(posedge clk) begin
        if(reset) begin
            pwm_counter <= 0;
            PWM_out <= 0;
        end
        else begin
            pwm_counter <= pwm_counter + 1;
            
            if(pwm_counter >= music_data) PWM_out <= 0;
            else PWM_out <= 1;
        end
    end
endmodule
