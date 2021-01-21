`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] fish_clock;
reg  [31:0] fish_clock1=32'b11000000000000000000000000000000;
wire [9:0]  pos;
wire [9:0]  pos1;
wire [9:0]  pos2;
wire [9:0]  pos3;
wire        fish_region;
wire        fish_region1;
wire        fish_region2;
wire        fish_region3;
// declare SRAM control signals
wire [17:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire        sram_we, sram_en;
 
// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel

// Application-specific VGA signals
reg  [17:0] pixel_addr;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images

localparam FISH_VPOS3 = 120;
localparam FISH_VPOS2 = 100;
localparam FISH_VPOS1 =  20;
localparam FISH_VPOS   = 64; // Vertical location of the fish in the sea image.
localparam FISH_W      = 64; // Width of the fish.
localparam FISH_H      = 32; // Height of the fish.
localparam  FISH_W1  = 64;
localparam  FISH_H1  = 72;
reg [17:0] fish_addr[0:7];   // Address array for up to 8 fish images.
reg [17:0] fish_addr1[0:7];
reg  [17:0]fish_addr2[0:3];
reg  [17:0]fish_addr_player[0:7];
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish_addr[0] <=  18'd0;         /* Addr for fish image #1 */
  fish_addr[1] <=  FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr[2] <= FISH_W*FISH_H*2;
  fish_addr[3] <= FISH_W*FISH_H*3;
  fish_addr[4] <= FISH_W*FISH_H*4;
  fish_addr[5] <= FISH_W*FISH_H*5;
  fish_addr[6] <= FISH_W*FISH_H*6;
  fish_addr[7] <= FISH_W*FISH_H*7;
end

initial begin
  fish_addr1[0] <=  18'd0;         /* Addr for fish image #1 */
  fish_addr1[1] <=  FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr1[2] <= FISH_W*FISH_H*2;
  fish_addr1[3] <= FISH_W*FISH_H*3;
  fish_addr1[4] <= FISH_W*FISH_H*4;
  fish_addr1[5] <= FISH_W*FISH_H*5;
  fish_addr1[6] <= FISH_W*FISH_H*6;
  fish_addr1[7] <= FISH_W*FISH_H*7;
end

initial begin
  fish_addr2[0] <=  18'd0;         /* Addr for fish image #1 */
  fish_addr2[1] <=  FISH_W1*FISH_H1; /* Addr for fish image #2 */
  fish_addr2[2] <= FISH_W1*FISH_H1*2;
  fish_addr2[3] <= FISH_W1*FISH_H1*3;
end

initial begin
  fish_addr_player[0] <=  18'd0;         /* Addr for fish image #1 */
  fish_addr_player[1] <=  FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr_player[2] <= FISH_W*FISH_H*2;
  fish_addr_player[3] <= FISH_W*FISH_H*3;
  fish_addr_player[4] <= FISH_W*FISH_H*4;
  fish_addr_player[5] <= FISH_W*FISH_H*5;
  fish_addr_player[6] <= FISH_W*FISH_H*6;
  fish_addr_player[7] <= FISH_W*FISH_H*7;
end

wire  btn_level;
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level)
);

reg  prev_btn_level;

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end
wire btn_pressed ;
assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

wire  btn_level1;

wire btn_pressed1;
debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level1)
);

reg  prev_btn_level1;

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level1 <= 1;
  else
    prev_btn_level1 <= btn_level1;
end

assign btn_pressed1 = (btn_level1 == 1 && prev_btn_level1 == 0);



// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);


// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
wire [17:0] sram_addr_fish_player;
wire [17:0] data_out_fish_player;
reg  [17:0] pixel_addr_fish_player;
assign sram_addr_fish_player = pixel_addr_fish_player;
sram_fish4 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))
  ram_player (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish_player), .data_i(data_in), .data_o(data_out_fish_player));
wire [17:0] sram_addr_fish3;
wire [11:0] data_out_fish3;
reg [17:0] pixel_addr_fish3;
assign sram_addr_fish3 = pixel_addr_fish3;
sram_fish3 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W1*FISH_H1*4))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish3), .data_i(data_in), .data_o(data_out_fish3));
wire [17:0] sram_addr_fish1;
wire [17:0] data_out_fish1;
reg  [17:0] pixel_addr_fish1;
assign sram_addr_fish1 = pixel_addr_fish1;
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
sram_fish1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish1), .data_i(data_in), .data_o(data_out_fish1));
 wire [17:0] data_out_fish2;
 wire [17:0] sram_addr_fish2;
 reg  [17:0] pixel_addr_fish2;
assign sram_addr_fish2 = pixel_addr_fish2;
 sram_fish1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish2), .data_i(data_in), .data_o(data_out_fish2));
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
reg flag1=1'b0;
always@(posedge clk)begin
    if(~reset_n)begin
        flag1<=1'b0;
    end
    if(btn_pressed1)begin
        flag1 <= ~flag1;
    end
end
assign pos = (flag1)? fish_clock[31:20] :fish_clock[29:18] ; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos1 = (flag1)? fish_clock1[29:18] : fish_clock1[31:20];

assign pos2 = (flag1)?fish_clock[29:18] :fish_clock[31:20];

assign pos3 = (flag1)?fish_clock1[31:20]:fish_clock1[29:18];

always@(posedge clk)begin
    if(~reset_n || fish_clock1[31:21] <=0 )begin
        fish_clock1 <= 32'b11000000000000000000000000000000;
    end else begin
        fish_clock1 <= fish_clock1 -1;
    end
end

always @(posedge clk) begin
  if (~reset_n || fish_clock[31:21] > VBUF_W + FISH_W)begin
    fish_clock <= 0;
 end else begin
    fish_clock <= fish_clock + 1;
    end
end
// End of the animation clock code.
// ------------------------------------------------------------------------
assign usr_led = {btn_pressed1,btn_pressed};
// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region =
           pixel_y >= (FISH_VPOS<<1) && pixel_y < (FISH_VPOS+FISH_H)<<1 &&
           (pixel_x + 127) >= pos && pixel_x < pos + 1;
assign fish_region1 =
           pixel_y >= (FISH_VPOS1<<1) && pixel_y < (FISH_VPOS1+FISH_H)<<1 &&
           (pixel_x + 127) >= pos1 && pixel_x < pos1 + 1;
 assign fish_region2 =
           pixel_y >= (FISH_VPOS2<<1) && pixel_y < (FISH_VPOS2+FISH_H1)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;
 assign fish_region3 =
           pixel_y >= (FISH_VPOS3<<1) && pixel_y < (FISH_VPOS3+FISH_H)<<1 &&
           (pixel_x + 127) >= pos3 && pixel_x < pos3 + 1;
           
always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr_fish_player <= 0;
  if (fish_region3)
    pixel_addr_fish_player <= fish_addr_player[fish_clock1[25:23]] +((pixel_y>>1)-FISH_VPOS3+1)*FISH_W- ((pixel_x +(FISH_W*2-1)-pos3)>>1);
end       
              
always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr_fish3 <= 0;
  if (fish_region2)
    pixel_addr_fish3 <= fish_addr2[fish_clock[24:23]] +((pixel_y>>1)-FISH_VPOS2+1)*FISH_W1 - ((pixel_x +(FISH_W1*2-1)-pos2)>>1);
end

always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr_fish1 <= 0;
  if (fish_region)
    pixel_addr_fish1 <= fish_addr[fish_clock[25:23]] +((pixel_y>>1)-FISH_VPOS)*FISH_W +((pixel_x +(FISH_W*2-1)-pos)>>1);
end

always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr_fish2 <= 0;
  if (fish_region1)
    pixel_addr_fish2 <= fish_addr1[fish_clock1[25:23]] + ((pixel_y>>1)-FISH_VPOS1+1)*FISH_W - ((pixel_x +(FISH_W*2-1)-pos1)>>1);
end

always@(posedge clk)begin
    if(~reset_n)begin
        pixel_addr <= 0;
    end else begin
     // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    end
end

// End of the AGU code.
// ------------------------------------------------------------------------
reg flag=1'b0;
always@(posedge clk)begin
    if(~reset_n)begin
        flag<=1'b0;
    end
    if(btn_pressed)begin
        flag <= ~flag;
    end
end

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) begin
        rgb_reg <= rgb_next;
  end
end



always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(fish_region)begin
        if(data_out_fish1!=12'h0f0)begin
            rgb_next = data_out_fish1; // RGB value at (pixel_x, pixel_y)
        end else begin
           if(flag)begin
                rgb_next = ~data_out;
            end else begin
                 rgb_next = data_out;
            end
        end
     end else if(fish_region1)begin
        if(data_out_fish2!=12'h0f0)begin
            rgb_next = data_out_fish2; // RGB value at (pixel_x, pixel_y)
        end else begin
           if(flag)begin
                rgb_next = ~data_out;
            end else begin
                 rgb_next = data_out;
            end
        end
        end else if(fish_region2 || fish_region3)begin
            if(fish_region3 && !fish_region2)begin
                if(data_out_fish_player!=12'h0f0)begin
                    rgb_next = data_out_fish_player;
                end else begin
                    if(flag)begin
                        rgb_next = ~data_out;
                    end else begin
                     rgb_next = data_out;
                    end                   
                end
            end else if(fish_region2 && !fish_region3)begin
                 if(data_out_fish3!=12'h0f0)begin
                    rgb_next = data_out_fish3;
                end else begin
                    if(flag)begin
                        rgb_next = ~data_out;
                    end else begin
                     rgb_next = data_out;
                    end                   
                end           
            end else if(fish_region2 && fish_region3)begin
                  if(data_out_fish3!=12'h0f0 && data_out_fish_player!=12'h0f0)begin // --
                    rgb_next = data_out_fish_player;
                end else begin
                    if(data_out_fish_player==12'h0f0)begin
                        if(data_out_fish3==12'h0f0)begin
                            if(flag)begin//++
                                rgb_next = ~data_out;
                            end else begin
                                rgb_next = data_out;
                            end 
                        end else begin//+-
                            rgb_next = data_out_fish3;  
                        end                       
                    end else begin//-+
                        rgb_next = data_out_fish_player;
                    end
                end           
            end
   end else begin
     if(flag)begin
        rgb_next = ~data_out;
     end else begin
        rgb_next = data_out;
    end
  end     
end

// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
