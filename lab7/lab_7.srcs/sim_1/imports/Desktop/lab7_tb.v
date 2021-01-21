`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/19 21:43:00
// Design Name: 
// Module Name: lab7_tb
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


module lab7_tb();

reg clk = 1;
reg reset_n = 1;
reg [3:0] BTN;
wire [3:0] LED;

reg uart_rx;
wire uart_tx;

always #5 clk = ~clk;

lab7 uut(.clk(clk), .reset_n(reset_n), .usr_btn(BTN), 
         .usr_led(LED), .uart_rx(uart_rx), .uart_tx(uart_tx));
         
wire [ 7:0] mat_A;
wire [ 7:0] mat_B;
wire [17:0] mat_C;

assign mat_A = uut.mat_A[2][2];
assign mat_B = uut.mat_B[2][2];
assign mat_C = uut.mat_C[2][2];
         
initial begin
    reset_n = 1;
    clk = 1;
    BTN = 0;
    #20
    reset_n = 0;
    #20
    reset_n = 1;
    #500
    BTN = 4'b0010;
    #21000000
    BTN = 4'b0000;
    #21000000
    ;
end
endmodule
