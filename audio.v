`timescale 1ns / 1ps


module audio(
    input clk, // 25 MHz clock
    input [5:0] jump_ena,

    output PWM_out
    );

    reg             clk_8khz=0;
    reg     [11:0]  divideCounter=0;
    reg     [7:0]   music_data;
  
//address line width for each distributed rom (sounds)
//    parameter integer   ADDR_WDITH                      = 0;
    parameter integer	ADDR_WDITH_exit_sound		    = 13;  //edited
    parameter integer	ADDR_WDITH_Gold_4_converted	    = 13;
    parameter integer	ADDR_WDITH_Hit_Hurt   		    = 13;
    parameter integer	ADDR_WDITH_Hit_Hurt38		    = 12;
    parameter integer	ADDR_WDITH_hurt       		    = 12;
    parameter integer	ADDR_WDITH_Knifeattack		    = 13;
    parameter integer	ADDR_WDITH_monster    		    = 14;
    parameter integer	ADDR_WDITH_MycoinPickup		    = 12;
    parameter integer	ADDR_WDITH_Mygameend  		    = 13;
    parameter integer	ADDR_WDITH_Myheaartbeat 		= 15;
    parameter integer	ADDR_WDITH_StartBGM   		    = 15;
    parameter integer	ADDR_WDITH_sword_Swing		    = 14;
    parameter integer	ADDR_WDITH_Swordpick  		    = 11;
    parameter integer	ADDR_WDITH_Treasure_Chest	    = 14;
    parameter integer	ADDR_WDITH_welcome_converted	= 13;
     
//total number of lines in each rom(number of lines in coe)
//    parameter integer   DEPTH                           = 0;
    parameter integer	DEPTH_exit_sound		        = 4416;  //edited
    parameter integer	DEPTH_Gold_4_converted	        = 7488;
    parameter integer	DEPTH_Hit_Hurt   		        = 6336;
    parameter integer	DEPTH_Hit_Hurt38		        = 4032;
    parameter integer	DEPTH_hurt       		        = 3456;
    parameter integer	DEPTH_Knifeattack		        = 6336;
    parameter integer	DEPTH_monster    		        = 14400;
    parameter integer	DEPTH_MycoinPickup		        = 2304;
    parameter integer	DEPTH_Mygameend  		        = 5376;
    parameter integer	DEPTH_Myheaartbeat 		        = 17280;
    parameter integer	DEPTH_StartBGM   		        = 22464;
    parameter integer	DEPTH_sword_Swing		        = 10944;
    parameter integer	DEPTH_Swordpick  		        = 4032;
    parameter integer	DEPTH_Treasure_Chest	        = 12096;
    parameter integer	DEPTH_welcome_converted	        = 7104;


    wire     [7:0]  music_data_exitsound,
                    music_data_heartbeat,
                    music_data_monster,
                    music_data_swordswing,
                    music_data_treasure,
                    music_data_welcome;
 
    reg             exitsound_ena;
    reg             heartbeat_ena;
    reg             monster_ena;
    reg             swordswing_ena;
    reg             treasure_ena;
    reg             welcome_ena;
    

    reg    [ADDR_WDITH_exit_sound - 1     :0]     temp_address_exitsound;
    reg    [ADDR_WDITH_Myheaartbeat - 1   :0]     temp_address_heartbeat;
    reg    [ADDR_WDITH_monster - 1        :0]     temp_address_monster;
    reg    [ADDR_WDITH_sword_Swing - 1    :0]     temp_address_swordswing;
    reg    [ADDR_WDITH_Treasure_Chest - 1 :0]     temp_address_treasure;
    reg    [ADDR_WDITH_welcome_converted-1:0]     temp_address_welcome;


//Distributed ROM's instantiated without clock enable pin
     exit_converted exit_sound (
           .a(temp_address_exitsound),         // input wire [12 : 0] a
           //.qspo_ce(exitsound_ena),           // input wire qspo_ce
           .spo(music_data_exitsound)         // output wire [7 : 0] spo
       );

      Myheaartbeat myheartbeat (
            .a(temp_address_heartbeat),        // input wire [14 : 0] a
            //.qspo_ce(heartbeat_ena),          // input wire qspo_ce
            .spo(music_data_heartbeat)        // output wire [7 : 0] spo
      );
      
      monster_audio monsteraudio (
            .a(temp_address_monster),        // input wire [13 : 0] a
            //.qspo_ce(monster_ena),          // input wire qspo_ce
            .spo(music_data_monster)        // output wire [7 : 0] spo
      );
                
      Sword_Swing swordswing (
            .a(temp_address_swordswing),        // input wire [13 : 0] a
            //.qspo_ce(swordswing_ena),          // input wire qspo_ce
            .spo(music_data_swordswing)        // output wire [7 : 0] spo
      );

      Treasure_Chest treasurechest (
            .a(temp_address_treasure),        // input wire [13 : 0] a
           // .qspo_ce(treasure_ena),          // input wire qspo_ce
            .spo(music_data_treasure)        // output wire [7 : 0] spo
      );
 
      welcome_converted welcomesound (
            .a(temp_address_welcome),        // input wire [12 : 0] a
         //   .qspo_ce(welcome_ena),          // input wire qspo_ce
            .spo(music_data_welcome)        // output wire [7 : 0] spo
      ); 
 

 //PWM module instantiation
 audio_PWM audioPWM(.clk(clk), .reset(0), .music_data(music_data), .PWM_out(PWM_out));
  
    always @(posedge clk_8khz) begin
       
       //************** 1st audio start ***********************************************
        if(jump_ena == 6'b000001) begin
            if(temp_address_exitsound <= DEPTH_exit_sound) begin
                  temp_address_exitsound <= temp_address_exitsound + 1;
                  exitsound_ena <= 1'b1;
                  music_data    <= music_data_exitsound;
            end
             else begin
                  temp_address_exitsound <= 0;
                  exitsound_ena <= 1'b0;
             end
         end
         
        else begin
            if(exitsound_ena & (temp_address_exitsound <= DEPTH_exit_sound)) begin
                      temp_address_exitsound <= temp_address_exitsound + 1;
                      exitsound_ena <= 1'b1;
                      music_data    <= music_data_exitsound;
             end
             else begin
                      temp_address_exitsound <= 0;
                      exitsound_ena <= 1'b0;
             end
        end
        
      //************************* 1st audio end ****************************************
      
       //************** 2nd audio start ************************************************ 
        if(jump_ena == 6'b000010) begin
            if(temp_address_heartbeat <= DEPTH_Myheaartbeat) begin
                      temp_address_heartbeat <= temp_address_heartbeat + 1;
                      heartbeat_ena <= 1'b1;
                      music_data    <= music_data_heartbeat;
             end
             else begin
                      temp_address_heartbeat <= 0;
                      heartbeat_ena <= 1'b0;
             end
          end
        else begin
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
        
    //************************* 2nd audio end ****************************************    
       
    //************** 3rd audio start ************************************************        
        if(jump_ena == 6'b000100) begin
            if(temp_address_monster <= DEPTH_monster) begin
                      temp_address_monster <= temp_address_monster + 1;
                      monster_ena <= 1'b1;
                      music_data    <= music_data_monster;
             end
             else begin
                      temp_address_monster <= 0;
                      monster_ena <= 1'b0;
             end
          end
        else begin
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
     //************************* 3rd audio end **************************************** 
     
     //************** 4th audio start ************************************************                
        if(jump_ena == 6'b001000) begin
            if(temp_address_swordswing <= DEPTH_sword_Swing) begin
                      temp_address_swordswing <= temp_address_swordswing + 1;
                      swordswing_ena <= 1'b1;
                      music_data    <= music_data_swordswing;
            end
            else begin
                      temp_address_swordswing <= 0;
                      swordswing_ena <= 1'b0;
            end
         end
        else begin
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
    //************************* 4th audio end ****************************************
    
   
   //************** 5th audio start ************************************************     
       if(jump_ena == 6'b010000) begin
           if(temp_address_treasure <= DEPTH_Treasure_Chest) begin
                     temp_address_treasure <= temp_address_treasure + 1;
                     treasure_ena <= 1'b1;
                     music_data    <= music_data_treasure;
            end
            else begin
                     temp_address_treasure <= 0;
                     treasure_ena <= 1'b0;
            end
          end
        else begin
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
    //************************* 5th audio end **************************************** 
     
     //************** 6th audio start ************************************************  
       if(jump_ena == 6'b100000) begin
            if(temp_address_welcome <= DEPTH_welcome_converted) begin
                      temp_address_welcome <= temp_address_welcome + 1;
                      welcome_ena <= 1'b1;
                      music_data    <= music_data_welcome;
             end
             else begin
                      temp_address_welcome <= 0;
                      welcome_ena <= 1'b0;
             end
          end
         else begin
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
      //************************* 6th audio end ****************************************      
   end //always

    // Generate 8khz clock for reading samples
    always @(posedge clk) begin
        if (divideCounter == 3125) begin        // from 65Mhz to 8Khz
             clk_8khz <= 1'b1;
             divideCounter <= 1'b0;
         end
         else begin
            divideCounter <= divideCounter + 1'b1;
             clk_8khz <= 1'b0; 
         end
     end
            
        
    endmodule
