 `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Randon Stasney Dakota Ward
// 
// Create Date: 04/28/2016 01:54:34 PM
// Design Name: proj2demo
// Module Name: icon
// Project Name: ROJO Bot
// Target Devices: Nexy4fpga
// Tool Versions: Vivado
// Description: 
// This module instantiates the block rams for the icons.  It then takes the pixel data from the dtg 
// and the takes the location from the bot and determines whether to pass on the color information 
// from the icon or set the output as 00 which will allow the world map to be output on the screen. 
// If the pixel data location overlaps the location of the icon then the output stream is the color
// coded output from the memory location
// Revision: 2.0 Added death star icon
// Revision  1.0 changed to incorperate the larger screen resolution and add offset logic
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module icon(
   input clk,								// sysclock
   input [10:0] pixel_row,      			// from dtg
   input [10:0] pixel_column,   			// from dtg 
   input [11:0] LocX,						// location of bot from bot.v multiplied by 16 for scaling
   input [11:0] LocY,						// location of bot from bot.v multiplied by 12 for scaling
   input [11:0] LocX_mon,						// location of bot from bot.v multiplied by 16 for scaling
   input [11:0] LocY_mon,						// location of bot from bot.v multiplied by 12 for scaling
   input [2:0] Botinfo,						// orientation of bot from bot.v
   output reg [12:0] death_pixel, mil_pixel,rock_pixel, mon_pixel, grass_pixel,
   output reg [1:0] icon_pixel				// output of color coded info to colorizer
);

   reg [8:0] tick;
   wire [10:0] new_row, new_col;// new_death;			// wire to hold the offset values for icon placement
   reg [13:0] rom_0, mona;									// the icon address 
//   reg [16:0] death, deaths, dean;						// deathstar icon addressing
   reg [15:0]	grass_a, stone_a, dirt_a;

	wire	[11:0] frtknig, dirt, wall, monout, Bkn, Rkn, Lkn, grass;
//	assign new_death = pixel_row + 8'b10000000;   	// offest to place the icon in the upper left hand above the track
	assign new_row = (LocY_mon - (LocY - 384));		//384			// offest the icon determined by case statement to add the lsb back into
	assign new_col = (LocX_mon - (LocX - 512));		//512		// the location so every 128 x 128 can be selected
//	assign deaths = (((pixel_column/3)*256) + (pixel_row/4));
	// always block to determine ouput when icon is being overlapped by the pixel stream
	always @ (posedge clk) begin
       if ((pixel_row == 0) && (pixel_column == 0)) begin // reset at every new frame to prevent drift
         rom_0 <= 0;
		 mona <= 0;
		 stone_a <= 0;
		 grass_a <= 0;
		 dirt_a <= 0;
	//	 deaths <= 0;
         icon_pixel <= 2'b00;
		 death_pixel <= 13'b0000000000000;
		 mil_pixel <= 13'b0000000000000;
		 mon_pixel <= 13'b0000000000000;
		 rock_pixel <= 13'b0000000000000;
		 grass_pixel <= 13'b0000000000000;
		 tick <= 0;
       end
       else begin  // check to see if there is icon data in the location of the current pixel stream
	//	death <= death; // default
		//stone 
		//if (tick == 127)
		//tick <= 0;
		//else 
		//tick <= tick + 1;
		//stone <= ((pixel_row/2) * 256) + tick/2;  //  (tick * 256) + pixel_column;
		//stone <= (((pixel_row/4)*256) + (pixel_column/4));
	//	stone <= (((pixel_row)*256) + (tick));
		stone_a <= (((pixel_row/2)*512) + (pixel_column/2));
		grass_a <= (((pixel_row/2)*512) + (pixel_column/2));
		dirt_a <= (((pixel_row/2)*512) + (pixel_column/2));
	//	dean <= (((pixel_row/6)*1024) + (pixel_column));
	//	deaths <= (((pixel_row/3)*256) + (pixel_column/4));
		icon_pixel <= 2'b00;
		mil_pixel <= 13'b0000000000000;
		mon_pixel <= 13'b0000000000000;
		rock_pixel <= {1'b1, wall};
		death_pixel <= {1'b1, dirt};
		grass_pixel <= {1'b1, grass};
		/// if monster is within sight of hero location we display on the screen
		if ((LocX_mon >= LocX - 512 && LocX_mon <= LocX + 512)&& (LocY_mon >= LocY - 384 && LocY_mon <= LocY +384)) begin
		//  The monster can be in 4 relative positions to the hero so we use relative positioning to place him
		//  to avoid negative numbers we find which location is greater the hero or the monster and by subtraction we can then place
		// the monster block relative to the hero
			if 	(LocX >= LocX_mon)begin
		
				if (LocY >= LocY_mon)begin
					if (((pixel_column >= 11'b001_1100_0000 - ( (LocX - LocX_mon))) && (pixel_column <= 11'b010_0100_0000 - ( (LocX - LocX_mon))))&&((pixel_row >= 11'b001_0100_0000 - ( (LocY - LocY_mon)))&& (pixel_row <= 11'b001_1100_0000 - ( (LocY - LocY_mon))))) begin	
/////////////////////************************the block works fine but the monster scrolls inside the block based on the position of the hero
//we need to compenste for that	and just draw him from the "box" here are the last 4 attemps I made you can test them bu just having the hero in a different quadrant from
// the monster and that way you can test 4 ways at once
// Please help find a solution				
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

				
				
				
/*			this is how we drew first icon	
			
			if ((pixel_row[10:7] == LocY[10:7]) && (pixel_column[10:7] == LocX[10:7])) begin 
			mona<= mona +1 ;
			mon_pixel <= {1'b1, monout};
            else begin
                mona <= mona;
                icon_pixel <= 2'b00;
				mon_pixel <= 13'b0000000000000;			
			end

*/		
		if ((LocX >= 512 && LocX <= 3584)&& (LocY >= 384 && LocY <= 2688)) begin
			if (((pixel_column >= 11'b001_1100_0000) && (pixel_column <= 11'b010_0100_0000))&&((pixel_row >= 11'b001_0100_0000)&& (pixel_row <= 11'b001_1100_0000))) begin
				
				rom_0 <= (((pixel_column + 6'b11_1111)) + (pixel_row + 8'b1011_1111)*128);
					case(Botinfo) // we select which icon orientation to display based on the botinfo

                        3'b100:    		mil_pixel <= {1'b1, frtknig};       	// 0 degrees
                       // 3'b001: 		icon_pixel <={out_45a,out_45b};        	// 45 degrees
                        3'b110:    		mil_pixel <= {1'b1, Lkn};        	//90 degrees
                         //      3'b011:    	icon_pixel <={out_135a,out_135b};    	//135 degrees
                        3'b000:    		mil_pixel <= {1'b1, Bkn};   	//180 degrees
                             //  3'b101:    	icon_pixel <={out_225a,out_225b};    	//225 degrees
                        3'b010: 		mil_pixel <= {1'b1, Rkn};    	//270 degress
                             //  3'b111:    	icon_pixel <={out_315a,out_315b};    	//315 degrees
                        default: 	mil_pixel <= 13'b0000000000000;
                           endcase 
				
			end
            else begin
                rom_0 <= rom_0;
                icon_pixel <= 2'b00;
				mil_pixel <= 13'b0000000000000;
            end
		end
		//if ((pixel_row[10:6] == LocY[10:6]) && (pixel_column[10:6] == LocX[10:6])) begin
		 // rom_0 <= rom_0 + 1;
		//  mil_pixel <= {1'b1, milB, milG, milR};
		//end
		else begin  // once we try and draw screen not by hero we "jump" because each x,y is a 16 pixel block maybe it can be centered
		    if ((pixel_row[10:7] == LocY[10:7]) && (pixel_column[10:7] == LocX[10:7])) begin //128 bit icon
                rom_0 <= rom_0 + 1;
				mil_pixel <= {1'b1, frtknig};
			end
			else begin
                rom_0 <= rom_0;
                icon_pixel <= 2'b00;
				mil_pixel <= 13'b0000000000000;
			end
		end

       end
   end  
   

knitg kg (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [13 : 0] addra
  .douta(frtknig)  // output wire [3 : 0] douta
);

stoneg sg ( // wall world map code 2
  .clka(clk),    // input wire clka
  .addra(stone_a),  // input wire [15 : 0] addra
  .douta(wall)  // output wire [3 : 0] douta
);
//deanmon
Mons ms (
  .clka(clk),    // input wire clka
  .addra(mona),  // input wire [15 : 0] addra
  .douta(monout)  // output wire [3 : 0] douta
);

grassg gg ( // world map 0 background
  .clka(clk),    // input wire clka
  .addra(dirt_a),  // input wire [15 : 0] addra
  .douta(dirt)  // output wire [3 : 0] douta
);
shrub bcgr (	// world map 3 greenery
  .clka(clk),    // input wire clka
  .addra(grass_a),  // input wire [15 : 0] addra
  .douta(grass)  // output wire [3 : 0] douta
);

KnBck KB (  
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [15 : 0] addra
  .douta(Bkn)  // output wire [11 : 0] douta
);
KnLft KL (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [15 : 0] addra
  .douta(Lkn)  // output wire [11 : 0] douta
);
KnRt KR (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [15 : 0] addra
  .douta(Rkn)  // output wire [11 : 0] douta
);

endmodule
