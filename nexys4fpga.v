//nexys4fpga.v -  design for ECE 540 Final Project Dungeon Crawler
//
// Copyright John Lynch and Roy Kravitz, 2014-2015, 2016
// 
// Created By:		Roy Kravitz, John Lynch modified for Randon Stasney, Dakota Ward, Naveen Yalla, Kajal Zatale
// Last Modified:	Randon Stasney 6/5/2016
//
// Revision History:
// -----------------
// Dec-2006		JL		Created this module for ECE 540
// Dec-2013		RK		Cleaned up the formatting.  No functional changes
// Aug-2014		RK		Parameterized module.  Modified for Vivado and Nexys4
// Apr-2016		RS		Modified for project 1 to include compass and chase
// May-2016		RS		Modified for project 2 to show autonomous bot on vga
// Jun-2016		RS		Modified for Final Project "Dungeon Crawler"
//
// Description:
// ------------
// This module is now the  ECE 540 Final Project Dungeon Crawler.   
// This project is autonomously controlling a monster bot represented as an icon displayed on
// the screen.  There is also a picoblaze for a Hero bot.  This top module holds and allows 
// the transfer of information to make this all possible.  The proj2demo holds the self driving 
// algorithm written in assembly. There is also a conversion of this to drive the hero bot
// via the joystick or if not present and slide switch zero is activated then the hero can be 
// driven by the pushbuttons.  This then controls the bot and the bots location and orientation 
// are then transmited to the screen to be displayed.  There is then a gamelogic to control the 
// interaction of the icons on the game and sound has been added via the mono output on the board
// 
///////////////////////////////////////////////////////////////////////////
module Nexys4fpga (
input 	clk,             	// 100MHz clock from on-board oscillator
// buttons used as alternate if no joystick by using slide switch zero
input 	btnL, btnR,			// pushbutton inputs -left 
//(db_btns[4])and right (db_btns[2])
input 	btnU, btnD,			// pushbutton inputs -up (db_btns[3]) 
// and down (db_btns[1])
input 	btnC,				// used to control sword swing 
// db_btns[5]
input 	btnCpuReset,		// red pushbutton input -> db_btns[0]
// slide swich zero used to switch driving of hero to onboard push buttons
input	[15:0]sw,			// switch inputs
input	MISO,  				// SPI interface for joystick
output	SS, MOSI, SCLK,  	// SPI interface for joystick
output	[15:0]led,  // LED outputs used from proj2demo and from there as breadcrumbs to aid in debug
// functionality for 7-seg was added to this module to aid in debug of proj2demo

output 	[6:0]seg,			// Seven segment display cathode pins
output  dp,					// decimal point
output	[7:0]an,// Seven segment display anode pins
//output	[7:0]JA,// JA Header
output 	vga_vsync, vga_hsync, 	// the pulse created by the dtg so the monitor can detect and 
								// display the proper screen resolution
output  [3:0] vga_red,vga_green,vga_blue, // output of color info to go to the vga pins on the board
output 	AUD_PWM, AUD_SD		// audio pulse width modulation control of the mono output jack on the board

);
 // parameter
 parameter SIMULATE = 0;
 // internal variables
wire [15:0]db_sw;		// debounced switches
wire [5:0]db_btns;		// debounced buttons
wire [3:0]db_btns_joy;	// jostick control to send to picoblaze
wire [7:0]tc_info;		// treasure chest open or closed flag
wire [1:0]game_over;	// show game over and determine final screen
wire sword_swing;		// sword button
wire monster_sound;		// transmit monster death growl
wire tc_sound;			// transmit treasuer opening sound
wire reset_mon;			// "kill" the monster by reseting him
wire [7:0] score;		// score in "gold"
wire [7:0] health;		// health is lost via time or monster attack

wire score_display;		// display bars gold score
wire [1:0] health_display;	// display bar current health
wire heart;				// heart sound for last 15 health
wire sysclk;			// 65MHz clock from clock generator 
wire sysreset;			// system reset signal –asserted
						// high to force reset
wire [4:0]dig7, dig6,dig5, dig4, dig3, dig2, dig1, dig0;// display digits
wire [7:0]decpts;		// decimal points
wire [7:0]segs_int;		// segment outputs (internal)
wire [63:0]digits_out;	// digits_out (only for simulation)

