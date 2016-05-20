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
   input [10:0] LocX,						// location of bot from bot.v multiplied by 8 for scaling
   input [10:0] LocY,						// location of bot from bot.v multiplied by 6 for scaling
   input [2:0] Botinfo,						// orientation of bot from bot.v
   output reg [12:0] death_pixel, mil_pixel,
   output reg [1:0] icon_pixel				// output of color coded info to colorizer
);

   
   wire [10:0] new_row, new_col, new_death;			// wire to hold the offset values for icon placement
   reg [11:0] rom_0;									// the icon address 
   reg [16:0] death, deaths, dean;						// deathstar icon addressing
   wire out_0a,out_0b,out_45a,out_45b,out_90a, 		// output of pixel color information for icons
        out_90b,out_135a, out_135b, out_180a, 
        out_180b,out_225a,out_225b,out_270a,
        out_270b, out_315a,out_315b;
	wire [3:0] deathoutR, deathoutG, deathoutB, deathoutsR, deathoutsG, deathoutsB, milB, milG, milR;					// output of pixel color for death star
	wire [3:0] deathoutBR, deathoutBG, deathoutBB, deathoutsBR, deathoutsBG, deathoutsBB, deanr, deang, deanb;
	
	assign new_death = pixel_row + 8'b10000000;   	// offest to place the icon in the upper left hand above the track
	assign new_row = pixel_row - 6;					// offest the icon determined by case statement to add the lsb back into
	assign new_col= pixel_column - 8;				// the location so every 128 x 128 can be selected
