`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Randon Stasney Dakota Ward
// 
// Create Date: 04/28/2016 01:54:34 PM
// Design Name: proj2demo
// Module Name: colorizer
// Project Name: ROJO Bot
// Target Devices: Nexy4fpga
// Tool Versions: Vivado
// Description: This module takes the input pixel stream for the vga display and colors 
// it based on icon data for those pixels and the background map
// 
// Dependencies: 
// 
// Revision:2.1
// Revision 0.01 - File Created
// Additional Comments:
// Changed the colors and added the deathstar icon as an overlay on the world map
// so we are using the 01 as the base grey color
// 
//////////////////////////////////////////////////////////////////////////////////


module colorizer(

    input	video_on,					// signal from dtg on wether to blank the screen
    input clk,							// system clock
    input [1:0]	world_pixel,			// pixel data from the world map
    input [1:0]	icon_pixel,				// pixel data from the icon
	input [12:0] death_pixel,			// pixel data from the death icon
	input [12:0] mil_pixel,
	input [12:0] rock_pixel,
	input [12:0] mon_pixel,
	input [12:0] grass_pixel,
    output reg [3:0] vga_red,			// output strength of red in the pixel
    output reg [3:0] vga_green,			// output strength of green in the pixel
    output reg [3:0] vga_blue			// output strength of blue in the pixel
);
    
    
    always @ (posedge clk) begin
        if(video_on) begin 
			//if (death_pixel [12] == 1) begin
             //   vga_red     <= death_pixel[3:0];                   //red:
             //   vga_green   <= death_pixel[7:4];                   //green:
             //   vga_blue    <= death_pixel[11:8];                   //blue:  			
			//end
			//else
			//begin
            if(mil_pixel[11:0] == 12'h000)
                //8'h00:
				begin // Icon see through or not used so using worldmap pixel colors
					if (mon_pixel[11:0] == 12'h000)
						begin
                    case(world_pixel)
                      2'b00:begin //background : black:space!
					                  vga_red     <= death_pixel[11:8];                   //red:
										vga_green   <= death_pixel[7:4];                   //green:
									vga_blue    <= death_pixel[3:0];                   //blue: 
               //         vga_red     <= 4'h0;                   //red:
               //         vga_green   <= 4'h0;                   //green:
               //         vga_blue    <= 4'h0;                   //blue:                    
							end    
                      2'b01:begin //blackline: is actually blue to represent space trail
                        vga_red     <= death_pixel[11:8];                     //red:
                        vga_green   <= death_pixel[7:4];                   //green:
                        vga_blue    <= death_pixel[3:0];                    //blue:                    
							end
                      2'b10:begin // obstruction: is a gold color to complete the starwars theme
                        vga_red     <= rock_pixel[11:8];                     //red:
                        vga_green   <= rock_pixel[7:4];                   //green:
                        vga_blue    <= rock_pixel[3:0];                    //blue:                    
							end
                      default:begin // not used for this design covers case 2'b11 and is black
                        vga_red     <= grass_pixel[11:8];                     //red:
                        vga_green   <= grass_pixel[7:4];                   //green:
                        vga_blue    <= grass_pixel[3:0];                    //blue:                    
							end                        
                     endcase 
						end  
				else begin
				vga_red     <= mon_pixel[11:8];                   //red:
                vga_green   <= mon_pixel[7:4];                   //green:
                vga_blue    <= mon_pixel[3:0];
					end
				end
				else begin
				vga_red     <= mil_pixel[11:8];                   //red:
                vga_green   <= mil_pixel[7:4];                   //green:
                vga_blue    <= mil_pixel[3:0];
				end
				/*
                // Icon colors that cover up world map pixels   
                2'b01: begin
                     vga_red        <= 4'h6; // even grey color used for the death star
                     vga_green      <= 4'h6; 
                     vga_blue       <= 4'h6; 
                end
                2'b10: begin
                     vga_red        <= 4'hE; // white used for ship base color and deathstar highlights
                     vga_green      <= 4'hE; 
                     vga_blue       <= 4'hE; 
                 end
                2'b11: begin
                     vga_red        <= 4'hB;  // red used for accents on ship and dish on deeathstar
                     vga_green      <= 4'h6;                   
                     vga_blue       <= 4'h6;
                end  
                default:begin // all cases used so should never get here but if it doest it blanks out screen
                     vga_red        <= 4'h1;                     //red:
                     vga_green      <= 4'h1;                   //green:
                     vga_blue       <= 4'h1;                    //blue:                    
                end            
             endcase
			*///end
			
			end 
		else begin // no video on so we're in blanking mode
                vga_red             <=4'h0 ;                     //red:
                vga_green           <=4'h0 ;                   //green:
                vga_blue            <=4'h0 ;                    //blue:                 
            end
        
		end//always

endmodule