// PicoBlaze interface to connect the interface for both bots hero is normal other is monster control
wire [11:0]address, address_mon;
wire [17:0]instruction, instruction_mon;
wire bram_enable, bram_enable_mon;
wire [7:0]port_id, port_id_mon;
wire [7:0]out_port, out_port_mon;
wire [7:0]in_port, in_port_mon;
wire write_strobe, write_strobe_mon;
wire k_write_strobe, k_write_strobe_mon;
wire read_strobe, read_strobe_mon;
wire interrupt, interrupt_mon;
wire interrupt_ack, interrupt_ack_mon;
wire kcpsm6_sleep, kcpsm6_sleep_mon; 
wire kcpsm6_reset, kcpsm6_reset_mon;
wire cpu_reset, cpu_reset_mon;
wire rdl, rdl_mon;
wire int_request, int_request_mon;

// PicoBlaze I/O registers
wire [7:0] sw_high, sw_low, res1, res2;  
wire [7:0] leds_high, leds_low;			
wire [4:0] digit0_int, digit1_int, digit2_int, digit3_int, digit4_int, digit5_int, digit6_int, digit7_int;

// bot i/o registers
wire [7:0] MotCtl_in, MotCtl_in_mon;   	// motor control in
wire [7:0] LocX_reg, RMDist_reg, LMDist_reg, LocY_reg, BotInfo_reg, Sensors_reg;  // outputs from bot
wire [7:0] LocX_reg_mon, LocY_reg_mon, BotInfo_reg_mon, Sensors_reg_mon; // outputs from monster bot
wire [10:0] vid_row, vid_col, vid_row6; // pixel display information
wire [11:0] Locy6, Locy6_mon; // scaled by now 12 to get 3072 pixel y direction
wire [1:0] vid_pixel_out, vid_pixel_out_mon;	// pixel (location) value
wire [1:0] icon_pixel;		// icon pixel information
wire [12:0] death_pixel, mil_pixel, rock_pixel, mon_pixel, grass_pixel,	end_pixel, TC_pixel, exit_pixel;// from icon 
wire  upd_sysregs, upd_sysregs_mon;			// interupt from bit to proj2demo
reg [6:0] LED;



//// ************************figure what we're doing from demo*********
assign Locy6_mon = LocY_reg_mon*12; // we multiply locy from bot to scale 256 locations to 3072
assign Locy6 = LocY_reg*12;      // we multiply locy from bot to scale 256 locations to 3072
assign vid_row6 = vid_row/12;	// we divide by 12 so we read from same location 12 times in a row
								// to scale the screen to the map
