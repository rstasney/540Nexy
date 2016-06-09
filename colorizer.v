`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Randon Stasney, Dakota Ward, Naveen Yalla, Kajal Zatale
// 
// Create Date: 04/28/2016 01:54:34 PM
// Design Name: Dungeon Crawler
// Module Name: colorizer.v
// Project Name: 540 Final Project 
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
// Stream pixel info for the health and score bars.  Also convert the textures from the icon.v
// and shows priority relation between the icons.  This then gets sent to the vga port on the 
// the nexys4 board for display.  The icon portions that are black allow shown through.
// 
//////////////////////////////////////////////////////////////////////////////////


module colorizer(

    input	video_on,					// signal from dtg on wether to blank the screen
    input clk,							// system clock
    input [1:0]	world_pixel,			// pixel data from the world map
    input [1:0]	icon_pixel,				// depreciated now we are displaying all 4096 colors
	input [12:0] death_pixel,			// pixel texture for the dirt
	input [12:0] mil_pixel,				// pixel data from the icon now the "hero"
	input [12:0] rock_pixel,			// pixel texture of the rock walls
	input [12:0] mon_pixel,				// Icon "monster"
	input [12:0] grass_pixel,			// grass texture
	input [12:0] end_pixel,				// final screen image
	input [12:0] exit_pixel,			// portal icon
	input [12:0] TC_pixel,				// treasure chest icon
	input [1:0]  health_disp_ip,        // to display health display meter.
	input        score_disp_ip,			// to display score meter
	
    output reg [3:0] vga_red,			// output strength of red in the pixel
    output reg [3:0] vga_green,			// output strength of green in the pixel
    output reg [3:0] vga_blue			// output strength of blue in the pixel
);
    
    
    always @ (posedge clk) begin
      if(video_on) begin 
		  if(score_disp_ip) begin      	// if score then display priority
				// color coded as gold bar to represent gold
              vga_red     <= 4'b1101;                   
              vga_green   <= 4'b1100;                   
              vga_blue    <= 4'b0000;		  
		  end			
			
			
		else  begin						// if health bar then display
				// green for full to 1/2 health
			if (health_disp_ip == 2'b11) begin
                 vga_red     <= 4'b0000;                   
                 vga_green   <= 4'b1111;                   
                 vga_blue    <= 4'b0000;
                 end
				 // orange for 1/2 health to 1/4
           else if(health_disp_ip == 2'b10) begin
                 vga_red     <= 4'b1101;                   
                 vga_green   <= 4'b1000;                   
                 vga_blue    <= 4'b0000;
                 end
				// red for final 1/4 of health 
           else if(health_disp_ip == 2'b01) begin
                 vga_red     <= 4'b1111;                   
                 vga_green   <= 4'b0000;                   
                 vga_blue    <= 4'b0000;
           end           
           
          else begin // shows end of game screen as priority
			if (end_pixel [12] == 1'b1)begin
							        vga_red     <= end_pixel[11:8];                   
									vga_green   <= end_pixel[7:4];                   
									vga_blue    <= end_pixel[3:0]; 
			end
			else begin
		// icons in priority order hero , monster, treasure chest, exit portal.
				if(mil_pixel[11:0] == 12'h000) begin // Icon see through with 000 or black to show other icons or map
					if (mon_pixel[11:0] == 12'h000) begin
						if (TC_pixel[11:0] == 12'h000) begin
							if (exit_pixel[11:0] == 12'h000) begin
								case(world_pixel)
								2'b00:begin //background : brown dirt
					                 vga_red     <= death_pixel[11:8];                  //red:
									vga_green   <= death_pixel[7:4];                   	//green:
									vga_blue    <= death_pixel[3:0];                    // blue:                  
									end    
								2'b01:begin //blackline: blanked out as brown dirt now
									vga_red     <= death_pixel[11:8];                   //red:
									vga_green   <= death_pixel[7:4];                   	//green:
									vga_blue    <= death_pixel[3:0];                    //blue:                    
									end
								2'b10:begin // walls represented as rocks now
									vga_red     <= rock_pixel[11:8];                    //red:
									vga_green   <= rock_pixel[7:4];                   	//green:
									vga_blue    <= rock_pixel[3:0];                    	//blue:                    
									end
								2'b11:begin // grass as third texture element
									vga_red     <= grass_pixel[11:8];                   //red:
									vga_green   <= grass_pixel[7:4];                   	//green:
									vga_blue    <= grass_pixel[3:0];                    //blue:                    
									end                        
								endcase 
							end
							else begin //// show exit portal
								vga_red     <= exit_pixel[11:8];                   		//red:
								vga_green   <= exit_pixel[7:4];                   		//green:
								vga_blue    <= exit_pixel[3:0];						 	//blue: 
							end
						end 
						else begin //// show treasure
							vga_red     <= TC_pixel[11:8];                   			//red:
							vga_green   <= TC_pixel[7:4];                   			//green:
							vga_blue    <= TC_pixel[3:0];								//blue:
						end
					end
					else begin		// show monster
						vga_red     <= mon_pixel[11:8];                   				//red:
						vga_green   <= mon_pixel[7:4];                   				//green:
						vga_blue    <= mon_pixel[3:0];									//blue:
					end
				end
				else begin    // show hero
					vga_red     <= mil_pixel[11:8];                   					//red:
					vga_green   <= mil_pixel[7:4];                   					//green:
					vga_blue    <= mil_pixel[3:0];										//blue:
				end
              end
			end	
		  end
		end	
			else begin // no video on so we're in blanking mode
                vga_red             <=4'h0 ;                     						//red:
                vga_green           <=4'h0 ;                   							//green:
                vga_blue            <=4'h0 ;                    						//blue:                 
            end
    
		end//always

endmodule