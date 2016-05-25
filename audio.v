`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2015 06:54:29 PM
// Design Name: 
// Module Name: audio
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module audio(
    input clk, // 25 MHz clock
    input jumpSound,
    output PWM_out
    );
    wire[7:0] music_data;
    
    // Generate 8khz clock for reading samples
    reg[11:0] divideCounter=0;
    reg clk_8khz=0;
    always @(posedge clk) begin
        if (divideCounter < 1563) begin
            divideCounter <= divideCounter+1;
        end else begin
            divideCounter <= 0;
            clk_8khz <= !clk_8khz;
        end
    end
    
    audio_PWM audioPWM(.clk(clk),.reset(0),.music_data(music_data),.PWM_out(PWM_out));
    
    /////////////////////////////////////////////////////////////////////////////
    //////////// Crashing Sound /////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////
 /*   
    wire[11:0] crashAddress;
    wire[3:0] crashAudio;
    soundTimer crashTimer(clk,clk_8khz,crashSound,crashAddress);
    crash_sound crash_sound(.a(crashAddress),.spo(crashAudio));
    wire[3:0] correctedCrashAudio = (crashAudio[3])? + (128-crashAudio[2:0]):(128+crashAudio[2:0]);
*/    
    /////////////////////////////////////////////////////////////////////////////
    //////////// Jumping Sound //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////
    
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