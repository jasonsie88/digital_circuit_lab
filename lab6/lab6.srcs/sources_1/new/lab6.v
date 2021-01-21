`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/10/10 16:10:38
// Design Name: UART I/O example for Arty
// Module Name: lab6
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz
// Tool Versions: 
// Description: 
// 
// The parameters for the UART controller are 9600 baudrate, 8-N-1-N
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 0,
                 S_MAIN_PROMPT1 = 1, S_MAIN_READ_NUM1 = 2,
                 S_MAIN_PROMPT2=3, S_MAIN_READ_NUM2 =4,
                 S_MAIN_COMPUTE=5,S_MAIN_REPLY=6;
                 
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam MEM_SIZE=128;
localparam MAIN_PROMPT_STR=0;
localparam SECOND_PROMPT_STR=34;
localparam DIVISION_REPLY=69;


reg [16-1:0] A;
reg [16-1:0] B;
reg [16-1:0] ans=16'b0;
reg [16-1:0] remainder=16'b0;
integer counter=15;


// declare system variables
wire enter_pressed;
wire print_enable, print_done;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [2:0] P, P_next;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [7:0] data[0:MEM_SIZE-1];



// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire key_input;
wire is_receiving;
wire is_transmitting;
wire recv_error;
reg finish;
wire DIV_finish;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
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

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2001 :(
//
always@(posedge clk)begin
    if(~reset_n)begin
        {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7],data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15],data[16],data[17],
        data[18],data[19],data[20],data[21],data[22],data[23],data[24],data[25],data[26],data[27],data[28],data[29],data[30],data[31],data[32],data[33]}
        <={8'h0D,8'h0A,"Enter the first decimal number:",8'h00};    
    end
    else begin
        {data[34],data[35],data[36],data[37],data[38],data[39],data[40],data[41],data[42],data[43],data[44],data[45],data[46],data[47],data[48],data[49],data[50],data[51],
        data[52],data[53],data[54],data[55],data[56],data[57],data[58],data[59],data[60],data[61],data[62],data[63],data[64],data[65],data[66],data[67],data[68]}
        <={8'h0D,8'h0A,"Enter the second decimal number:",8'h00};  
        
        {data[69],data[70],data[71],data[72],data[73],data[74],data[75],data[76],data[77],data[78],data[79],data[80],data[81],data[82],
        data[83],data[84],data[85],data[86],data[87],data[88],data[89],data[90],data[91],data[92],data[93],data[94],data[95],data[96],data[97]}
        <={8'h0D,8'h0A,"The integer quotient is: 0x"};
        data[98] <= (ans[15:12] > 9) ? ans[15:12] + 55 : ans[15:12] + 48 ;
        data[99] <= (ans[11:8] > 9) ?  ans[11:8] + 55 : ans[11:8] + 48 ;
        data[100] <= (ans[7:4] > 9) ? ans[7:4] + 55 : ans[7:4] + 48 ;
        data[101] <= (ans[3:0] > 9) ? ans[3:0] + 55 : ans[3:0] +48 ;     
    end
end

// Combinational I/O logics of the top-level system
assign usr_led = counter;
assign enter_pressed = (rx_temp == 8'h0D); // don't use rx_byte here!
assign key_input=(rx_temp == 8'h30 || rx_temp == 8'h31 || rx_temp == 8'h32 || rx_temp == 8'h33 || rx_temp == 8'h34 || rx_temp == 8'h35 || rx_temp == 8'h36 || rx_temp == 8'h37 || rx_temp == 8'h38 || rx_temp == 8'h39);
assign tx_byte  = key_input ? rx_byte : data[send_counter]; 
// ------------------------------------------------------------------------
// FSM output logics: print string control signals.
assign print_enable = (P == S_MAIN_PROMPT1 || P == S_MAIN_PROMPT2 || P == S_MAIN_REPLY );
assign print_done = (Q==S_UART_INCR) ? (tx_byte == 8'h00) : ~print_enable;
assign DIV_finish = finish;
// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT || key_input);
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Wait for initial delay of the circuit.
	   if (init_counter < INIT_DELAY) P_next = S_MAIN_INIT;
		else P_next = S_MAIN_PROMPT1;
    S_MAIN_PROMPT1: // Print the prompt message.
      if (print_done) P_next = S_MAIN_READ_NUM1;
      else P_next = S_MAIN_PROMPT1;
    S_MAIN_READ_NUM1: // wait for <Enter> key.
      if (enter_pressed) P_next = S_MAIN_PROMPT2;
      else P_next = S_MAIN_READ_NUM1;
    S_MAIN_PROMPT2:
      if(print_done) P_next = S_MAIN_READ_NUM2;
      else P_next = S_MAIN_PROMPT2;
    S_MAIN_READ_NUM2:
      if(enter_pressed) P_next = S_MAIN_COMPUTE;
      else P_next = S_MAIN_READ_NUM2;
    S_MAIN_COMPUTE:
        if(DIV_finish) P_next = S_MAIN_REPLY;
        else P_next = S_MAIN_COMPUTE;
    S_MAIN_REPLY: // Print the hello message.
      if (print_done) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_REPLY;
  endcase
end


// Initialization counter.
always @(posedge clk) begin
  if (P == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// long divison


always@(posedge clk)begin
    if(~reset_n)begin
        A[16-1:0] <= 16'b0;
        B[16-1:0] <= 16'b0;
        ans [16-1:0] <= 16'b0;
        remainder [16-1:0] <= 16'b0;
        finish <= 1'b0;
        counter<=16;         
    end
    if(P == S_MAIN_INIT)begin
         A[16-1:0] <= 16'b0;
         B[16-1:0] <= 16'b0;
        ans [16-1:0] <= 16'b0;
        remainder [16-1:0] <= 16'b0;
        finish <= 1'b0; 
        counter<=16;             
    end
    
    if(P==S_MAIN_READ_NUM1 && key_input)begin
        A<=A*10+(rx_temp-48);
    end
    if(P==S_MAIN_READ_NUM2 && key_input)begin
        B<=B*10+(rx_temp-48);
    end
    if(P==S_MAIN_COMPUTE && !finish)begin
        for(counter=16; counter>0; counter=counter-1)begin    
            remainder = {remainder[14:0],A[counter-1]};
            if(remainder >= B)begin
                remainder = remainder - B;
                ans[counter-1]=1'b1;
            end
        //ans=A/B;
        end
        if(counter <= 0)begin
            finish=1'b1;
        end
    end 
    

    
end

// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end





// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= MAIN_PROMPT_STR;
    S_MAIN_READ_NUM1: send_counter <= SECOND_PROMPT_STR;
    S_MAIN_READ_NUM2: send_counter <= DIVISION_REPLY;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// The following logic stores the UART input in a temporary buffer.
// The input character will stay in the buffer for one clock cycle.
always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end
// End of the UART input logic
// ------------------------------------------------------------------------




endmodule
