`timescale 1ns / 1ps


module audio(
    input clk, // 25 MHz clock
    input jumpSound,
//    output [11:0] music_out,
    output PWM_out
    );
    
    reg clk_8khz=0;
    
    // Generate 8khz clock for reading samples
     reg[11:0] divideCounter=0;
    
    always @(posedge clk) begin
        if (divideCounter == 3125) begin   //9,999,999
             clk_8khz <= 1'b1;
             divideCounter <= 1'b0;
         end
         else begin
            divideCounter <= divideCounter + 1'b1;
             clk_8khz <= 1'b0; 
         end
     end
    
    parameter integer	DEPTH		= 105410;  //edited
    
    wire[7:0] music_data;
    
   // assign music_out = temp_address;    //edited
    //parameter integer	DEPTH		= 189035;  //edited
    
    audio_PWM audioPWM(.clk(clk),.reset(0),.music_data(music_data),.PWM_out(PWM_out));
    
 
    /////////////////////////////////////////////////////////////////////////////
    //////////// Jumping Sound //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////
        wire[16:0] jumpAddress;
//        wire[7:0] jumpAudio;
        
        blk_mem_gen_0 heartbeat (
          .clka(clk),    // input wire clka
          .addra(jumpAddress),  // input wire [11 : 0] addra
          .douta(music_data)  // output wire [3 : 0] douta
        );
        
       reg  [16:0]  temp_address;
       assign jumpAddress = temp_address;
     
       
       
       
       always @(posedge clk_8khz) begin
           if(temp_address == DEPTH) begin
                    temp_address <= 11'd0;
           end
           else
             temp_address <= temp_address + 11'b1;
       end
            
    endmodule
    
    
    
    /*
    wire[11:0] jumpAddress;
    wire[3:0] jumpAudio;
    soundTimer jumpTimer(clk,clk_8khz,jumpSound,jumpAddress);
    jump_sound jump_sound(.a(jumpAddress),.spo(jumpAudio));
    wire[3:0] correctedJumpAudio = (jumpAudio[3])? + (128-jumpAudio[2:0]):(128+jumpAudio[2:0]);
    
    // Add outputs together, return value
    
    wire[4:0] audioSum = correctedJumpAudio+correctedJumpAudio;
    assign music_data = {audioSum,3'b0};
    
endmodule

module soundTimer   // Timing for an 8khz sound
        #(parameter LENGTH = 3680)  // Length in number of samples
   (input clk, //25 MHz Clk
    input sampleClock, // Clock for sampling
    input enable,
    output reg [11:0] sampleNumber=0);
   
    
    always @(posedge sampleClock) begin
        if(sampleNumber > 0 || enable) begin
            if (sampleNumber == LENGTH-1) begin
                sampleNumber <= 0;
            end else begin
                sampleNumber <= sampleNumber + 1;
            end
        end
    end
endmodule
*/