//	assign deaths = (((pixel_column/3)*256) + (pixel_row/4));
	// always block to determine ouput when icon is being overlapped by the pixel stream
	always @ (posedge clk) begin
       if ((pixel_row == 0) && (pixel_column == 0)) begin // reset at every new frame to prevent drift
         rom_0 <= 0;
		 death <= 0;
		 dean <= 0;
		 deaths <= 0;
         icon_pixel <= 2'b00;
		 death_pixel <= 13'b0000000000000;
		 mil_pixel <= 13'b0000000000000;
       end
       else begin  // check to see if there is icon data in the location of the current pixel stream
		death <= death; // default
		dean <= (((pixel_row/6)*1024) + (pixel_column));
		deaths <= (((pixel_row/3)*256) + (pixel_column/4));
		icon_pixel <= 2'b00;
		mil_pixel <= 13'b0000000000000;
		
		if ((pixel_row[10:6] == LocY[10:6]) && (pixel_column[10:6] == LocX[10:6])) begin
		  rom_0 <= rom_0 + 1;
		  mil_pixel <= {1'b1, milB, milG, milR};
		end
                           else begin
                           rom_0 <= rom_0;
                           icon_pixel <= 2'b00;
						   mil_pixel <= 13'b0000000000000;
                           end
		//	death_pixel <= {1'b1, deathoutsBB, deathoutsBG, deathoutsBR};
		//	if ((pixel_column[10:8] == 4'h1) && ( new_death [10:8] == 4'h1)) begin // stationary overlap places the deathstar
		//		death <= death + 1;	
		if ((LocY[8:6] == 3'b110)&&(LocX[10:3] == 8'h3A))
			//if (LocX[10:3] == 8'h3A)
		//		death_pixel <= {1'b1, deathoutBB, deathoutBG, deathoutBR};	
		//death_pixel <= {1'b1, deathoutsBB, deathoutsBG, deathoutsBR};
				death_pixel <= {1'b1, deanb, deang, deanr};
				else
	//			begin
				//death_pixel <= {1'b1, deathoutsB, deathoutsG, deathoutsR};
				death_pixel <= {1'b1, deanb, deang, deanr};
			   // iterate through the block ram to display color values
		//	death_pixel <= {1'b1, deathoutB, deathoutG, deathoutR};	
	//		end
			//else begin
		/*	
               case ({LocY[3], LocX[3]}) // to overlap 16 bits we reenter the location to be able to access every x and y location
               2'b00:   begin 
							//  if we overlap we read and increment from the block ram
                           if ((pixel_row[10:4] == LocY[10:4]) && (pixel_column[10:4] == LocX[10:4])) begin
                           rom_0 <= rom_0 + 1;
                           case(Botinfo) // we select which icon orientation to display based on the botinfo

                               3'b000:    	icon_pixel <={out_0a,out_0b};        	// 0 degrees
                               3'b001: 		icon_pixel <={out_45a,out_45b};        	// 45 degrees
                               3'b010:    	icon_pixel <={out_90a,out_90b};        	//90 degrees
                               3'b011:    	icon_pixel <={out_135a,out_135b};    	//135 degrees
                               3'b100:    	icon_pixel <={out_180a,out_180b};    	//180 degrees
                               3'b101:    	icon_pixel <={out_225a,out_225b};    	//225 degrees
                               3'b110: 		icon_pixel <={out_270a,out_270b};    	//270 degress
                               3'b111:    	icon_pixel <={out_315a,out_315b};    	//315 degrees
                               default: 	icon_pixel <= 2'b00;
                           endcase    
                           end  
								// or we let the map info be displayed by outputting icon clear
                           else begin  
                           rom_0 <= rom_0;
                           icon_pixel <= 2'b00;
                           end    
						end
               2'b01:   begin 
							//  if we overlap we read and increment from the block ram
                           if ((pixel_row[10:4] == (LocY[10:4])) && (new_col[10:4] == (LocX[10:4]))) begin
                           rom_0 <= rom_0 + 1;
                           case(Botinfo) // we select which icon orientation to display based on the botinfo

                               3'b000:    	icon_pixel <={out_0a,out_0b};        	// 0 degrees
                               3'b001: 		icon_pixel <={out_45a,out_45b};        	// 45 degrees
                               3'b010:    	icon_pixel <={out_90a,out_90b};        	//90 degrees
                               3'b011:    	icon_pixel <={out_135a,out_135b};    	//135 degrees
                               3'b100:    	icon_pixel <={out_180a,out_180b};    	//180 degrees
                               3'b101:    	icon_pixel <={out_225a,out_225b};    	//225 degrees
                               3'b110: 		icon_pixel <={out_270a,out_270b};    	//270 degress
                               3'b111:    	icon_pixel <={out_315a,out_315b};    	//315 degrees
                               default: 	icon_pixel <= 2'b00;
                           endcase    
                           end
							// or we let the map info be displayed by outputting icon clear
                           else begin
                           rom_0 <= rom_0;
                           icon_pixel <= 2'b00;
                           end    
						end
               2'b10:   begin 
							//  if we overlap we read and increment from the block ram
                           if ((new_row[10:4] == (LocY[10:4] )) && (pixel_column[10:4] == LocX[10:4])) begin
                           rom_0 <= rom_0 + 1;
                           case(Botinfo) // we select which icon orientation to display based on the botinfo

                               3'b000:    	icon_pixel <={out_0a,out_0b};        	// 0 degrees
                               3'b001: 		icon_pixel <={out_45a,out_45b};        	// 45 degrees
                               3'b010:    	icon_pixel <={out_90a,out_90b};        	//90 degrees
                               3'b011:    	icon_pixel <={out_135a,out_135b};    	//135 degrees
                               3'b100:    	icon_pixel <={out_180a,out_180b};    	//180 degrees
                               3'b101:    	icon_pixel <={out_225a,out_225b};    	//225 degrees
                               3'b110: 		icon_pixel <={out_270a,out_270b};    	//270 degress
                               3'b111:    	icon_pixel <={out_315a,out_315b};    	//315 degrees
                               default: 	icon_pixel <= 2'b00;
                           endcase    
                           end 
							// or we let the map infor be displayed by outputting icon clear
                           else begin
                           rom_0 <= rom_0;
                           icon_pixel <= 2'b00;
                           end    
						end
               2'b11:   begin 
							//  if we overlap we read and increment from the block ram
                           if ((new_row[10:4] == (LocY[10:4] )) && (new_col[10:4] == (LocX[10:4]))) begin
                           rom_0 <= rom_0 + 1;
                           case(Botinfo) // we select which icon orientation to display based on the botinfo

                               3'b000:    	icon_pixel <={out_0a,out_0b};        	// 0 degrees
                               3'b001: 		icon_pixel <={out_45a,out_45b};        	// 45 degrees
                               3'b010:    	icon_pixel <={out_90a,out_90b};        	//90 degrees
                               3'b011:    	icon_pixel <={out_135a,out_135b};    	//135 degrees
                               3'b100:    	icon_pixel <={out_180a,out_180b};    	//180 degrees
                               3'b101:    	icon_pixel <={out_225a,out_225b};    	//225 degrees
                               3'b110: 		icon_pixel <={out_270a,out_270b};    	//270 degress
                               3'b111:    	icon_pixel <={out_315a,out_315b};    	//315 degrees
                               default: 	icon_pixel <= 2'b00;
                           endcase    
                           end   
							// or we let the map infor be displayed by outputting icon clear
                           else begin
                           rom_0 <= rom_0;
                           icon_pixel <= 2'b00;
                           end    
                       end
               endcase
			*///end
       end
   end  
   
//  Icons based on class example 16 x 16 represented as a 512 x 1 memory 
//  the first 256 bits are the msb of the 2 bit output and the lsb is accessed
//  by adding the 1'b1 to the address to access the memory 256 - 511
mB milb (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [11 : 0] addra
  .douta(milB)  // output wire [3 : 0] douta
);
mg milg (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [11 : 0] addra
  .douta(milG)  // output wire [3 : 0] douta
);
mr milr (
  .clka(clk),    // input wire clka
  .addra(rom_0),  // input wire [11 : 0] addra
  .douta(milR)  // output wire [3 : 0] douta
);
ICON_0 icon_0 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_0a),              	// output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_0b)              	// output wire [ : 0] doutb
   
 );   
ICON_45 icon_45 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_45a),              	// output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_45b)              	// output wire [ : 0] doutb
); 
ICON_90 icon_90 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_90a),              	// output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_90b)              	// output wire [ : 0] doutb
);
ICON_135 icon_135 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_135a),              // output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_135b)              	// output wire [ : 0] doutb
); 
ICON_180 icon_180 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_180a),              // output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_180b)              	// output wire [ : 0] doutb
); 
ICON_225 icon_225 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_225a),              // output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_225b)              	// output wire [ : 0] doutb
);
ICON_270 icon_270 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_270a),              // output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_270b)              	// output wire [ : 0] doutb
);
ICON_315 icon_315 (
 .clka(clk),                    // input wire clka
 .addra(rom_0),      			// input wire [8 : 0] addra
 .douta(out_315a),              // output wire [ : 0] douta
 .clkb(clk),                    // input wire clkb
 .addrb({1'b1,rom_0}),      	// input wire [8 : 0] addrb
 .doutb(out_315b)              	// output wire [ : 0] doutb
);

// the death star is a 256 x 256 pixel image represented as a 65536 x 2 memory
// with the width representing both the pixels for the output to go to colorizer
death_B blue (
  .clka(clk),    // input wire clka
  .addra(death),  // input wire [15 : 0] addra
  .douta(deathoutB),  // output wire [3 : 0] douta
  .clkb(clk),    // input wire clkb
  .addrb(deaths),  // input wire [15 : 0] addrb
  .doutb(deathoutsB)  // output wire [3 : 0] doutb
);

death_R red (
  .clka(clk),    // input wire clka
  .addra(death),  // input wire [15 : 0] addra
  .douta(deathoutR),  // output wire [3 : 0] douta
  .clkb(clk),    // input wire clkb
  .addrb(deaths),  // input wire [15 : 0] addrb
  .doutb(deathoutsR)  // output wire [3 : 0] doutb
);


death_G green (
  .clka(clk),    				// input wire clka
  .addra(death),  				// input wire [15 : 0] addra
  .douta(deathoutG),  			// output wire [1 : 0] douta
  .clkb(clk),    				// input wire clkb
  .addrb(deaths),  				// input wire [15 : 0] addrb ; not used in this design
  .doutb(deathoutsG)  			// output wire [1 : 0] doutb
);
death_BR bred (
  .clka(clk),    // input wire clka
  .addra(death),  // input wire [15 : 0] addra
  .douta(deathoutBR),  // output wire [3 : 0] douta
  .clkb(clk),    // input wire clkb
  .addrb(deaths),  // input wire [15 : 0] addrb
  .doutb(deathoutsBR)  // output wire [3 : 0] doutb
);
death_BG bgreen (
  .clka(clk),    // input wire clka
  .addra(death),  // input wire [15 : 0] addra
  .douta(deathoutBG),  // output wire [3 : 0] douta
  .clkb(clk),    // input wire clkb
  .addrb(deaths),  // input wire [15 : 0] addrb
  .doutb(deathoutsBG)  // output wire [3 : 0] doutb
);
death_BB bblue (
  .clka(clk),    // input wire clka
  .addra(death),  // input wire [15 : 0] addra
  .douta(deathoutBB),  // output wire [3 : 0] douta
  .clkb(clk),    // input wire clkb
  .addrb(deaths),  // input wire [15 : 0] addrb
  .doutb(deathoutsBB)  // output wire [3 : 0] doutb
);
deanb db(
  .clka(clk),    // input wire clka
  .addra(dean),  // input wire [16 : 0] addra
  .douta(deanb)  // output wire [3 : 0] douta
);
deanr dr (
  .clka(clk),    // input wire clka
  .addra(dean),  // input wire [16 : 0] addra
  .douta(deanr)  // output wire [3 : 0] douta
);
deang dg (
  .clka(clk),    // input wire clka
  .addra(dean),  // input wire [16 : 0] addra
  .douta(deang)  // output wire [3 : 0] douta
);
endmodule
