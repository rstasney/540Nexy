 `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Randon Stasney, Dakota Ward, Naveen Yalla, Kajal Zatale
// 
// Create Date: 04/28/2016 01:54:34 PM
// Design Name: proj2demo
// Module Name: icon.v
// Project Name: Dungeon crawler
// Target Devices: Nexy4fpga
// Tool Versions: Vivado
// Description: 
// This module instantiates the block rams for the icons.  It then takes the pixel data from the dtg 
// and the takes the location from the bot and determines whether to pass on the color information 
// from the icon or set the output as 00 which will allow the world map to be output on the screen. 
// If the pixel data location overlaps the location of the icon then the output stream is the color
// coded output from the memory location
// Revision 0.01 - File Created
// Revision  1.0 changed to incorperate the larger screen resolution and add offset logic
// Revision: 2.0 Added death star icon
// Revision  3.0 Added hero scrolling
// Revision  3.5 Added relation chest monster portal icon
// Additional Comments:
// The treasure chest are hard coded x,y location based here and in gamelogic.  The map now encompasses
// 4096 pixels x 3072 pixels of which we are displaying 1/16th of the screeen at a given time centered
// on the hero location.  All the other icons are drawn in relatiopn to the hero and the world pixels
// determine the color texture that we apply to the background screen
//////////////////////////////////////////////////////////////////////////////////


module icon(
   input clk,								// sysclock
   input [10:0] pixel_row,      			// from dtg
   input [10:0] pixel_column,   			// from dtg 
   input [11:0] LocX,						// location of herobot from bot31.v multiplied by 16 for scaling
   input [11:0] LocY,						// location of herobot from bot31.v multiplied by 12 for scaling
   input [11:0] LocX_mon,					// location of monsterbot from bot.v multiplied by 16 for scaling
   input [11:0] LocY_mon,					// location of monsterbot from bot.v multiplied by 12 for scaling
   input [1:0] game_over,					// game logic to determine which end screen and when to display
   input [7:0] tc_info,						// onehot encoded whether treasure chest open and looted allrerady
   input [2:0] Botinfo,						// orientation of herobot from bot31.v for display angle
   output reg [12:0] death_pixel, mil_pixel,rock_pixel, mon_pixel, grass_pixel, // texture and icon data to colorizer 
   output reg [12:0] end_pixel, TC_pixel, exit_pixel,
   output reg [1:0] icon_pixel				// depreciated
);
// hard coded icon values for treasure
	reg [11:0] LocX_T1, LocY_T1, LocX_T2, LocY_T2, LocX_T3, LocY_T3, LocX_T4, LocY_T4, exit_X;
	reg [11:0] LocX_T5, LocY_T5, LocX_T6, LocY_T6, LocX_T7, LocY_T7, LocX_T8, LocY_T8, exit_Y;
// tick for proper drawing in relation to hero 
   reg [8:0] tick, tc_tick, tc_tick2, tc_tick3, tc_tick4, tc_tick5, tc_tick6, tc_tick7, tc_tick8, exit_tick;
// icon addressing of 128 x 128 icons
   reg [13:0] rom_0, mona, tc, ex;									// the icon address 
//  texture screen addressing for 256 x 256 image
   reg [15:0] stone_a, end_a;
//  texture addressing 
	reg [14:0]	grass128, dirt128;
// output streams from roms **combine with a 1'b1 bit which signifies to colorizer to draw them**
	wire	[11:0] frtknig, dirt, wall, monout, Bkn, Rkn, Lkn, grass, end_over, end_score, treasureO, treasureC, portal;

	
	

	
// main block to access the roms and stream color data 
	always @ (posedge clk) begin
       if ((pixel_row == 0) && (pixel_column == 0)) begin // reset at every new frame to prevent drift
         rom_0 <= 0;
		 mona <= 0;
		 tc <= 0;
		 end_a <= 0;
		 stone_a <= 0;
		 grass128 <= 0;
		 dirt128 <= 0;
		 // pixel icon locations for treasure, x * 16, y * 12
		 LocX_T1 <= 12'h2F0;
		 LocY_T1 <= 12'h1D4;
		 LocX_T2 <= 12'hD10;
		 LocY_T2 <= 12'hD8;
		 LocX_T3 <= 12'hD0;
		 LocY_T3 <= 12'h468;
		 LocX_T4 <= 12'hD30;
		 LocY_T4 <= 12'h4C8;
		 LocX_T5 <= 12'h360;
		 LocY_T5 <= 12'h690;
		 LocX_T6 <= 12'hD30;
		 LocY_T6 <= 12'h81C;
		 LocX_T7 <= 12'h3F0;
		 LocY_T7 <= 12'hA38;
		 LocX_T8 <= 12'hBC0;
		 LocY_T8 <= 12'hA38;
		 // pixel icon locations for portal, x * 16, y * 12
		 exit_X <= 12'h980;
		 exit_Y <= 12'h810;
         icon_pixel <= 2'b00;
		 end_pixel <= 13'b0000000000000;
		 death_pixel <= 13'b0000000000000;
		 mil_pixel <= 13'b0000000000000;
		 mon_pixel <= 13'b0000000000000;
		 rock_pixel <= 13'b0000000000000;
		 grass_pixel <= 13'b0000000000000;
		 TC_pixel <= 13'b0000000000000;
		 exit_pixel <= 13'b0000000000000;
		 tick <= 0;        	// monster 
		 tc_tick <= 0;		// treasure chests
		 tc_tick2 <= 0;
		 tc_tick3 <= 0;
		 tc_tick4 <= 0;
		 tc_tick5 <= 0;
		 tc_tick6 <= 0;
		 tc_tick7 <= 0;
		 tc_tick8 <= 0;
		 exit_tick <= 0;	// exit portal
       end
       else begin  // check to see if there is icon data in the location of the current pixel stream
	   // calculate addresses to paint the world
	   // divide by column to repeat and make match total 1024/ "4" equals 256 the pixel dimensions of end_a
		end_a <= (((pixel_row/12)*1024) + (pixel_column/4));
		// not full screen so just texture by multiple drawings
		stone_a <= (((pixel_row/2)*512) + (pixel_column/2)); 
		grass128 <= (((pixel_row/2)*512) + (pixel_column/2));
		dirt128 <= (((pixel_row/2)*512) + (pixel_column/2));
		icon_pixel <= 2'b00;
		end_pixel <= 13'b0000000000000;
		mil_pixel <= 13'b0000000000000;
		mon_pixel <= 13'b0000000000000;
		TC_pixel <= 13'b0000000000000;
		exit_pixel <= 13'b0000000000000;
		// set texture stream 
		rock_pixel <= {1'b1, wall}; 			// walls 			world map 2
		death_pixel <= {1'b1, dirt};			// background dirt	world map 0
		grass_pixel <= {1'b1, grass};			// other grass		world map 3
		/// game over takes precendent
	if (game_over [1] == 1'b1) begin
		if 	(game_over [0] == 1'b1) begin
			end_pixel <= {1'b1, end_over};  // display fail screen
		end
		else begin 
			end_pixel <= {1'b1, end_score};	// display win screen
		end
	end
	else begin
// check treasure chest is within screen range of hero's current location
// all icons drawn in relation to hero and all use the same pattern logic so will only comment this block
// as an explanation, all other blocks work exactly the same
		if ((LocX_T1 >= LocX - 512 && LocX_T1 <= LocX + 512)&& (LocY_T1 >= LocY - 384 && LocY_T1 <= LocY +384)) begin
		// if he is determine which quadrant it's in relational to the hero
			
			if 	(LocX >= LocX_T1)begin		
				if (LocY >= LocY_T1)begin // chest top left subtract chest from hero both direction
				
				
				// Logic to draw relational icons
				// hero is centered 
				// divide screen into 4 quadrants for 4 cases
				// hero 128 x 128 and screen is 1024 x 768
				// to draw we are drawing from top right so that's 64 pixels above and to the left of the center
				// the 512 - 64 is 468 where we would start drawing hero
				// we then offset that by the difference between the hero and the item 
				// as an example the first quadrant chest is top left  hero is greater so he will subtract the chest
				// say hero is at 3000 x and treasure is at 2900 x the difference is 100 from the 468 so at 
				// pixel column 368 we would start drawing the left hand side of the chest
				// we apply the same formula to the Y direction
				// if the chest is on the right or below we than add that difference and we are always subtracting from the larger
				// to just find that relational difference so in our right example we would subtract the hero "from" the chest
				// and add it to the 448, so hero 1300 chest 1500 start drawing left side at 1500 - 1300 + 448 = 648
				// in the Y direction we use 320 as our 1/2 screen - 64 pixels of icon from center. and notice that if he is 
				// in the same place we use the equals and draw them both in the same place. So as our hero moves this is constantly 
				// updated and draws the icon in proper relation
				// notice since we only have 1 rom we are only drawing 1 treasure at a time hence the elseif logic
				
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T1))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T1))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T1)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T1))))) begin					
						tc <= tc_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T1)))*128);  // we use the tick to increment the 128 bits and find Y direction row by its offset from the 320 
						tc_tick <= tc_tick + 1;					// increment tick for every column
						if 	(tc_info [0] == 1'b0)   			// logic to display open or closed chest from gamelogic
							TC_pixel <= {1'b1, treasureC};		// closed unlooted
						else
							TC_pixel <= {1'b1, treasureO};		// looted open
					end	
					else begin
						tc_tick <= 0;							// reset tick every new row 
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			// don't display if not in that range 
					end	
				end			
				else begin				// chest bottom left subtract hero - chest X, and add chest - hero Y
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T1))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T1))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T1 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T1 - LocY))))) begin				
						tc <= tc_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T1)))*128);
						tc_tick <= tc_tick + 1;
						if 	(tc_info [0] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T1)begin  // chest top right add chest - hero X, subtract hero - chest Y
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T1 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T1 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T1)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T1))))) begin				
						tc <= tc_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T1)))*128);
						tc_tick <= tc_tick + 1;
						if 	(tc_info [0] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin					// chest bottom right add chest - hero X, add chest - hero Y
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T1 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T1 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T1 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T1 - LocY))))) begin				
						tc <= tc_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T1)))*128);
						tc_tick <= tc_tick + 1;
						if 	(tc_info [0] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	

	
// treasure chest 2
	else	if ((LocX_T2 >= LocX - 512 && LocX_T2 <= LocX + 512)&& (LocY_T2 >= LocY - 384 && LocY_T2 <= LocY +384)) begin
			if 	(LocX >= LocX_T2)begin
		
				if (LocY >= LocY_T2)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T2))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T2))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T2)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T2))))) begin					
						tc <= tc_tick2 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T2)))*128);
						tc_tick2 <= tc_tick2 + 1;
						if 	(tc_info [1] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick2 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T2))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T2))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T2 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T2 - LocY))))) begin				
						tc <= tc_tick2 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T2)))*128);
						tc_tick2 <= tc_tick2 + 1;
						if 	(tc_info [1] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick2 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T2)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T2 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T2 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T2)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T2))))) begin				
						tc <= tc_tick2 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T2)))*128);
						tc_tick2 <= tc_tick2 + 1;
						if 	(tc_info [1] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick2 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T2 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T2 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T2 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T2 - LocY))))) begin				
						tc <= tc_tick2 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T2)))*128);
						tc_tick2 <= tc_tick2 + 1;
						if 	(tc_info [1] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick2 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	


// treasure chest 3	
	else	if ((LocX_T3 >= LocX - 512 && LocX_T3 <= LocX + 512)&& (LocY_T3 >= LocY - 384 && LocY_T3 <= LocY +384)) begin
			if 	(LocX >= LocX_T3)begin
		
				if (LocY >= LocY_T3)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T3))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T3))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T3)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T3))))) begin					
						tc <= tc_tick3 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T3)))*128);
						tc_tick3 <= tc_tick3 + 1;
						if 	(tc_info [2] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick3 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T3))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T3))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T3 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T3 - LocY))))) begin				
						tc <= tc_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T1)))*128);
						tc_tick3 <= tc_tick3 + 1;
						if 	(tc_info [2] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick3 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T3)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T3 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T3 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T3)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T3))))) begin				
						tc <= tc_tick3 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T3)))*128);
						tc_tick3 <= tc_tick3 + 1;
						if 	(tc_info [2] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick3 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T3 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T3 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T3 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T3 - LocY))))) begin				
						tc <= tc_tick3 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T3)))*128);
						tc_tick3 <= tc_tick3 + 1;
						if 	(tc_info [2] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick3 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	

	

// treasure chest 4	
	else	if ((LocX_T4 >= LocX - 512 && LocX_T4 <= LocX + 512)&& (LocY_T4 >= LocY - 384 && LocY_T4 <= LocY +384)) begin
			if 	(LocX >= LocX_T4)begin
		
				if (LocY >= LocY_T4)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T4))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T4))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T4)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T4))))) begin					
						tc <= tc_tick4 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T4)))*128);
						tc_tick4 <= tc_tick4 + 1;
						if 	(tc_info [3] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick4 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T4))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T4))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T4 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T4 - LocY))))) begin				
						tc <= tc_tick4 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T4)))*128);
						tc_tick4 <= tc_tick4 + 1;
						if 	(tc_info [3] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick4 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T4)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T4 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T4 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T4)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T4))))) begin				
						tc <= tc_tick4 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T4)))*128);
						tc_tick4 <= tc_tick4 + 1;
						if 	(tc_info [3] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick4 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T4 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T4 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T4 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T4 - LocY))))) begin				
						tc <= tc_tick4 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T4)))*128);
						tc_tick4 <= tc_tick4 + 1;
						if 	(tc_info [3] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick4 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	
	
	
// treasure chest 5
	else	if ((LocX_T5 >= LocX - 512 && LocX_T5 <= LocX + 512)&& (LocY_T5 >= LocY - 384 && LocY_T5 <= LocY +384)) begin
			if 	(LocX >= LocX_T5)begin
		
				if (LocY >= LocY_T5)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T5))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T5))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T5)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T5))))) begin					
						tc <= tc_tick5 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T5)))*128);
						tc_tick5 <= tc_tick5 + 1;
						if 	(tc_info [4] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick5 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T5))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T5))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T5 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T5 - LocY))))) begin				
						tc <= tc_tick5 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T5)))*128);
						tc_tick5 <= tc_tick5 + 1;
						if 	(tc_info [4] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick5 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T5)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T5 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T5 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T5)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T5))))) begin				
						tc <= tc_tick5 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T5)))*128);
						tc_tick5 <= tc_tick5 + 1;
						if 	(tc_info [4] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick5 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T5 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T5 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T5 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T5 - LocY))))) begin				
						tc <= tc_tick5 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T5)))*128);
						tc_tick5 <= tc_tick5 + 1;
						if 	(tc_info [4] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick5 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	

// treasure chest 6
	else	if ((LocX_T6 >= LocX - 512 && LocX_T6 <= LocX + 512)&& (LocY_T6 >= LocY - 384 && LocY_T6 <= LocY +384)) begin
			if 	(LocX >= LocX_T6)begin
		
				if (LocY >= LocY_T6)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T6))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T6))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T6)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T6))))) begin					
						tc <= tc_tick6 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T6)))*128);
						tc_tick6 <= tc_tick6 + 1;
						if 	(tc_info [5] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick6 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T6))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T6))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T6 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T6 - LocY))))) begin				
						tc <= tc_tick6 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T6)))*128);
						tc_tick6 <= tc_tick6 + 1;
						if 	(tc_info [5] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick6 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T6)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T6 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T6 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T6)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T6))))) begin				
						tc <= tc_tick6 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T6)))*128);
						tc_tick6 <= tc_tick6 + 1;
						if 	(tc_info [5] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick6 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T6 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T6 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T6 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T6 - LocY))))) begin				
						tc <= tc_tick6 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T6)))*128);
						tc_tick6 <= tc_tick6 + 1;
						if 	(tc_info [5] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick6 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	

// treasure chest 7	
else		if ((LocX_T7 >= LocX - 512 && LocX_T7 <= LocX + 512)&& (LocY_T7 >= LocY - 384 && LocY_T7 <= LocY +384)) begin
			if 	(LocX >= LocX_T7)begin
		
				if (LocY >= LocY_T7)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T7))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T7))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T7)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T7))))) begin					
						tc <= tc_tick7 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T7)))*128);
						tc_tick7 <= tc_tick7 + 1;
						if 	(tc_info [6] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick7 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T7))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T7))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T7 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T7 - LocY))))) begin				
						tc <= tc_tick7 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T7)))*128);
						tc_tick7 <= tc_tick7 + 1;
						if 	(tc_info [6] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick7 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T7)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T7 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T7 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T7)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T7))))) begin				
						tc <= tc_tick7 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T7)))*128);
						tc_tick7 <= tc_tick7 + 1;
						if 	(tc_info [6] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick7 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T7 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T7 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T7 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T7 - LocY))))) begin				
						tc <= tc_tick7 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T7)))*128);
						tc_tick7 <= tc_tick7 + 1;
						if 	(tc_info [6] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick7 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	
	
// treasure chest 8
	else	if ((LocX_T8 >= LocX - 512 && LocX_T8 <= LocX + 512)&& (LocY_T8 >= LocY - 384 && LocY_T8 <= LocY +384)) begin
			if 	(LocX >= LocX_T8)begin
		
				if (LocY >= LocY_T8)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T8))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T8))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T8)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T8))))) begin					
						tc <= tc_tick8 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T8)))*128);
						tc_tick8 <= tc_tick8 + 1;
						if 	(tc_info [7] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick8 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_T8))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_T8))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T8 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T8 - LocY))))) begin				
						tc <= tc_tick8 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T8)))*128);
						tc_tick8 <= tc_tick8 + 1;
						if 	(tc_info [7] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick8 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= LocY_T8)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_T8 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T8 - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_T8)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_T8))))) begin				
						tc <= tc_tick8 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T8)))*128);
						tc_tick8 <= tc_tick8 + 1;
						if 	(tc_info [7] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end
					else begin
						tc_tick8 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_T8 - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_T8 - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_T8 - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_T8 - LocY))))) begin				
						tc <= tc_tick8 + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_T8)))*128);
						tc_tick8 <= tc_tick8 + 1;
						if 	(tc_info [7] == 1'b0)
							TC_pixel <= {1'b1, treasureC};
						else
							TC_pixel <= {1'b1, treasureO};
					end	
					else begin
						tc_tick8 <= 0;
						tc <= tc;
						icon_pixel <= 2'b00;
						TC_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	
		else begin
			tc <= 0;
			icon_pixel <= 2'b00;
			TC_pixel <= 13'b0000000000000;			
		end		
	
		
// exit portal icon same relational logic as chest	
		if ((exit_X >= LocX - 512 && exit_X <= LocX + 512)&& (exit_Y >= LocY - 384 && exit_Y <= LocY +384)) begin
			if 	(LocX >= exit_X)begin
		
				if (LocY >= exit_Y)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - exit_X))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - exit_X))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - exit_Y)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - exit_Y))))) begin					
						ex <= exit_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - exit_Y)))*128);
						exit_tick <= exit_tick + 1;
					
							exit_pixel <= {1'b1, portal};
					
					end	
					else begin
						exit_tick <= 0;
						ex <= ex;
						icon_pixel <= 2'b00;
						exit_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - exit_X))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - exit_X))))&&((pixel_row >= 11'b001_0100_0000 + ( (exit_Y - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (exit_Y - LocY))))) begin				
						ex <= exit_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - exit_Y)))*128);
						exit_tick <= exit_tick + 1;
						
							exit_pixel <= {1'b1, portal};

					end	
					else begin
						exit_tick <= 0;
						ex <= ex;
						icon_pixel <= 2'b00;
						exit_pixel <= 13'b0000000000000;			
					end							
				end
			end
			else begin
				if (LocY >= exit_Y)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((exit_X - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (exit_X - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - exit_Y)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - exit_Y))))) begin				
						ex <= exit_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - exit_Y)))*128);
						exit_tick <= exit_tick + 1;
				
							exit_pixel <= {1'b1, portal};
						
					end
					else begin
						exit_tick <= 0;
						ex <= ex;
						icon_pixel <= 2'b00;
						exit_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (exit_X - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (exit_X - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (exit_Y - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (exit_Y - LocY))))) begin				
						ex <= exit_tick + ((pixel_row - (11'b001_0100_0000 - (LocY - exit_Y)))*128);
						exit_tick <= exit_tick + 1;
					
						exit_pixel <= {1'b1, portal};
						
					end	
					else begin
						exit_tick <= 0;
						ex <= ex;
						icon_pixel <= 2'b00;
						exit_pixel <= 13'b0000000000000;			
					end	
				end
			end							
		end	
		else begin
			ex <= 0;
			icon_pixel <= 2'b00;
			exit_pixel <= 13'b0000000000000;			
		end	


// the monster is also the same relational icon logic		
		if ((LocX_mon >= LocX - 512 && LocX_mon <= LocX + 512)&& (LocY_mon >= LocY - 384 && LocY_mon <= LocY +384)) begin
			if 	(LocX >= LocX_mon)begin
		
				if (LocY >= LocY_mon)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_mon))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_mon))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_mon)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_mon))))) begin					
						mona <= tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_mon)))*128);
						mon_pixel <= {1'b1, monout};
						tick <= tick + 1;
					end	
					else begin
						tick <= 0;
						mona <= mona;
						icon_pixel <= 2'b00;
						mon_pixel <= 13'b0000000000000;			
					end	
				end			
				else begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_mon))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_mon))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_mon - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_mon - LocY))))) begin				
						mona <= tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_mon)))*128);
						mon_pixel <= {1'b1, monout};
						tick <= tick + 1;
					end	
					else begin
						tick <= 0;
						mona <= mona;
						icon_pixel <= 2'b00;
						mon_pixel <= 13'b0000000000000;			
					end						
				end
			end
			else begin
				if (LocY >= LocY_mon)begin
					if (((pixel_column >= 11'b001_1100_0000 + ((LocX_mon - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_mon - LocX))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_mon)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_mon))))) begin				
						mona <= tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_mon)))*128);
						mon_pixel <= {1'b1, monout};
						tick <= tick + 1;
					end
					else begin
						tick <= 0;
						mona <= mona;
						icon_pixel <= 2'b00;
						mon_pixel <= 13'b0000000000000;			
					end						
				end	
				else begin
					if (((pixel_column >= 11'b001_1100_0000 + ( (LocX_mon - LocX))) && (pixel_column <= 11'b010_0100_0000 + ( (LocX_mon - LocX))))&&((pixel_row >= 11'b001_0100_0000 + ( (LocY_mon - LocY)))&& (pixel_row <= 11'b001_1100_0000 + ( (LocY_mon - LocY))))) begin				
						mona <= tick + ((pixel_row - (11'b001_0100_0000 - (LocY - LocY_mon)))*128);
						mon_pixel <= {1'b1, monout};
						tick <= tick + 1;
					end	
					else begin
						tick <= 0;
						mona <= mona;
						icon_pixel <= 2'b00;
						mon_pixel <= 13'b0000000000000;			
					end	
				end
			end	
		end
		else begin
			mona <= 0;
			icon_pixel <= 2'b00;
			mon_pixel <= 13'b0000000000000;			
		end	

				
// for drawing the hero if we're not on the edge of the screen	
		if ((LocX >= 512 && LocX <= 3584)&& (LocY >= 384 && LocY <= 2688)) begin
			if (((pixel_column >= 11'b001_1100_0000) && (pixel_column <= 11'b010_0100_0000))&&((pixel_row >= 11'b001_0100_0000)&& (pixel_row <= 11'b001_1100_0000))) begin
				
				rom_0 <= (((pixel_column + 6'b11_1111)) + (pixel_row + 8'b1011_1111)*128);
					case(Botinfo) // we select which hero icon orientation to display based on the botinfo

                        3'b100:    		mil_pixel <= {1'b1, frtknig};       	// 0 degrees
                        3'b110:    		mil_pixel <= {1'b1, Lkn};        	//90 degrees
                        3'b000:    		mil_pixel <= {1'b1, Bkn};   	//180 degrees
                        3'b010: 		mil_pixel <= {1'b1, Rkn};    	//270 degress
                        default: 	mil_pixel <= 13'b0000000000000;
                           endcase 
				
			end
            else begin
                rom_0 <= rom_0;
                icon_pixel <= 2'b00;
				mil_pixel <= 13'b0000000000000;
            end
		end
//  for when we're on the edge, ** does jump because we have blown up the screen
		else begin  
		    if ((pixel_row[10:7] == LocY[10:7]) && (pixel_column[10:7] == LocX[10:7])) begin //128 bit icon
                rom_0 <= rom_0 + 1;
					case(Botinfo) // we select which hero icon orientation to display based on the botinfo

                        3'b100:    		mil_pixel <= {1'b1, frtknig};       	// 0 degrees
                        3'b110:    		mil_pixel <= {1'b1, Lkn};        	//90 degrees
                        3'b000:    		mil_pixel <= {1'b1, Bkn};   	//180 degrees
                        3'b010: 		mil_pixel <= {1'b1, Rkn};    	//270 degress
                        default: 	mil_pixel <= 13'b0000000000000;
                           endcase 
			end
			else begin
                rom_0 <= rom_0;
                icon_pixel <= 2'b00;
				mil_pixel <= 13'b0000000000000;
			end
		end
	end
       end
   end 
   
// instantiate all the memories  
// hero front icon
knitg kg (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [13 : 0] addra
  .douta(frtknig)  // output wire [3 : 0] douta
);
// exit portal icon
exiting portal (
  .clka(clk),    // input wire clka
  .addra(ex),  // input wire [13 : 0] addra
  .douta(portal)  // output wire [3 : 0] douta
);
// wall texture
stoneg sg ( // wall world map code 2
  .clka(clk),    // input wire clka
  .addra(stone_a),  // input wire [15 : 0] addra
  .douta(wall)  // output wire [3 : 0] douta
);
//monster
Mons ms (
  .clka(clk),    // input wire clka
  .addra(mona),  // input wire [15 : 0] addra
  .douta(monout)  // output wire [3 : 0] douta
);
// hero back icon
KnBck KB (  
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [15 : 0] addra
  .douta(Bkn)  // output wire [11 : 0] douta
);
// hero left icon
KnLft KL (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [15 : 0] addra
  .douta(Lkn)  // output wire [11 : 0] douta
);
// hero right icon
KnRt KR (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [15 : 0] addra
  .douta(Rkn)  // output wire [11 : 0] douta
);
// closed chest icon
TCC closed (
  .clka(clk),    // input wire clka
  .addra(tc),  // input wire [13 : 0] addra
  .douta(treasureC)  // output wire [11 : 0] douta
);
// opened chest icon
TCO opened (
  .clka(clk),    // input wire clka
  .addra(tc),  // input wire [13 : 0] addra
  .douta(treasureO)  // output wire [11 : 0] douta
);
// game over died "lost" 
gameover finalscre (
  .clka(clk),    // input wire clka
  .addra(end_a),  // input wire [15 : 0] addra
  .douta(end_over)  // output wire [11 : 0] douta
);
// game over exited "won"
Vworld_map scores (
  .clka(clk),    // input wire clka
  .addra(end_a),  // input wire [15 : 0] addra
  .douta(end_score)  // output wire [11 : 0] douta
);
//----------- switched grass to distributed rom to display second end screen 
DRgrass distgrass (
  .a(grass128),      // input wire [13 : 0] a
  .spo(grass)  // output wire [11 : 0] spo
);
// dirt background
dirtlong dirty(
  .clka(clk),    // input wire clka
  .addra(dirt128),  // input wire [13 : 0] addra
  .douta(dirt)  // output wire [11 : 0] douta
);

endmodule