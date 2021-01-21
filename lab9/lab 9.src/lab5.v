`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab9(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs

integer counter=0;
wire btn_level, btn_pressed;
reg prev_btn_level;
reg [3:0] P,P_next;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "Crack the passwd"; // Initialize the text of the second row.
reg [0:127] passwd_hash = 128'h2B391453507883C4F0349DA1A4C31B94;
reg [63:0] start_point0 = {"0","0","0","0","0","0","0","0"};
reg [63:0] start_point1 = {"0","4","0","0","0","0","0","0"};
reg [63:0] start_point2 = {"0","8","0","0","0","0","0","0"};
reg [63:0] start_point3 = {"1","2","0","0","0","0","0","0"};
reg [63:0] start_point4 = {"1","6","0","0","0","0","0","0"};
reg [63:0] start_point5 = {"2","0","0","0","0","0","0","0"};
reg [63:0] start_point6 = {"2","4","0","0","0","0","0","0"};
reg [63:0] start_point7 = {"2","8","0","0","0","0","0","0"};
reg [63:0] start_point8 = {"3","2","0","0","0","0","0","0"};
reg [63:0] start_point9 = {"3","6","0","0","0","0","0","0"};
reg [63:0] start_point10 = {"4","0","0","0","0","0","0","0"};
reg [63:0] start_point11 = {"4","4","0","0","0","0","0","0"};
reg [63:0] start_point12 = {"4","8","0","0","0","0","0","0"};
reg [63:0] start_point13 = {"5","2","0","0","0","0","0","0"};
reg [63:0] start_point14 = {"5","6","0","0","0","0","0","0"};
reg [63:0] start_point15 = {"6","0","0","0","0","0","0","0"};
reg [63:0] start_point16 = {"6","4","0","0","0","0","0","0"};
reg [63:0] start_point17 = {"6","8","0","0","0","0","0","0"};
reg [63:0] start_point18 = {"7","2","0","0","0","0","0","0"};
reg [63:0] start_point19 = {"7","6","0","0","0","0","0","0"};
reg [63:0] start_point20 = {"8","0","0","0","0","0","0","0"};
reg [63:0] start_point21 = {"8","4","0","0","0","0","0","0"};
reg [63:0] start_point22 = {"8","8","0","0","0","0","0","0"};
reg [63:0] start_point23 = {"9","2","0","0","0","0","0","0"};
reg [63:0] start_point24 = {"9","6","0","0","0","0","0","0"};

reg [7:0]timer[0:6]={"0","0","0","0","0","0","0"};
reg  [63:0] ans;
wire [63:0] ans0;
wire [63:0] ans1;
wire [63:0] ans2;
wire [63:0] ans3;
wire [63:0] ans4;
wire [63:0] ans5;
wire [63:0] ans6;
wire [63:0] ans7;
wire [63:0] ans8;
wire [63:0] ans9;
wire [63:0] ans10;
wire [63:0] ans11;
wire [63:0] ans12;
wire [63:0] ans13;
wire [63:0] ans14;
wire [63:0] ans15;
wire [63:0] ans16;
wire [63:0] ans17;
wire [63:0] ans18;
wire [63:0] ans19;
wire [63:0] ans20;
wire [63:0] ans21;
wire [63:0] ans22;
wire [63:0] ans23;
wire [63:0] ans24;
wire valid0,valid1,valid2,valid3,
 valid4,valid5,valid6,valid7,
 valid8,valid9,valid10,valid11,
 valid12,valid13,valid14,valid15,
 valid16,valid17,valid18,valid19,
 valid20,valid21,valid22,valid23,valid24;

reg [10:0] init_counter;
reg init_finish=1'b0;
reg start=1'b0;


localparam [3:0] S_MAIN_INIT=4'b0000,S_MAIN_PRESS=4'b0001,S_MAIN_CAL=4'b0010,S_MAIN_STORE=4'b0100,S_MAIN_SHOW=4'b0011;
                
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
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

md5 md0(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point0),
    .valid(valid0),
    .passwd(ans0)
);

md5 md1(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point1),
    .valid(valid1),
    .passwd(ans1)
);

md5 md2(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point2),
    .valid(valid2),
    .passwd(ans2)
);

md5 md3(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point3),
    .valid(valid3),
    .passwd(ans3)
);

md5 md4(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point4),
    .valid(valid4),
    .passwd(ans4)
);

md5 md5(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point5),
    .valid(valid5),
    .passwd(ans5)
);

md5 md6(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point6),
    .valid(valid6),
    .passwd(ans6)
);

md5 md7(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point7),
    .valid(valid7),
    .passwd(ans7)
);

md5 md8(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point8),
    .valid(valid8),
    .passwd(ans8)
);

md5 md9(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point9),
    .valid(valid9),
    .passwd(ans9)
);

md5 md10(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point10),
    .valid(valid10),
    .passwd(ans10)
);

md5 md11(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point11),
    .valid(valid11),
    .passwd(ans11)
);

md5 md12(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point12),
    .valid(valid12),
    .passwd(ans12)
);

md5 md13(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point13),
    .valid(valid13),
    .passwd(ans13)
);

md5 md14(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point14),
    .valid(valid14),
    .passwd(ans14)
);

md5 md15(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point15),
    .valid(valid15),
    .passwd(ans15)
);

md5 md16(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point16),
    .valid(valid16),
    .passwd(ans16)
);

md5 md17(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point17),
    .valid(valid17),
    .passwd(ans17)
);

md5 md18(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point18),
    .valid(valid18),
    .passwd(ans18)
);

md5 md19(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point19),
    .valid(valid19),
    .passwd(ans19)
);

md5 md20(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point20),
    .valid(valid20),
    .passwd(ans20)
);

md5 md21(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point21),
    .valid(valid21),
    .passwd(ans21)
);

md5 md22(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point22),
    .valid(valid22),
    .passwd(ans22)
);

md5 md23(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point23),
    .valid(valid23),
    .passwd(ans23)
);

md5 md24(
    .clk(clk),
    .reset_n(reset_n),
    .passwd_hash(passwd_hash),
    .press(btn_pressed),
    .start(start_point24),
    .valid(valid24),
    .passwd(ans24)
);

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);


always@(posedge clk)begin
    if(~reset_n)begin
        P<=S_MAIN_INIT;
    end else begin
        P<=P_next;
    end
end

always@(posedge clk)begin
    if(~reset_n)begin
        init_counter <= 11'b0;
    end else if(P==S_MAIN_INIT)begin
        init_counter <= init_counter + 1;
    end
end


always@(*)begin
    case(P)
    S_MAIN_INIT: 
        if(init_counter == 11'd1000)begin 
               P_next = S_MAIN_PRESS;
        end else begin
               P_next = S_MAIN_INIT;
         end
    S_MAIN_PRESS:
        if(btn_pressed==1'b1)begin
            P_next = S_MAIN_CAL;
        end else begin
            P_next = S_MAIN_PRESS;
        end
    S_MAIN_CAL:
        if(valid0 || valid1 || valid2 || valid3 ||valid4 || valid5 || valid6 || valid7 || valid8 || valid9 ||
        valid10 || valid11 || valid12 || valid13 || valid14 || valid15 || valid16 || valid17|| valid18 || valid19 ||
        valid20 || valid21 || valid22 || valid23|| valid24)begin
            P_next = S_MAIN_STORE;
        end else begin
            P_next = S_MAIN_CAL;
        end
    S_MAIN_STORE:
        P_next = S_MAIN_SHOW;
    S_MAIN_SHOW:
        P_next = S_MAIN_SHOW;
    endcase
end

always@(posedge clk)begin
    if(~reset_n)begin
        ans<={"0","0","0","0","0","0","0","0"};
    end
    if(P==S_MAIN_STORE)begin
        if(valid0==1)begin         
           ans <={ans0[63:56],ans0[55:48],ans0[47:40],ans0[39:32],ans0[31:24],ans0[23:16],ans0[15:8],ans0[7:0]};
        end 
        if(valid1==1)begin
          ans <={ans1[63:56],ans1[55:48],ans1[47:40],ans1[39:32],ans1[31:24],ans1[23:16],ans0[15:8],ans1[7:0]};
        end
        if(valid2==1)begin
           ans <={ans2[63:56],ans2[55:48],ans2[47:40],ans2[39:32],ans2[31:24],ans2[23:16],ans2[15:8],ans2[7:0]};
        end
        if(valid3==1)begin
            ans <={ans3[63:56],ans3[55:48],ans3[47:40],ans3[39:32],ans3[31:24],ans3[23:16],ans3[15:8],ans3[7:0]};
        end
        if(valid4==1)begin         
           ans <={ans4[63:56],ans4[55:48],ans4[47:40],ans4[39:32],ans4[31:24],ans4[23:16],ans4[15:8],ans4[7:0]};
        end 
        if(valid5==1)begin
          ans <={ans5[63:56],ans5[55:48],ans5[47:40],ans5[39:32],ans5[31:24],ans5[23:16],ans5[15:8],ans5[7:0]};
        end
        if(valid6==1)begin
           ans <={ans6[63:56],ans6[55:48],ans6[47:40],ans6[39:32],ans6[31:24],ans6[23:16],ans6[15:8],ans6[7:0]};
        end
        if(valid7==1)begin
            ans <={ans7[63:56],ans7[55:48],ans7[47:40],ans7[39:32],ans7[31:24],ans7[23:16],ans7[15:8],ans7[7:0]};
        end
         if(valid8==1)begin         
           ans <={ans8[63:56],ans8[55:48],ans8[47:40],ans8[39:32],ans8[31:24],ans8[23:16],ans8[15:8],ans8[7:0]};
        end 
        if(valid9==1)begin
          ans <={ans9[63:56],ans9[55:48],ans9[47:40],ans9[39:32],ans9[31:24],ans9[23:16],ans9[15:8],ans9[7:0]};
        end
        if(valid10==1)begin
           ans <={ans10[63:56],ans10[55:48],ans10[47:40],ans10[39:32],ans10[31:24],ans10[23:16],ans10[15:8],ans10[7:0]};
        end
        if(valid11==1)begin
            ans <={ans11[63:56],ans11[55:48],ans11[47:40],ans11[39:32],ans11[31:24],ans11[23:16],ans11[15:8],ans11[7:0]};
        end
        if(valid12==1)begin         
           ans <={ans12[63:56],ans12[55:48],ans12[47:40],ans12[39:32],ans12[31:24],ans12[23:16],ans12[15:8],ans12[7:0]};
        end 
        if(valid13==1)begin
          ans <={ans13[63:56],ans13[55:48],ans13[47:40],ans13[39:32],ans13[31:24],ans13[23:16],ans13[15:8],ans13[7:0]};
        end
        if(valid14==1)begin
           ans <={ans14[63:56],ans14[55:48],ans14[47:40],ans14[39:32],ans14[31:24],ans14[23:16],ans14[15:8],ans14[7:0]};
        end
        if(valid15==1)begin
            ans <={ans15[63:56],ans15[55:48],ans15[47:40],ans15[39:32],ans15[31:24],ans15[23:16],ans15[15:8],ans15[7:0]};
        end
        if(valid16==1)begin         
           ans <={ans16[63:56],ans16[55:48],ans16[47:40],ans16[39:32],ans16[31:24],ans16[23:16],ans16[15:8],ans16[7:0]};
        end 
        if(valid17==1)begin
          ans <={ans17[63:56],ans17[55:48],ans17[47:40],ans17[39:32],ans17[31:24],ans17[23:16],ans17[15:8],ans17[7:0]};
        end
        if(valid18==1)begin
           ans <={ans18[63:56],ans18[55:48],ans18[47:40],ans18[39:32],ans18[31:24],ans18[23:16],ans18[15:8],ans18[7:0]};
        end
        if(valid19==1)begin
            ans <={ans19[63:56],ans19[55:48],ans19[47:40],ans19[39:32],ans19[31:24],ans19[23:16],ans19[15:8],ans19[7:0]};
        end
        if(valid20==1)begin
            ans <={ans20[63:56],ans20[55:48],ans20[47:40],ans20[39:32],ans20[31:24],ans20[23:16],ans20[15:8],ans20[7:0]};
        end
        if(valid21==1)begin         
           ans <={ans21[63:56],ans21[55:48],ans21[47:40],ans21[39:32],ans21[31:24],ans21[23:16],ans21[15:8],ans21[7:0]};
        end 
        if(valid22==1)begin
          ans <={ans22[63:56],ans22[55:48],ans22[47:40],ans22[39:32],ans22[31:24],ans22[23:16],ans22[15:8],ans22[7:0]};
        end
        if(valid23==1)begin
           ans <={ans23[63:56],ans23[55:48],ans23[47:40],ans23[39:32],ans23[31:24],ans23[23:16],ans23[15:8],ans23[7:0]};
        end
        if(valid24==1)begin
            ans <={ans24[63:56],ans24[55:48],ans24[47:40],ans24[39:32],ans24[31:24],ans24[23:16],ans24[15:8],ans24[7:0]};
        end
    end
end


always@(posedge clk)begin
    if(~reset_n)begin
        start<=1'b0;
        counter<=0;
        {timer[0],timer[1],timer[2],timer[3],timer[4],timer[5],timer[6]}<={8'd48,8'd48,8'd48,8'd48,8'd48,8'd48,8'd48};        
    end
    if(P==S_MAIN_PRESS && P_next==S_MAIN_CAL)begin
        start<=1'b1;
    end 
    if(start==1'b1 && P!=S_MAIN_SHOW && P!=S_MAIN_PRESS)begin
       counter <= (counter<100000) ? counter+1 : 0; 
    end
    if(counter==100000)begin
        if(timer[6]!=8'd57)begin
            timer[6]<=timer[6]+1;
        end else if(timer[5]!=8'd57)begin
            timer[5]<=timer[5]+1;
            timer[6]<=8'd48;
        end else if(timer[4]!=8'd57)begin
            timer[4]<=timer[4]+1;
            timer[5]<=8'd48;
            timer[6]<=8'd48;
        end else if(timer[3]!=8'd57)begin
            timer[3]<=timer[3]+1;
            timer[4]<=8'd48;
            timer[5]<=8'd48;
            timer[6]<=8'd48;
        end else if(timer[2]!=8'd57)begin
            timer[2]<=timer[2]+1;
            timer[3]<=8'd48;
            timer[4]<=8'd48;
            timer[5]<=8'd48;
            timer[6]<=8'd48;
        end else if(timer[1]!=8'd57)begin
            timer[1]<=timer[1]+1;
            timer[2]<=8'd48;
            timer[3]<=8'd48;
            timer[4]<=8'd48;
            timer[5]<=8'd48;
            timer[6]<=8'd48;        
        end else if(timer[0]!=8'd57)begin
            timer[0]<=timer[0]+1;
            timer[1]<=8'd48;
            timer[2]<=8'd48;
            timer[3]<=8'd48;
            timer[4]<=8'd48;
            timer[5]<=8'd48;
            timer[6]<=8'd48;         
        end
    end
end

always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "Press BTN3 to   ";
    row_B <= "Crack the passwd";
  end else if(P == S_MAIN_PRESS)begin
    row_A <= "Press BTN3 to   ";
    row_B <= "Crack the passwd";  
  end else if(P==S_MAIN_SHOW) begin
    row_A <={"Passwd: ",ans[63:56],ans[55:48],ans[47:40],ans[39:32],ans[31:24],ans[23:16],ans[15:8],ans[7:0]};
    row_B <= {"Time: ",timer[0],timer[1],timer[2],timer[3],timer[4],timer[5],timer[6]," ms"};
  end else begin
    row_A<="Cracking        ";
    row_B<="Password        ";
  end
end

endmodule

