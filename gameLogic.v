 `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Randon Stasney, Dakota Ward, Naveen Yalla, Kajal Zatale
// 
// Create Date: 05/24/2016 01:54:34 PM
// Design Name: dungeon crawler
// Module Name: gameLogic.v
// Project Name: Dungeon Crawler
// Target Devices: Nexy4fpga
// Tool Versions: Vivado
// Description: 
// This module provides the gamelogic collision for Dungeon Crawler.  This module takes
// in the x and y coordinates of the hero and determines if he interacts with in game elements
// which are just drawn icons on the screen.  It also takes in the location of the monster.
// The hero interacts with an element if he is +or- 1 in the x and y direction,  This interaction
// in the case of the treasure cues sound increments score and updates visual icon.  The portal 
// allows the hero to exit the game before he runs out of health.  The monster damages the player
// allows damage to the monster if the hero is swinging his sword, cues a death sound for the 
// monster and resets him so the hero can face him again.  The chest and exit have been hardcoded
// and if changed need to be modified in icon.v as well.  The sound runs on a 8KHz clock so sound 
// enable triggers at 65MHz need to be held for 8125 cycles.  This module also updates the health
// and score and provides the health decrement timer to set life span.
// 
//////////////////////////////////////////////////////////////////////////////////


module gameLogic(
   input clk,								// 65 MHz sysclock
   input reset,
   input [7:0] LocX,						// location of herobot from bot31.v 
   input [7:0] LocY,						// location of herobot from bot31.v 
   input [7:0] LocX_mon,					// location of monsterbot from bot.v 
   input [7:0] LocY_mon,					// location of monsterbot from bot.v
   input sword_swing,						// from left joystick pushbutton or center pad button
   output reg [1:0] game_over,				// triggers final screen in icon.v
   output reg [7:0] tc_info,				// one hot for wether che3st looted and open or not
   output reg monster_sound,				// growl on monster death
   output reg tc_sound,						// open treasure sound when looting chest
   output reg reset_mon,					// monster death to reet monster
   output reg heart,						// low health warning heartbeat sound
   output reg [7:0] score,					// score from chests and monster kills
   output reg [7:0] health					// health for timing dungeon insteraction

);
// trigger for holding signal so sound clock can capture it
reg [12:0] monster_sound_trig = 13'h0000;
reg [12:0] tc_sound_trig = 13'h0000;	
// hardwired x and y treasure locations based on 256x 256 map
reg [7:0] tc_locx1 = 8'h2F;
reg	[7:0] tc_locx2 = 8'hD1;
reg [7:0] tc_locx3 = 8'hD;
reg [7:0] tc_locx4 = 8'hD3;
reg [7:0] tc_locx5 = 8'h36;
reg [7:0] tc_locx6 = 8'hD3;
reg [7:0] tc_locx7 = 8'h3F;
reg [7:0] tc_locx8 = 8'hBC;
reg [7:0] tc_locy1 = 8'h27;
reg	[7:0] tc_locy2 = 8'h12; 
reg [7:0] tc_locy3 = 8'h5E; 
reg [7:0] tc_locy4 = 8'h66; 
reg [7:0] tc_locy5 = 8'h8C; 
reg [7:0] tc_locy6 = 8'hAD; 
reg [7:0] tc_locy7 = 8'hDA; 
reg [7:0] tc_locy8 = 8'hDA;
// exit portal location
reg [7:0] portal_x = 8'h98;
reg [7:0] portal_y = 8'hAC;
// monster health how many swings needed to kill him
reg [2:0] mon_health = 3'b111;
// timer for how often monster and hero interact when in same location
reg [27:0] intercount = 28'h2625A00;
// timer to decrement health
reg [27:0] healthcount = 28'h5BA9500;

	always @ (posedge clk) begin
		if (reset) begin // reset set base starting values
			reset_mon <= 1'b1;
			tc_info <= 8'h00;
			score <= 8'h00;
			health <= 8'hFF;
			tc_sound <= 1'b0;
			tc_sound_trig <= 13'h0000;
			monster_sound_trig <= 13'h0000;
			monster_sound <= 1'b0;
			game_over <= 2'b00;
			mon_health <= 3'b111;
			intercount <= 28'h2625A00;
			healthcount <= 28'hABA9500;
		end
		else begin
			// default values
			tc_sound_trig <= 13'h0000;
			monster_sound_trig <= 13'h0000;
			reset_mon <= 1'b0;
			tc_info <= tc_info;
			score <= score;
			health <= health;
			tc_sound <= 1'b0;
			monster_sound <= 1'b0;
			game_over <= game_over;
			mon_health <= mon_health;
			intercount <= intercount;
			healthcount <= healthcount;
			// trigger for heartbeat
			if (health <= 15)
				heart <= 1'b1;
			else heart <= 1'b0;
			// decrement health to time dungeon experience
			if (healthcount == 0) begin
				if (health != 0) begin
					health <= health - 1;
					healthcount <= 28'h5BA9500; 
				end
				// if he dies you get no gold and shut off heartbeat sound
				else begin
					heart <= 1'b0;
					score <= 8'h00;
					game_over <= 2'b11; // show fail death screen
				end
			end
			else begin
				health <= health;
				healthcount <= healthcount - 1;
			end
		if (health != 0) begin // so he can't interact after we have final screen
			// +- collision logic
			if (((LocX <= tc_locx1 + 1) && (LocX >= tc_locx1 - 1)) && ((LocY <= tc_locy1 + 1) && (LocY >= tc_locy1 - 1))) begin
				if (tc_info[0] == 1'b0) begin	// if "new" take action
				score <= score + 25;  			// increments score
				tc_sound_trig <= 13'h1FFF;		// cues sound effect
				tc_info[0] <= 1'b1;				// flags as interacted sets old and shows icon open
				end
				else begin
				end
			end
// same logic for all 8 treasure chests
			else if (((LocX <= tc_locx2 + 1) && (LocX >= tc_locx2 - 1)) && ((LocY <= tc_locy2 + 1) && (LocY >= tc_locy2 - 1))) begin
				if (tc_info[1] == 1'b0) begin
				score <= score + 25;
				tc_sound_trig <= 13'h1FFF;
				tc_info[1] <= 1'b1;
				end
				else begin
				end
			end
			else if (((LocX <= tc_locx3 + 1) && (LocX >= tc_locx3 - 1)) && ((LocY <= tc_locy3 + 1) && (LocY >= tc_locy3 - 1))) begin
				if (tc_info[2] == 1'b0) begin
				score <= score + 25;
				tc_sound_trig <= 13'h1FFF;
				tc_info[2] <= 1'b1;
				end
				else begin
				end
			end
			else if (((LocX <= tc_locx4 + 1) && (LocX >= tc_locx4 - 1)) && ((LocY <= tc_locy4 + 1) && (LocY >= tc_locy4 - 1))) begin
				if (tc_info[3] == 1'b0) begin
				score <= score + 25;
				tc_sound_trig <= 13'h1FFF;
				tc_info[3] <= 1'b1;
				end
				else begin
				end
			end
			else if (((LocX <= tc_locx5 + 1) && (LocX >= tc_locx5 - 1)) && ((LocY <= tc_locy5 + 1) && (LocY >= tc_locy5 - 1))) begin
				if (tc_info[4] == 1'b0) begin
				score <= score + 25;
				tc_sound_trig <= 13'h1FFF;
				tc_info[4] <= 1'b1;
				end
				else begin
				end
			end
			else if (((LocX <= tc_locx6 + 1) && (LocX >= tc_locx6 - 1)) && ((LocY <= tc_locy6 + 1) && (LocY >= tc_locy6 - 1))) begin
				if (tc_info[5] == 1'b0) begin
				score <= score + 25;
				tc_sound_trig <= 13'h1FFF;
				tc_info[5] <= 1'b1;
				end
				else begin
				end
			end
			else if (((LocX <= tc_locx7 + 1) && (LocX >= tc_locx7 - 1)) && ((LocY <= tc_locy7 + 1) && (LocY >= tc_locy7 - 1))) begin
				if (tc_info[6] == 1'b0) begin
				score <= score + 25;
				tc_sound_trig <= 13'h1FFF;
				tc_info[6] <= 1'b1;
				end
				else begin
				end
			end
			else if (((LocX <= tc_locx8 + 1) && (LocX >= tc_locx8 - 1)) && ((LocY <= tc_locy8 + 1) && (LocY >= tc_locy8 - 1))) begin
				if (tc_info[7] == 1'b0) begin
				score <= score + 25;
				tc_sound_trig <= 13'h1FFF;
				tc_info[7] <= 1'b1;
				end
				else begin
				end
			end
			else begin
			end
// counter to hold sound signal for 8125 cycles so it's captured by 8KHz clock
			if (tc_sound_trig != 13'h0000)begin
				tc_sound_trig <= tc_sound_trig - 1;
				tc_sound <= 1'b1;
			end
			else
				tc_sound <= 0;
			
			

			
			// portal interaction to allow game end and "win" keep gold
			if (((LocX <= portal_x + 1) && (LocX >= portal_x - 1)) && ((LocY <= portal_y + 1) && (LocY >= portal_y - 1))) begin
				game_over <= 2'b10; // display "win" endscreen fron icon.v
				heart <= 1'b0; 		// turn off heartbeat
				health <= 1'b1;		// set health to almost dead to avoid display on final screen
				score <= score;		// get to keep score
			end
			else begin
			end
			
// monster interaction			
			if (((LocX <= LocX_mon + 1) && (LocX >= LocX_mon - 1)) && ((LocY <= LocY_mon + 1) && (LocY >= LocY_mon - 1))) begin
				if (intercount != 0) begin
					intercount <= intercount - 1;
				end
				else begin
				// sample values to determine interaction every 30 seconds
					intercount <= 28'h2625A00;
					if (mon_health != 3'b000) begin
						if (sword_swing == 1'b1) begin     	// if we are swinging sowrd we damage the monster as he damages us
							mon_health <= mon_health - 1;	// we hit him for 1 damage
							if (health <= 5) 				// if we're below 5 health he kills us
								health <= 0;
							else health <= health - 5;		// other wise we lose 5 health while attacking
						end
						else begin
							if (health <= 5) 
								health <= 0;
							else health <= health - 5;		// we aren't attacking or damaging him but he is us
						end
					end
					else begin
						score <= score + 50;				// we kill him we get double score than chest
						monster_sound_trig <= 13'h1FFF;		// cue monster growl
						reset_mon <= 1'b1;					// reset him so he starts over at entrance going along line
						mon_health <= 3'b111;				// give new monster fresh health
					end
				end
			end
			else begin
			end
			// timer to hold signal so captured by 8KHz clock
			if (monster_sound_trig != 13'h0000)begin
				monster_sound_trig <= monster_sound_trig -1;
				monster_sound <= 1'b1;
			end
			else
				monster_sound <= 0;
		end // health !00
		else
		begin
		end
		end // else !reset
	end // always
endmodule