// top 2 represent score in hex
assign dig7 = {1'b0,score[7:4]};
assign dig6 = {1'b0,score[3:0]};
// next two represent current health
assign dig5 = {1'b0,health[7:4]};
assign dig4 = {1'b0,health[3:0]};  	
// orientation from bot info
assign dig3 = {1'b0,LocX_reg[7:4]};			// upper half of x loc
assign dig2 = {1'b0,LocX_reg[3:0]};			// lower half of x loc
assign dig1 = {1'b0,LocY_reg[7:4]};			// upper half of y loc
assign dig0 = {1'b0,LocY_reg[3:0]};			// lower half of y loc


// global assigns
//assign sysclk = clk;
assign sysreset = ~db_btns[0]; 		// btnCpuReset is asserted low so invert it
assign  sw_high = db_sw[15:8]; 		// connect switches to output
assign  sw_low = db_sw[7:0];		// connect switches to output
assign  led = {leds_low, 1'b0,LED}; // low was the sensor info and the pattern was to see if they showed
assign dp = segs_int[7];			// dp used as crumbs in debug and show interrupt
assign seg = segs_int[6:0];			



// SPI signals for joystrick interface
wire SS, SCLK, MOSI;
						
// Holds data to be sent to PmodJSTK
wire [7:0] sndData;

// Signal to send/receive data to/from PmodJSTK
wire sndRec, forward, back, left, right;

// Data read from PmodJSTK 5 bytes of data from joystick
wire [39:0] jstkData;

// Signal carrying output data that user selected
wire [9:0] jstY, jstX;



// Use state of switch 0 to select output of X position or Y position data to SSD
assign jstY = {jstkData[9:8], jstkData[23:16]};  // grab info from joystick about position
assign jstX = {jstkData[25:24], jstkData[39:32]};
assign forward = (jstY >= 700) ? 1'b1 : 1'b0;  // center value 500 so trigger read of greater than or less than
assign back = (jstY <= 300) ? 1'b1 : 1'b0;
assign left = (jstX <= 300) ? 1'b1 : 1'b0;
assign right = (jstX >= 700) ? 1'b1 : 1'b0;	
assign db_btns_joy = {left, forward, right, back};  // put signals into signal that is same as buttons for picoblaze
assign sword_swing = (jstkData[1] | db_btns [5]);  	// drive sowrd via joystick or pushbutton
			
// send data fron switches back to light leds on joystick			
assign sndData = {8'b100000, {db_sw[1], db_sw[2]}};

// Assign PmodJSTK button status to LED[2:0]
always @(sndRec or sysreset or jstkData) begin
	if(sysreset == 1'b1) begin
		LED <= 7'b0000000;
	end
	else begin // show joystick position on led also was for debug 
		LED <= {forward, back, left, right, jstkData[1], jstkData[2], jstkData[0]};
	end
end


  clk_wiz_0 CLKGEN
   (
   // Clock in ports
    .clk_in1(clk),      // input clk_in1
    // Clock out ports
    .clk_out1(sysclk),     // output clk_out 65MHz
    .clk_out2(joyclk),     // not used
    // Status and control signals
    .reset(1'b0), // input reset
    .locked(locked));      // output locked


    
// instantiate the debounce module
// RESET_POLARITLY_LOW is 1 because btnCpuReset is asserted
// high and the debounced version of btnCpuReset becomees
// sysreset
debounce
#(
.RESET_POLARITY_LOW(1),
.SIMULATE(SIMULATE)
)  DB
(
.clk(sysclk),
.pbtn_in({btnC,btnL,btnU,btnR,btnD,btnCpuReset}),  // concatonate the signals to send to the debouncer
.switch_in(sw),
.pbtn_db(db_btns),	// the output of the debounced buttons
.swtch_db(db_sw)	// the debounced switch output
);

// instantiate the 7-segment, 8-digit display
sevensegment
#(
.RESET_POLARITY_LOW(0),
.SIMULATE(SIMULATE)
) SSB
(
// inputs for control signals
// tie the display to the wires driving them
.d0(dig0),
.d1(dig1),
.d2(dig2),
.d3(dig3),
.d4(dig4),
.d5(dig5),
.d6(dig6),
.d7(dig7),
.dp(decpts),
// outputs to seven segment display
.seg(segs_int),
.an(an),
// clock and reset signals (66 MHz clock, active high reset)
.clk(sysclk),
.reset(sysreset),
// ouput for simulation only
.digits_out(digits_out)
);

// instantiate the PicoBlaze and instruction ROM
assign kcpsm6_sleep = 1'b0;
assign kcpsm6_reset = sysreset | rdl;
assign kcpsm6_reset_mon = sysreset | reset_mon;
kcpsm6 #(
.interrupt_vector(12'h3FF),  		// location of interupt handler
.scratch_pad_memory_size(64),		// build parameter
.hwbuild(8'h00))					// can pass info on hardware build
APPCPUMAIN(
.address (address),					
.instruction (instruction),
.bram_enable (bram_enable),
.port_id (port_id),
.write_strobe (write_strobe),		// write strobe to write to port
.k_write_strobe (),		
.out_port (out_port),				
.read_strobe (read_strobe),
.in_port (in_port),
.interrupt (interrupt),				// signal generated from bot.v
.interrupt_ack (interrupt_ack),		// acknowledgement from proj2demo that it recieved
.reset (kcpsm6_reset),			
.sleep(kcpsm6_sleep),
.clk (sysclk));

 proj2demo #(
 .C_JTAG_LOADER_ENABLE(0),
 .C_FAMILY("7S"),   		//Family 'S6' or 'V6' or '7S'
 .C_RAM_SIZE_KWORDS(2)     	//Program size '1', '2' or '4'
 )    						//Include JTAG Loader when set to 1'b1 
 PGM2DEMO (    
.rdl (rdl),					// rdl is for jtag interface loading
.enable (bram_enable),		// enable the 
.address (address),
.instruction (instruction),
.clk (sysclk));
/////////*************************
//MONSTER
//////////////*******************
kcpsm6 #(
.interrupt_vector(12'h3FF),  		// location of interupt handler
.scratch_pad_memory_size(64),		// build parameter
.hwbuild(8'h00))					// can pass info on hardware build
MONSTER(
.address (address_mon),					
.instruction (instruction_mon),
.bram_enable (bram_enable_mon),
.port_id (port_id_mon),
.write_strobe (write_strobe_mon),		// write strobe to write to port
.k_write_strobe (),		
.out_port (out_port_mon),				
.read_strobe (read_strobe_mon),
.in_port (in_port_mon),
.interrupt (interrupt_mon),				// signal generated from bot.v
.interrupt_ack (interrupt_ack_mon),		// acknowledgement from proj2demo that it recieved
.reset (kcpsm6_reset_mon),			
.sleep(kcpsm6_sleep),
.clk (sysclk));

 proj2demomon #(
 .C_JTAG_LOADER_ENABLE(0),
 .C_FAMILY("7S"),   		//Family 'S6' or 'V6' or '7S'
 .C_RAM_SIZE_KWORDS(2)     	//Program size '1', '2' or '4'
 )    						//Include JTAG Loader when set to 1'b1 
 PGM2DEMOMON (    
.rdl (rdl_mon),					// rdl is for jtag interface loading
.enable (bram_enable_mon),		// enable the 
.address (address_mon),
.instruction (instruction_mon),
.clk (sysclk));

// instantiate the PicoBlaze I/O register interface
nexys4_bot_if #(
.RESET_POLARITY_LOW(1))			
N4IF(
.write_strobe(write_strobe),	// write strobe to write ot ports
.read_strobe(read_strobe),		// read strobe not used since no fifo
.port_id(port_id),				// the prot id to be read or written
.io_data_in(out_port),    		// data from Picoblaze to the I/O register
.io_data_out(in_port),    		// data from I/O register to Picoblaze   
.interrupt_ack(interrupt_ack),	// signal to accept interrupt
.interrupt(interrupt),			// the interrupt from the bot
.write_strobe_mon(write_strobe_mon),	// write strobe to write ot ports
.read_strobe_mon(read_strobe_mon),		// read strobe not used since no fifo
.port_id_mon(port_id_mon),				// the prot id to be read or written
.io_data_in_mon(out_port_mon),    		// data from Picoblaze to the I/O register
.io_data_out_mon(in_port_mon),    		// data from I/O register to Picoblaze   
.interrupt_ack_mon(interrupt_ack_mon),	// signal to accept interrupt
.interrupt_mon(interrupt_mon),			// the interrupt from the bot
.sysclk(sysclk),				// 65MHZ clock
.sysreset(sysreset),			// reset

// ports fpga fabric
	// (i) pushbuttons inputs for buttons
.PORT_00({4'b0000, db_btns_joy}),				//for joystick
.PORT_01(sw_low),					// (i) slide switches
.PORT_10({4'b0000, db_btns[4:1]}),	// (i) pushbutton inputs alternate port address to drive with slide switch zero
.PORT_11(sw_high),					// (i) slide switches 15:8 (high byte of switches


//  Rojobot interface registers

.PORT_09(MotCtl_in),	// (o) herobot motor control output from system

// what proj2demo uses to calculate how to drive the bot
/************************************************************/
.PORT_0A(LocX_reg), 	//(i) X coordinate of rojobot location
.PORT_0B(LocY_reg), 	//(i))Y coordinate of rojobot location
.PORT_0C(BotInfo_reg), 	//(i) Rojobot info register
.PORT_0D(Sensors_reg),	//(i) Sensor register
/************************************************************/
// MONSTER
.PORT_19(MotCtl_in_mon),	// (o) monsterbot motor control output from system

// what proj2demo uses to calculate how to drive the bot
/************************************************************/
.PORT_1A(LocX_reg_mon), 	//(i) X coordinate of monsterbot location
.PORT_1B(LocY_reg_mon), 	//(i))Y coordinate of monsterbot location
.PORT_1C(BotInfo_reg_mon), 	//(i) monsterbot info register
.PORT_1D(Sensors_reg_mon),	//(i) Sensor register
/************************************************************/
// unused for this current application
.PORT_02(leds_low),		// LEDS [7:0]
.PORT_03(digit3_int),	// (o) digit 3 port address
.PORT_04(digit2_int),	// (o) digit 2 port address
.PORT_05(digit1_int),	// (o) digit 1 port address
.PORT_06(digit0_int),	// (o) digit 0 port address
.PORT_07(decpts[3:0]),	// (o) decimal points 3:0 port address
.PORT_08(res1),			// (o) *RESERVED* port address
.PORT_12(leds_high),	// (o) LEDs 15:8 (high byte of switches)
.PORT_13(digit7_int),	// (o) digit 7 port address
.PORT_14(digit6_int),	// (o) digit 6 port address
.PORT_15(digit5_int),	// (o) digit 5 port address
.PORT_16(digit4_int),	// (o) digit 4 port address
.PORT_17(decpts[7:4]),	// (o) decimal points 7:4 port address
.PORT_18(res2),			// (o) *RESERVED* alternate port address

// used as interrupt to update loc and senor regs
.interrupt_request(upd_sysregs),			// from hero bot sync
.interrupt_request_mon(upd_sysregs_mon) 	// from monster bot sync
);

// instantiate hero bot
bot31(
	// system interface registers
.MotCtl_in(MotCtl_in),				// Motor control input	
.LocX_reg(LocX_reg),				// X-coordinate of herobot's location		
.LocY_reg(LocY_reg),				// Y-coordinate of herobot's location
.Sensors_reg(Sensors_reg),			// Sensor readings
.BotInfo_reg(BotInfo_reg),			// Information about herobot's activity
.LMDist_reg(LMDist_reg),			// left motor distance register
.RMDist_reg(RMDist_reg),			// right motor distance register
						
	// interface to the video logic scaled for read same value 16 times
.vid_row(vid_row6),						// video logic row address divided by 12
.vid_col({4'b0000,vid_col[10:4]}),		// video logic column address divided by 16

.vid_pixel_out(vid_pixel_out),			// pixel (location) value

	// interface to the system
.clk(sysclk),						// 65MHZ clock
.reset(sysreset),					// system reset
.upd_sysregs(upd_sysregs),			// flag from PicoBlaze to indicate that the system registers 
									// (LocX, LocY, Sensors, BotInfo)have been updated
.Bot_Config_reg(8'b0001_0011)		// enable speed control and set tolerance
);
bot(
	// system interface registers
.MotCtl_in(MotCtl_in_mon),				// Motor control input	
.LocX_reg(LocX_reg_mon),				// X-coordinate of rojobot's location		
.LocY_reg(LocY_reg_mon),				// Y-coordinate of rojobot's location
.Sensors_reg(Sensors_reg_mon),			// Sensor readings
.BotInfo_reg(BotInfo_reg_mon),			// Information about rojobot's activity
.LMDist_reg(LMDist_reg),			// left motor distance register
.RMDist_reg(RMDist_reg),			// right motor distance register
						
	// interface to the video logic scaled for read same value 16 times
.vid_row(vid_row6),						// video logic row address divided by 12
.vid_col({4'b0000,vid_col[10:4]}),		// video logic column address divided by 16

.vid_pixel_out(vid_pixel_out_mon),		// pixel (location) value -- not used based on heros 

	// interface to the system
.clk(sysclk),							// 65MHZ clock
.reset(kcpsm6_reset_mon),				// system reset
.upd_sysregs(upd_sysregs_mon)			// flag from PicoBlaze to indicate that the system registers 
										// (LocX, LocY, Sensors, BotInfo)have been updated

);
 // timing to control the vga
dtg DTG(
		.clock(sysclk),				// 65MHZ clock
		.rst(sysreset),				// system reset
        .horiz_sync(vga_hsync),		// pulse for monitor to detect resolution
        .vert_sync(vga_vsync),		// pulse for monitor to detect resolution
        .video_on(video_on),    	// determines whether to show pixel or not during balnking period    
        .pixel_row(vid_row),		// the current location of the pixel stream row
        .pixel_column(vid_col)		// the current location of the pixel stream column
	);
	    
 // colorizer to set 12 bit color output to vga
colorizer COLOR(
     .video_on(video_on),			// determines whether to show pixel or not during balnking period 		
     .clk(sysclk),					// 66MHZ clock
     .world_pixel(vid_pixel_out),	// color data from world map of that pixel location
     .icon_pixel(icon_pixel),		// color data from icon of that pixel location	
	 // colors are 4 bits wide weighted
	 .death_pixel(death_pixel),		// background now dirt color
	 .mil_pixel(mil_pixel),			// hero icon pixel info
	 .rock_pixel(rock_pixel),		// rock wall obstruction texture
	 .grass_pixel(grass_pixel),		// grass coloring texture
	 .mon_pixel(mon_pixel),			// monster pixel info
	 .end_pixel(end_pixel),			// endscreen pixel info
	 .exit_pixel(exit_pixel),		// exit portal icon
	 .TC_pixel(TC_pixel),			// treasure chest icon
	 .health_disp_ip(health_display),   // to display health display meter.
	 .score_disp_ip(score_display),		// to display score bar on screen
     .vga_red(vga_red),				// how much red to output for that pixel
     .vga_green(vga_green),			// how much green to output for that pixel
     .vga_blue(vga_blue) 			// how much blue to output for that pixel
);
 // icon to detect icon location and overlap on worldmap to show proper image
icon ICON(
        .clk(sysclk),							// 65MHZ clock
        .pixel_row(vid_row),					// the current location of the pixel stream row
        .pixel_column(vid_col),					// the current location of the pixel stream column
        .LocY(Locy6),							// loc Y from bot scaled * 12 to get 3072
        .LocX({LocX_reg, 4'b0000}),				// loc x from bot scaled * 16 to get 4096
        .LocY_mon(Locy6_mon),					// loc Y from bot scaled * 12 to get 3072
        .LocX_mon({LocX_reg_mon, 4'b0000}),		// loc x from bot scaled * 16 to get 4096
		.game_over(game_over),					// game over flag and which screen
		.tc_info(tc_info),						// treasure looted and open or not 1 hot flags
        .Botinfo(BotInfo_reg),					// bot info orientation for hero icon selection
		.death_pixel(death_pixel),				// background dirt 
		.mil_pixel(mil_pixel),					// hero icon 
		.grass_pixel(grass_pixel),				// grass texture
		.end_pixel(end_pixel),					// exit portal icon
		.TC_pixel(TC_pixel),					// treasure chest icon
		.mon_pixel(mon_pixel),					// monster icon
		.exit_pixel(exit_pixel),				// portal icon
		.rock_pixel(rock_pixel),				// wall texture
        .icon_pixel(icon_pixel)					// unused as we display all colors now
       
 );
gameLogic gmL(
			.clk(sysclk),						// sys 65 MHz clock
			.reset(sysreset),					
			.LocY(LocY_reg),					// loc Y from hero for collision logic
			.LocX(LocX_reg),					// loc x from hero for collision logic
			.LocY_mon(LocY_reg_mon),			// loc Y from monster for collision logic
			.LocX_mon(LocX_reg_mon),			// loc x from monster for collision logic
			.sword_swing(sword_swing),			// sword swing for attack monster collision
			.monster_sound(monster_sound),		// output growl on monster death
			.tc_sound(tc_sound),				// output treasure chest open sound when collision with chest
			.reset_mon(reset_mon),				// the "kill" reset the monster starts over on path is killable again
			.score(score),						// score from treasure and monster
			.heart(heart),						// low health warning sound
			.health(health),					// health decrements over time and from monster
			.tc_info(tc_info),					// whether treausre has been looted or not
			.game_over(game_over)				// signal game end by display game over screen
);
PmodJSTK joy(
			.CLK(sysclk),						// sys 65 MHz clock
			.RST(sysreset),
			.sndRec(sndRec),					// the clock for the SPI interface at 5Hz
			.DIN(sndData),						// 5 bytes to be written back to joystick via SPI protocol
			.MISO(MISO),						// Interface to joystick via SPI protocol
			.SS(SS),
			.SCLK(SCLK),
			.MOSI(MOSI),
			.DOUT(jstkData)						// 5 bytes reeived from joystick (3 buttons and x,y stick location)
    );
ClkDiv_5Hz genSndRec(
					.CLK(sysclk),				// 65 MHz clock
					.RST(sysreset),				// reset
					.CLKOUT(sndRec)				// 5Hz clock for driving SPI
			);
		
	assign AUD_SD=1;  // tie high for PWM audio output
	
audio audio(
	.clk(sysclk), 								// now 65MHz clock
	.reset(sysreset),
	.jump_ena({1'b0,tc_sound ,(jstkData[1] | db_btns [5]),monster_sound ,heart,1'b0}), // sound trigger inputs
	.PWM_out(AUD_PWM));							// PWM output to board mono jack

// drawn display on screen representing health and score
healthmodule meter(    
    .reset(sysreset),
    .clk(sysclk),
    .health(health),							// hero remaining health
    .score(score),								// hero score
    .pixel_row(vid_row),						// pixel and column placement for drawing on screen
    .pixel_column(vid_col),
    
    .score_display(score_display),				// output of drawings to colorizer
    .health_display(health_display)

    );	
	
endmodule