`timescale 1ns / 1ps
//healthmodule.v -  design for ECE 540 Final Project
//
// Copyright 2014 Digilent, Inc.
// 
// Created By:		Mihaita Nagy, Sam Bobrowicz
// Modified By:		Randon Stasney, Dakota Ward, Naveen Yalla, Kajal Zatale
// Last Modified:	Naveen Yalla 6/5/2016
//
// Revision History:
// -----------------
// Mar-2014		MN		Created for RgbledDisplay
// Jun-2016		NY		Modified for Final Project to show score and health on screen
//
// Description:
// ------------
// This module draws the health and score bars that the colorizer uses to display the health and score
// on the screen.  It takes in the row and column data alond with the current health and score and then 
// draws a bar in the upper left corner of the screen to represent its value.
// 
///////////////////////////////////////////////////////////////////////////


module healthmodule(
		
    input       reset,					// reset
    input       clk,					// 65 MHz sysclk
    input [7:0] health,					// current health of hero
    input [7:0] score,					// current score of hero
    input [10:0] pixel_row,  			// pixel row from dtg
    input [10:0] pixel_column,			// pixel column from dtg
    
    output reg       score_display,		// output to colorizer
    output reg [1:0] health_display		// color coded output to colorizer

    );


   
    wire  [10:0]  health_x_start, health_y_start;  		// begin and end points for drawn bar
    wire  [10:0]  health_x_end, health_y_end;
		
    assign health_x_start = 11'd32;						// starting locations on screen
    assign health_y_start = 11'd32;
    assign health_x_end   = 11'd64;
    assign health_y_end   = health_y_start + health;	// end is staqrt + current value
    
    
    wire  [10:0]  score_x_start, score_y_start;			// same for score
    wire  [10:0]  score_x_end, score_y_end;   
    
    assign score_x_start = 11'd80;
    assign score_y_start = 11'd32;
    assign score_x_end   = 11'd112;
    assign score_y_end   = score_y_start + score;
 
        always @(posedge clk) begin
            if (reset) 
                begin 
                    health_display  <= 2'b00;						
                end
			// we draw lines directly on screen to represent value
            else if (pixel_column >= health_y_start  && pixel_column <= health_y_end ) begin
                  if ( pixel_row >= health_x_start  && pixel_row <= health_x_end) 	begin	
                      if(health > 128) begin
                         health_display  <= 2'b11;  				// green bar
                      end
                      else if (health > 63 && health <= 127) begin 	// once we're at 1/2 switch to orange
                          health_display  <= 2'b10;
                      end
                      else begin
                          health_display  <= 2'b01;					// red bar warning
                      end
                      
                   end
            end
            else begin
                health_display  <= 2'b00;
            end
        end
        
        // draw gold bar to represent score
        always @(posedge clk) begin									
                    if (reset) 
                        begin 
                            score_display  <= 1'b0;
                        end
					// start at given pixel draw until score represented
                    else if (pixel_column >= score_y_start  && pixel_column <= score_y_end ) begin
                          if ( pixel_row >= score_x_start  && pixel_row <= score_x_end)     begin            
                              
                              score_display  <= 1'b1;
                           end
                    end
                    else begin
                        score_display  <= 1'b0;
                    end
                end
endmodule
