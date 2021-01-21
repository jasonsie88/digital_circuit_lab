`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input uart_rx,
  output uart_tx,
  input  [3:0] usr_btn,
  output [3:0] usr_led
 
  // 1602 LCD Module Interface
  //output LCD_RS,
  //output LCD_RW,
  //output LCD_E,
  //output [3:0] LCD_D
);

localparam [3:0] S_MAIN_INIT = 4'b0000,S_MAIN_ADDR = 4'b0001,S_MAIN_READ = 4'b0010,S_MAIN_STORE = 4'b0011,
S_MAIN_PIPELINE1 = 4'b0100,S_MAIN_PIPELINE2=4'b0101,S_MAIN_PIPELINE3 = 4'b0110,S_MAIN_PIPELINE4=4'b0111,S_MAIN_SHOW=4'b1000;

localparam [1:0] S_UART_IDLE = 2'b00, S_UART_WAIT = 2'b01,
               S_UART_SEND = 2'b10, S_UART_INCR = 2'b11;

reg [7:0] ans [0:79];
reg [7:0] data[0:170];

//declare uart
reg  [8:0] send_counter;
reg  [1:0] Q, Q_next;
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;
assign tx_byte = data[send_counter];
assign transmit = (Q_next == S_UART_WAIT );

// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [3:0]  P, P_next;
reg  [11:0] user_addr ;
reg  [7:0] A_mat[1:16];
reg  [7:0] B_mat[1:16];
reg  [17:0] C_mat[1:16];
reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;


LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
  
debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

uart uart0(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);
wire [10:0] sram_addr_B;
wire [11:0] data_out_B;
// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
sram ram1(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_B), .data_i(data_in), .data_o(data_out_B));
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = user_addr[10:0];
assign sram_addr_B = user_addr[10:0]+16;
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end
integer count=0;
reg finish = 1'b0;
reg cal_finish = 1'b0;
always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT:
        if(btn_level[1])P_next = S_MAIN_ADDR;
        else P_next = S_MAIN_INIT;
    S_MAIN_ADDR:
        P_next = S_MAIN_READ;
    S_MAIN_READ:
        P_next = S_MAIN_STORE;
    S_MAIN_STORE:
        if(finish) P_next = S_MAIN_PIPELINE1;
        else P_next = S_MAIN_ADDR;
    S_MAIN_PIPELINE1:
         P_next = S_MAIN_PIPELINE2;
    S_MAIN_PIPELINE2:
        P_next = S_MAIN_PIPELINE3;
    S_MAIN_PIPELINE3:
        P_next = S_MAIN_PIPELINE4;
    S_MAIN_PIPELINE4:
        if(cal_finish) P_next = S_MAIN_SHOW;
        else P_next = S_MAIN_PIPELINE1;
    S_MAIN_SHOW:
        P_next = S_MAIN_SHOW;
  endcase
end


always @(posedge clk) begin
  if (~reset_n )begin
    user_addr <= 12'h000;
    count <= 0;
    finish <= 1'b0;
  end
  if(P == S_MAIN_ADDR && !finish)begin
     if (count != 0) begin
        user_addr <= user_addr + 1;
       end
    count <= count + 1;
    if(count > 16)begin
        finish <= 1'b1;
    end
  end
  if(P == S_MAIN_STORE)begin
        A_mat[user_addr+1] <= data_out;
        B_mat[user_addr+1] <= data_out_B;
   end 
end
integer k=1;
always @(posedge clk)begin
    if(~reset_n)begin
        cal_finish <= 1'b0;
        k<=1;
    end
    
    if(P == S_MAIN_PIPELINE1)begin 
            case(k)
            1:C_mat[1][17:0] <= A_mat[1][7:0]*B_mat[1][7:0];
            2:C_mat[2][17:0] <= A_mat[1][7:0]*B_mat[5][7:0];
            3:C_mat[3][17:0] <= A_mat[1][7:0]*B_mat[9][7:0];
            4:C_mat[4][17:0] <= A_mat[1][7:0]*B_mat[13][7:0];
            5:C_mat[5][17:0] <= A_mat[2][7:0]*B_mat[1][7:0];
            6:C_mat[6][17:0] <= A_mat[2][7:0]*B_mat[5][7:0];
            7:C_mat[7][17:0] <= A_mat[2][7:0]*B_mat[9][7:0];
            8:C_mat[8][17:0] <= A_mat[2][7:0]*B_mat[13][7:0];            
            9:C_mat[9][17:0] <= A_mat[3][7:0]*B_mat[1][7:0];
            10:C_mat[10][17:0] <= A_mat[3][7:0]*B_mat[5][7:0];
            11:C_mat[11][17:0] <= A_mat[3][7:0]*B_mat[9][7:0];
            12:C_mat[12][17:0] <= A_mat[3][7:0]*B_mat[13][7:0];
            13:C_mat[13][17:0] <= A_mat[4][7:0]*B_mat[1][7:0];
            14:C_mat[14][17:0] <= A_mat[4][7:0]*B_mat[5][7:0];
            15:C_mat[15][17:0] <= A_mat[4][7:0]*B_mat[9][7:0];
            16:C_mat[16][17:0] <= A_mat[4][7:0]*B_mat[13][7:0];            
            endcase
    end
    
    if(P == S_MAIN_PIPELINE2)begin 
            case(k)
            1:C_mat[1][17:0] <= A_mat[5][7:0]*B_mat[2][7:0] + C_mat[1][17:0];
            2:C_mat[2][17:0] <= A_mat[5][7:0]*B_mat[6][7:0] + C_mat[2][17:0];
            3:C_mat[3][17:0] <= A_mat[5][7:0]*B_mat[10][7:0] + C_mat[3][17:0];
            4:C_mat[4][17:0] <= A_mat[5][7:0]*B_mat[14][7:0] + C_mat[4][17:0];
            5:C_mat[5][17:0] <= A_mat[6][7:0]*B_mat[2][7:0] + C_mat[5][17:0];
            6:C_mat[6][17:0] <= A_mat[6][7:0]*B_mat[6][7:0] + C_mat[6][17:0];
            7:C_mat[7][17:0] <= A_mat[6][7:0]*B_mat[10][7:0] + C_mat[7][17:0];
            8:C_mat[8][17:0] <= A_mat[6][7:0]*B_mat[14][7:0] + C_mat[8][17:0];            
            9:C_mat[9][17:0] <= A_mat[7][7:0]*B_mat[2][7:0] + C_mat[9][17:0];
            10:C_mat[10][17:0] <= A_mat[7][7:0]*B_mat[6][7:0] + C_mat[10][17:0];
            11:C_mat[11][17:0] <= A_mat[7][7:0]*B_mat[10][7:0] + C_mat[11][17:0];
            12:C_mat[12][17:0] <= A_mat[7][7:0]*B_mat[14][7:0] + C_mat[12][17:0];
            13:C_mat[13][17:0] <= A_mat[8][7:0]*B_mat[2][7:0] + C_mat[13][17:0];
            14:C_mat[14][17:0] <= A_mat[8][7:0]*B_mat[6][7:0] + C_mat[14][17:0];
            15:C_mat[15][17:0] <= A_mat[8][7:0]*B_mat[10][7:0] + C_mat[15][17:0];
            16:C_mat[16][17:0] <= A_mat[8][7:0]*B_mat[14][7:0] + C_mat[16][17:0];            
            endcase
    end
     if(P == S_MAIN_PIPELINE3)begin 
            case(k)
            1:C_mat[1][17:0] <= A_mat[9][7:0]*B_mat[3][7:0] + C_mat[1][17:0];
            2:C_mat[2][17:0] <= A_mat[9][7:0]*B_mat[7][7:0] + C_mat[2][17:0];
            3:C_mat[3][17:0] <= A_mat[9][7:0]*B_mat[11][7:0] + C_mat[3][17:0];
            4:C_mat[4][17:0] <= A_mat[9][7:0]*B_mat[15][7:0] + C_mat[4][17:0];
            5:C_mat[5][17:0] <= A_mat[10][7:0]*B_mat[3][7:0] + C_mat[5][17:0];
            6:C_mat[6][17:0] <= A_mat[10][7:0]*B_mat[7][7:0] + C_mat[6][17:0];
            7:C_mat[7][17:0] <= A_mat[10][7:0]*B_mat[11][7:0] + C_mat[7][17:0];
            8:C_mat[8][17:0] <= A_mat[10][7:0]*B_mat[15][7:0] + C_mat[8][17:0];            
            9:C_mat[9][17:0] <= A_mat[11][7:0]*B_mat[3][7:0] + C_mat[9][17:0];
            10:C_mat[10][17:0] <= A_mat[11][7:0]*B_mat[7][7:0] + C_mat[10][17:0];
            11:C_mat[11][17:0] <= A_mat[11][7:0]*B_mat[11][7:0] + C_mat[11][17:0];
            12:C_mat[12][17:0] <= A_mat[11][7:0]*B_mat[15][7:0] + C_mat[12][17:0];
            13:C_mat[13][17:0] <= A_mat[12][7:0]*B_mat[3][7:0] + C_mat[13][17:0];
            14:C_mat[14][17:0] <= A_mat[12][7:0]*B_mat[7][7:0] + C_mat[14][17:0];
            15:C_mat[15][17:0] <= A_mat[12][7:0]*B_mat[11][7:0] + C_mat[15][17:0];
            16:C_mat[16][17:0] <= A_mat[12][7:0]*B_mat[15][7:0] + C_mat[16][17:0];            
            endcase
    end   
    if(P == S_MAIN_PIPELINE4)begin
            case(k)
            1:C_mat[1][17:0] <= A_mat[13][7:0]*B_mat[4][7:0] + C_mat[1][17:0];
            2:C_mat[2][17:0] <= A_mat[13][7:0]*B_mat[8][7:0] + C_mat[2][17:0];
            3:C_mat[3][17:0] <= A_mat[13][7:0]*B_mat[12][7:0] + C_mat[3][17:0];
            4:C_mat[4][17:0] <= A_mat[13][7:0]*B_mat[16][7:0] + C_mat[4][17:0];
            5:C_mat[5][17:0] <= A_mat[14][7:0]*B_mat[4][7:0] + C_mat[5][17:0];
            6:C_mat[6][17:0] <= A_mat[14][7:0]*B_mat[8][7:0] + C_mat[6][17:0];
            7:C_mat[7][17:0] <= A_mat[14][7:0]*B_mat[12][7:0] + C_mat[7][17:0];
            8:C_mat[8][17:0] <= A_mat[14][7:0]*B_mat[16][7:0] + C_mat[8][17:0];            
            9:C_mat[9][17:0] <= A_mat[15][7:0]*B_mat[4][7:0] + C_mat[9][17:0];
            10:C_mat[10][17:0] <= A_mat[15][7:0]*B_mat[8][7:0] + C_mat[10][17:0];
            11:C_mat[11][17:0] <= A_mat[15][7:0]*B_mat[12][7:0] + C_mat[11][17:0];
            12:C_mat[12][17:0] <= A_mat[15][7:0]*B_mat[16][7:0] + C_mat[12][17:0];
            13:C_mat[13][17:0] <= A_mat[16][7:0]*B_mat[4][7:0] + C_mat[13][17:0];
            14:C_mat[14][17:0] <= A_mat[16][7:0]*B_mat[8][7:0] + C_mat[14][17:0];
            15:C_mat[15][17:0] <= A_mat[16][7:0]*B_mat[12][7:0] + C_mat[15][17:0];
            16:C_mat[16][17:0] <= A_mat[16][7:0]*B_mat[16][7:0] + C_mat[16][17:0];            
            endcase        
        k <= k+1;
    end
    if(k > 16)begin
        cal_finish <= 1'b1;
    end 
end


// End of the main controller

// uart FSM
reg [1:0] Q1,Q1_next;
localparam [1:0] S_MAIN_UART_INIT = 2'b00,S_MAIN_PROMPT = 2'b01,S_MAIN_STAY=2'b10;
localparam PROMPT_STR = 0;

always@(posedge clk)begin
    if(~reset_n) Q1 <= S_MAIN_INIT;
    else Q1 <= Q1_next;
end
wire print_done;
wire print_enable;


always@(*)begin
    case(Q1)
    S_MAIN_UART_INIT:
        if(P == S_MAIN_SHOW)Q1_next = S_MAIN_PROMPT;
        else Q1_next = S_MAIN_UART_INIT;
    S_MAIN_PROMPT:
        if(print_done)Q1_next = S_MAIN_STAY;
        else Q1_next = S_MAIN_PROMPT;
    S_MAIN_STAY:
        Q1_next = S_MAIN_STAY;
    endcase
end

assign usr_led = send_counter[7:4];

always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end


assign print_enable = (Q1 != S_MAIN_PROMPT && Q1_next == S_MAIN_PROMPT);
assign print_done = (tx_byte == 8'h00);

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable == 1) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h00) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

always@(*) begin
    {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7],data[8],data[9],
    data[10],data[11],data[12],data[13],data[14],data[15],data[16],data[17],data[18],data[19],
    data[20],data[21],data[22],data[23],data[24],data[25],data[26],data[27],
    data[28],data[29],data[30],data[31],data[32],data[33],data[34],data[35],
    data[36],data[37],data[38],data[39],data[40],data[41]}<={"The matrix multiplication result   ",8'h0D,8'h0A,"is:",8'h0D,8'h0A};
 end   
 always@(*)begin
    {data[42], data[43], data[44], data[45], data[46], data[47], data[48], data[49],
	 data[50], data[51], data[52], data[53], data[54], data[55], data[56], data[57],
	 data[58], data[59], data[60], data[61], data[62], data[63], data[64], data[65],
     data[66], data[67], data[68], data[69], data[70], data[71], data[72], data[73] }
	  <= {"[ ", ans[0], ans[1], ans[2], ans[3], ans[4], ", ", ans[5], ans[6], ans[7], ans[8], ans[9], ", ", ans[10], ans[11], ans[12], ans[13], ans[14], ", ", ans[15], ans[16], ans[17], ans[18], ans[19], " ]", 8'h0D, 8'h0A};
end	
always@(*)begin
	{data[74], data[75], data[76], data[77], data[78], data[79], data[80], data[81],
	 data[82], data[83], data[84], data[85], data[86], data[87], data[88], data[89],
     data[90], data[91], data[92], data[93], data[94], data[95], data[96], data[97],
	 data[98], data[99], data[100], data[101], data[102], data[103], data[104], data[105]}
	  <= {"[ ", ans[20], ans[21], ans[22], ans[23], ans[24], ", ", ans[25], ans[26], ans[27], ans[28], ans[29], ", ", ans[30], ans[31], ans[32], ans[33], ans[34], ", ", ans[35], ans[36], ans[37], ans[38], ans[39], " ]", 8'h0D, 8'h0A};
end	  
always@(*)begin
	{data[106], data[107], data[108], data[109], data[110], data[111], data[112], data[113],
     data[114], data[115], data[116], data[117], data[118], data[119], data[120], data[121],
	 data[122], data[123], data[124], data[125], data[126],data[127], data[128], data[129], data[130],
	 data[131], data[132], data[133], data[134], data[135], data[136], data[137]}
	  <= {"[ ", ans[40], ans[41], ans[42], ans[43], ans[44], ", ", ans[45], ans[46], ans[47], ans[48], ans[49], ", ", ans[50], ans[51], ans[52], ans[53], ans[54], ", ", ans[55], ans[56], ans[57], ans[58], ans[59], " ]", 8'h0D, 8'h0A};
end
always@(*)begin
	{data[138], data[139], data[140], data[141], data[142], data[143], data[144], data[145],
     data[146], data[147], data[148], data[149], data[150], data[151], data[152], data[153],
     data[154], data[155], data[156], data[157], data[158], data[159], data[160], data[161],
     data[162], data[163], data[164], data[165], data[166], data[167], data[168], data[169], data[170]}
	  <= {"[ ", ans[60], ans[61], ans[62], ans[63], ans[64], ", ", ans[65], ans[66], ans[67], ans[68], ans[69], ", ", ans[70], ans[71], ans[72], ans[73], ans[74], ", ", ans[75], ans[76], ans[77], ans[78], ans[79], " ]", 8'h0D, 8'h0A, 8'h00};    
end

always@(posedge clk)begin
    case(Q1_next)
        S_MAIN_INIT: send_counter <= PROMPT_STR;
        default: send_counter <= send_counter + (Q_next==S_UART_INCR);
    endcase
end

always@(posedge clk)begin
    rx_temp <= (received)? rx_byte : 8'h00;
end

always@(posedge clk)begin
    ans[0] <= C_mat[1][17:16] + "0";
end
always@(posedge clk)begin
    ans[1] <= ((C_mat[1][15:12] > 9) ? "7":"0") + C_mat[1][15:12];
end
always@(posedge clk)begin
    ans[2] <= ((C_mat[1][11:8] > 9) ? "7" :"0") + C_mat[1][11:8];
end
always@(posedge clk)begin
    ans[3] <= ((C_mat[1][7:4] > 9) ? "7" : "0") + C_mat[1][7:4];
end
always@(posedge clk)begin
    ans[4] <= ((C_mat[1][3:0] > 9) ? "7" : "0") + C_mat[1][3:0];
end
always@(posedge clk)begin
    ans[5] <= C_mat[2][17:16] + "0";
end
always@(posedge clk)begin
    ans[6] <= ((C_mat[2][15:12] > 9) ? "7":"0") + C_mat[2][15:12];
end
always@(posedge clk)begin
    ans[7] <= ((C_mat[2][11:8] > 9) ? "7" :"0") + C_mat[2][11:8];
end
always@(posedge clk)begin
    ans[8] <= ((C_mat[2][7:4] > 9) ? "7" : "0") + C_mat[2][7:4];
end
always@(posedge clk)begin
    ans[9] <= ((C_mat[2][3:0] > 9) ? "7" : "0") + C_mat[2][3:0];   
end 
always@(posedge clk)begin
    ans[10] <= C_mat[3][17:16] + "0";
end
always@(posedge clk)begin
    ans[11] <= ((C_mat[3][15:12] > 9) ? "7":"0") + C_mat[3][15:12];
end
always@(posedge clk)begin
    ans[12] <= ((C_mat[3][11:8] > 9) ? "7" :"0") + C_mat[3][11:8];
end
always@(posedge clk)begin
    ans[13] <= ((C_mat[3][7:4] > 9) ? "7" : "0") + C_mat[3][7:4];
end
always@(posedge clk)begin
    ans[14] <= ((C_mat[3][3:0] > 9) ? "7" : "0") + C_mat[3][3:0];
end
always@(posedge clk)begin
    ans[15] <= C_mat[4][17:16] + "0";
end
always@(posedge clk)begin
    ans[16] <= ((C_mat[4][15:12] > 9) ? "7":"0") + C_mat[4][15:12];
end
always@(posedge clk)begin
    ans[17] <= ((C_mat[4][11:8] > 9) ? "7" :"0") + C_mat[4][11:8];
end
always@(posedge clk)begin
    ans[18] <= ((C_mat[4][7:4] > 9) ? "7" : "0") + C_mat[4][7:4];
end
always@(posedge clk)begin
    ans[19] <= ((C_mat[4][3:0] > 9) ? "7" : "0") + C_mat[4][3:0];
end
always@(posedge clk)begin
    ans[20] <= C_mat[5][17:16] + "0";
end
always@(posedge clk)begin
    ans[21] <= ((C_mat[5][15:12] > 9) ? "7":"0") + C_mat[5][15:12];
end
always@(posedge clk)begin
    ans[22] <= ((C_mat[5][11:8] > 9) ? "7" :"0") + C_mat[5][11:8];
end
always@(posedge clk)begin
    ans[23] <= ((C_mat[5][7:4] > 9) ? "7" : "0") + C_mat[5][7:4];
end
always@(posedge clk)begin
    ans[24] <= ((C_mat[5][3:0] > 9) ? "7" : "0") + C_mat[5][3:0];
end
always@(posedge clk)begin
    ans[25] <= C_mat[6][17:16] + "0";
end
always@(posedge clk)begin
    ans[26] <= ((C_mat[6][15:12] > 9) ? "7":"0") + C_mat[6][15:12];
end
always@(posedge clk)begin
    ans[27] <= ((C_mat[6][11:8] > 9) ? "7" :"0") + C_mat[6][11:8];
end
always@(posedge clk)begin
    ans[28] <= ((C_mat[6][7:4] > 9) ? "7" : "0") + C_mat[6][7:4];
end
always@(posedge clk)begin
    ans[29] <= ((C_mat[6][3:0] > 9) ? "7" : "0") + C_mat[6][3:0];
end
always@(posedge clk)begin
    ans[30] <= C_mat[7][17:16] + "0";
end
always@(posedge clk)begin
    ans[31] <= ((C_mat[7][15:12] > 9) ? "7":"0") + C_mat[7][15:12];
end
always@(posedge clk)begin
    ans[32] <= ((C_mat[7][11:8] > 9) ? "7" :"0") + C_mat[7][11:8];
end
always@(posedge clk)begin
    ans[33] <= ((C_mat[7][7:4] > 9) ? "7" : "0") + C_mat[7][7:4];
end
always@(posedge clk)begin
    ans[34] <= ((C_mat[7][3:0] > 9) ? "7" : "0") + C_mat[7][3:0];
end
always@(posedge clk)begin
    ans[35] <= C_mat[8][17:16] + "0";
end
always@(posedge clk)begin
    ans[36] <= ((C_mat[8][15:12] > 9) ? "7":"0") + C_mat[8][15:12];
end
always@(posedge clk)begin
    ans[37] <= ((C_mat[8][11:8] > 9) ? "7" :"0") + C_mat[8][11:8];
end
always@(posedge clk)begin
    ans[38] <= ((C_mat[8][7:4] > 9) ? "7" : "0") + C_mat[8][7:4];
end
always@(posedge clk)begin
    ans[39] <= ((C_mat[8][3:0] > 9) ? "7" : "0") + C_mat[8][3:0];
end
always@(posedge clk)begin    
    ans[40] <= C_mat[9][17:16] + "0";
end    
always@(posedge clk)begin
    ans[41] <= ((C_mat[9][15:12] > 9) ? "7":"0") + C_mat[9][15:12];
end
always@(posedge clk)begin
    ans[42] <= ((C_mat[9][11:8] > 9) ? "7" :"0") + C_mat[9][11:8];
end
always@(posedge clk)begin
    ans[43] <= ((C_mat[9][7:4] > 9) ? "7" : "0") + C_mat[9][7:4];
end
always@(posedge clk)begin
    ans[44] <= ((C_mat[9][3:0] > 9) ? "7" : "0") + C_mat[9][3:0];
end
always@(posedge clk)begin
    ans[45] <= C_mat[10][17:16] + "0";
end
always@(posedge clk)begin
    ans[46] <= ((C_mat[10][15:12] > 9) ? "7":"0") + C_mat[10][15:12];
end
always@(posedge clk)begin
    ans[47] <= ((C_mat[10][11:8] > 9) ? "7" :"0") + C_mat[10][11:8];
end    
always@(posedge clk)begin
    ans[48] <= ((C_mat[10][7:4] > 9) ? "7" : "0") + C_mat[10][7:4];
end
always@(posedge clk)begin    
    ans[49] <= ((C_mat[10][3:0] > 9) ? "7" : "0") + C_mat[10][3:0];
end
always@(posedge clk)begin    
    ans[50] <= C_mat[11][17:16] + "0";
end
always@(posedge clk)begin    
    ans[51] <= ((C_mat[11][15:12] > 9) ? "7":"0") + C_mat[11][15:12];
end
always@(posedge clk)begin    
    ans[52] <= ((C_mat[11][11:8] > 9) ? "7" :"0") + C_mat[11][11:8];
end
always@(posedge clk)begin    
    ans[53] <= ((C_mat[11][7:4] > 9) ? "7" : "0") + C_mat[11][7:4];
end
always@(posedge clk)begin
    ans[54] <= ((C_mat[11][3:0] > 9) ? "7" : "0") + C_mat[11][3:0];
end
always@(posedge clk)begin    
    ans[55] <= C_mat[12][17:16] + "0";
end
always@(posedge clk)begin    
    ans[56] <= ((C_mat[12][15:12] > 9) ? "7":"0") + C_mat[12][15:12];
end
always@(posedge clk)begin    
    ans[57] <= ((C_mat[12][11:8] > 9) ? "7" :"0") + C_mat[12][11:8];
end
always@(posedge clk)begin    
    ans[58] <= ((C_mat[12][7:4] > 9) ? "7" : "0") + C_mat[12][7:4];
end
always@(posedge clk)begin    
    ans[59] <= ((C_mat[12][3:0] > 9) ? "7" : "0") + C_mat[12][3:0];
end
always@(posedge clk)begin    
    ans[60] <= C_mat[13][17:16] + "0";
end
always@(posedge clk)begin    
    ans[61] <= ((C_mat[13][15:12] > 9) ? "7":"0") + C_mat[13][15:12];
end
always@(posedge clk)begin    
    ans[62] <= ((C_mat[13][11:8] > 9) ? "7" :"0") + C_mat[13][11:8];
end
always@(posedge clk)begin   
    ans[63] <= ((C_mat[13][7:4] > 9) ? "7" : "0") + C_mat[13][7:4];
end
always@(posedge clk)begin    
    ans[64] <= ((C_mat[13][3:0] > 9) ? "7" : "0") + C_mat[13][3:0];
end
always@(posedge clk) begin   
    ans[65] <= C_mat[14][17:16] + "0";
end
always@(posedge clk)begin    
    ans[66] <= ((C_mat[14][15:12] > 9) ? "7":"0") + C_mat[14][15:12];
end   
always@(posedge clk)begin
    ans[67] <= ((C_mat[14][11:8] > 9) ? "7" :"0") + C_mat[14][11:8];
end 
always@(posedge clk)begin   
    ans[68] <= ((C_mat[14][7:4] > 9) ? "7" : "0") + C_mat[14][7:4];
end
always@(posedge clk)begin    
    ans[69] <= ((C_mat[14][3:0] > 9) ? "7" : "0") + C_mat[14][3:0];
end
always@(posedge clk)begin   
    ans[70] <= C_mat[15][17:16] + "0";
end
always@(posedge clk)begin    
    ans[71] <= ((C_mat[15][15:12] > 9) ? "7":"0") + C_mat[15][15:12];
end
always@(posedge clk)begin    
    ans[72] <= ((C_mat[15][11:8] > 9) ? "7" :"0") + C_mat[15][11:8];
end
always@(posedge clk)begin    
    ans[73] <= ((C_mat[15][7:4] > 9) ? "7" : "0") + C_mat[15][7:4];
end
always@(posedge clk)begin   
    ans[74] <= ((C_mat[15][3:0] > 9) ? "7" : "0") + C_mat[15][3:0];
end
always@(posedge clk)begin    
    ans[75] <= C_mat[16][17:16] + "0";
end
always@(posedge clk)begin    
    ans[76] <= ((C_mat[16][15:12] > 9) ? "7":"0") + C_mat[16][15:12];
end
always@(posedge clk)begin
    ans[77] <= ((C_mat[16][11:8] > 9) ? "7" :"0") + C_mat[16][11:8];
end
always@(posedge clk)begin    
    ans[78] <= ((C_mat[16][7:4] > 9) ? "7" : "0") + C_mat[16][7:4];
end
always@(posedge clk)begin    
    ans[79] <= ((C_mat[16][3:0] > 9) ? "7" : "0") + C_mat[16][3:0];    
end






endmodule
