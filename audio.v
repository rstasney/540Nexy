`timescale 1ns / 1ps
// audio.v -  design for ECE 540 final Project
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
// This module is now the audio control for Dungeon Crawler.  The sounds were 
// sampled at 8 KHz and saved aS 8 bit values in distributed rom from thier 
// .coe files.  The module captures a trigger or allows continous playback for
// the sounds.  The sounds are in order with the last one having precendent to 
// set music data based on its information. so welcome plays over monster death 
// over treasure open over sword over heartbeat.
//
///////////////////////////////////////////////////////////////////////////

module audio(
    input clk, 				//65 MHz clock
	input reset,
    input [5:0] jump_ena, 	// triggers
    output PWM_out			// output PWM to mono jack on nexys4 board
    );
	
// creation of 8KHz clock signal
    reg             clk_8khz = 0;
    reg     [11:0]  divideCounter = 0;
	
// data from music memory
    reg     [7:0]   music_data;
	
	reg [7:0] welcome = 8'hFF;		// queue welcome at start and reset
  
// address line width for memory access to sound files
    parameter integer	ADDR_WDITH_monster    		    = 14;
    parameter integer	ADDR_WDITH_Myheaartbeat 		= 15;
    parameter integer	ADDR_WDITH_sword_Swing		    = 12;
    parameter integer	ADDR_WDITH_Treasure_Chest	    = 14;
    parameter integer	ADDR_WDITH_welcome_converted	= 13;
     
// total number of lines in each rom(number of lines in coe)
    parameter integer	DEPTH_monster    		        = 14400;
    parameter integer	DEPTH_Myheaartbeat 		        = 17280;
    parameter integer	DEPTH_sword_Swing		        = 2496;
    parameter integer	DEPTH_Treasure_Chest	        = 12096;
    parameter integer	DEPTH_welcome_converted	        = 7104;

// music data from memory
    wire     [7:0]  music_data_heartbeat,
                    music_data_monster,
                    music_data_swordswing,
                    music_data_treasure,
                    music_data_welcome;
 
// trigger for sound
    reg             heartbeat_ena;
    reg             monster_ena;
    reg             swordswing_ena;
    reg             treasure_ena;
    reg             welcome_ena;
    
// address reading

    reg    [ADDR_WDITH_Myheaartbeat - 1   :0]     temp_address_heartbeat;
    reg    [ADDR_WDITH_monster - 1        :0]     temp_address_monster;
    reg    [ADDR_WDITH_sword_Swing - 1    :0]     temp_address_swordswing;
    reg    [ADDR_WDITH_Treasure_Chest - 1 :0]     temp_address_treasure;
    reg    [ADDR_WDITH_welcome_converted-1:0]     temp_address_welcome;


 // send memory data to PWM 
 audio_PWM audioPWM(.clk(clk), .reset(0), .music_data(music_data), .PWM_out(PWM_out));
 
     // Generate 8khz clock for reading samples
	    always @(posedge clk) begin
			if (divideCounter < 4062) begin  // new counter values since we're using a 65MHz main clock
				divideCounter <= divideCounter+1;
			end else begin
            divideCounter <= 0;
            clk_8khz <= !clk_8khz;
			end
		end
		
// Using 8KHz clock for addressing and playback
    always @(posedge clk_8khz) begin
	if (reset) begin
		welcome <= 8'hFF; 	// reset welcome 
	end
	else begin
		if (welcome != 0)	// play welcome at startup
			welcome <= welcome -1;
		else
			welcome <= welcome;
			
		temp_address_heartbeat <= 0;	
		
		if(jump_ena[1] == 1'b1) begin //  heartbeat
            if(temp_address_heartbeat <= DEPTH_Myheaartbeat) begin
                      temp_address_heartbeat <= temp_address_heartbeat + 1; // allow heartbeat to play continous
                      heartbeat_ena <= 1'b1;
                      music_data    <= music_data_heartbeat;
            end
			else begin
                      temp_address_heartbeat <= 0;
                      heartbeat_ena <= 1'b0;
            end
        end
        else begin					// trigger activated to play through sound once
            if(heartbeat_ena & (temp_address_heartbeat <= DEPTH_Myheaartbeat)) begin
                      temp_address_heartbeat <= temp_address_heartbeat + 1;
                      heartbeat_ena <= 1'b1;
                      music_data    <= music_data_heartbeat;
             end
             else begin
                      temp_address_heartbeat <= 0;
                      heartbeat_ena <= 1'b0;
             end
        end 

                  
        if(jump_ena[3] == 1'b1) begin  // sword swing
            if(temp_address_swordswing <= DEPTH_sword_Swing) begin
                      temp_address_swordswing <= temp_address_swordswing + 1;	// allow to play continous if held down
                      swordswing_ena <= 1'b1;  // trigger to play sound once
                      music_data    <= music_data_swordswing;
            end
            else begin
                      temp_address_swordswing <= 0;
                      swordswing_ena <= 1'b0;
            end
         end
        else begin		// trigger has been activated play sound once
            if(swordswing_ena & (temp_address_swordswing <= DEPTH_sword_Swing)) begin
                      temp_address_swordswing <= temp_address_swordswing + 1;
                      swordswing_ena <= 1'b1;
                      music_data    <= music_data_swordswing;
             end
             else begin
                      temp_address_swordswing <= 0;
                      swordswing_ena <= 1'b0;
             end
        end

 
       if(jump_ena[4] == 1'b1) begin  // treasure
                    treasure_ena  <= 1'b1;  // activate trigger to play once
                    temp_address_treasure <= 0;
                    end
        else begin		// play through sound one time
            if(treasure_ena & (temp_address_treasure <= DEPTH_Treasure_Chest)) begin
                      temp_address_treasure <= temp_address_treasure + 1;
                      treasure_ena <= 1'b1;
                      music_data    <= music_data_treasure;
             end
             else begin
                      temp_address_treasure <= 0;
                      treasure_ena <= 1'b0;
             end
        end
		
		     
        if(jump_ena[2] == 1'b1) begin  // monster death growl
                            monster_ena  <= 1'b1;  // terigger activated
                            temp_address_monster <= 0;
                            end
                else begin		// play through death growl once
                    if(monster_ena & (temp_address_monster <= DEPTH_monster)) begin
                              temp_address_monster <= temp_address_monster + 1;
                              monster_ena <= 1'b1;
                              music_data    <= music_data_monster;
                     end
                     else begin
                              temp_address_monster <= 0;
                              monster_ena <= 1'b0;
                     end
                end           
     
       // play welcome at startup and on reset to initialize hero 
       if(welcome != 8'h00) begin
                     welcome_ena  <= 1'b1;  // set trigger
                     temp_address_welcome <= 0;
                     end
         else begin   // play through once
             if(welcome_ena & (temp_address_welcome <= DEPTH_welcome_converted)) begin
                       temp_address_welcome <= temp_address_welcome + 1;
                       welcome_ena <= 1'b1;
                       music_data    <= music_data_welcome;
              end
              else begin
                       temp_address_welcome <= 0;
                       welcome_ena <= 1'b0;
              end
         end
       
    end
end

// instantiate distributed ROM memories
      Myheaartbeat myheartbeat (
            .a(temp_address_heartbeat),        	// input wire [14 : 0] a
            .qspo_ce(1'b1),          			// input wire qspo_ce
            .spo(music_data_heartbeat)        	// output wire [7 : 0] spo
      );
   
   
      monster monster (
            .a(temp_address_monster),        	// input wire [13 : 0] a
            .qspo_ce(1'b1),          			// input wire qspo_ce
            .spo(music_data_monster)        	// output wire [7 : 0] spo
      );
 
      Sword_Swing swordswing (
            .a(temp_address_swordswing),        // input wire [13 : 0] a
            .qspo_ce(1'b1),          			// input wire qspo_ce
            .spo(music_data_swordswing)        	// output wire [7 : 0] spo
      );

      Treasure_Chest treasurechest (
            .a(temp_address_treasure),        	// input wire [13 : 0] a
            .qspo_ce(1'b1),          			// input wire qspo_ce
            .spo(music_data_treasure)        	// output wire [7 : 0] spo
      );
 
      welcome_converted welcomesound (
            .a(temp_address_welcome),        	// input wire [12 : 0] a
            .qspo_ce(welcome_ena),          	// input wire qspo_ce
            .spo(music_data_welcome)        	// output wire [7 : 0] spo
      ); 
 
    endmodule

