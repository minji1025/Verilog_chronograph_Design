`timescale 1ns / 1ps

module FNDController(
    input clk,
    input reset,
    input [6:0] digit_Front,
    input [6:0] digit_Back,
    output [7:0] fndFont,
    output [3:0] fndCom 
);

  wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
  wire [3:0] w_digit;
  wire [2:0] w_count;
  wire [3:0] w_dp;
  wire w_clk_1khz;

  clkDiv #(
      .MAX_COUNT(100_000)
  ) U_ClkDiv (
      .clk  (clk),
      .reset(reset),
      .o_clk(w_clk_1khz)
  );

  counter #(
      .MAX_COUNT(5)
  ) U_Counter_2bit (
      .clk(w_clk_1khz),
      .reset(reset),
      .count(w_count)  //0123
  );

  counter_dp #(
    .MAX_COUNT(1000)
    ) U_counter_dp (
    .clk(w_clk_1khz), 
    .reset(reset),
    .o_dp(w_dp)
);

  decoder_2x4 U_Decoder_2X4 (
      .fndSet(w_count),
      .fndCom(fndCom)
  );

  digitSplitter_time U_DigitSplitter_sec (
      .i_digit(digit_Front),
      .o_digit_1(w_digit_1),
      .o_digit_10(w_digit_10)
  );
  digitSplitter_time U_DigitSplitter_min (
      .i_digit(digit_Back),
      .o_digit_1(w_digit_100),
      .o_digit_10(w_digit_1000)
  );

  mux U_MUX_4X1_time (
      .sel(w_count),
      .x0 (w_digit_1),
      .x1 (w_digit_10),
      .x2 (w_digit_100),
      .x3 (w_digit_1000),
      .x4 (w_dp),
      .y  (w_digit)
  );

  BCDtoSEG U_BcdToSeg (
      .bcd(w_digit), 
      .seg(fndFont)
  );

endmodule

module digitSplitter_time (
    input  [6:0] i_digit,
    output [3:0] o_digit_1,
    output [3:0] o_digit_10
);

  assign o_digit_1 = i_digit % 10;
  assign o_digit_10 = i_digit / 10 % 10;

endmodule

module mux (
    input [2:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    input [3:0] x4,
    output reg [3:0] y
);

  always @(*) begin  //* :always 문안에 있는 모든 변수에 대해
    case (sel)
        3'b000 : y = x0;
        3'b001 : y = x1;
        3'b010 : y = x2;
        3'b011 : y = x3;
        3'b100 : y = x4;
        default y = x0;
    endcase
  end

endmodule


module BCDtoSEG (
    input [3:0] bcd,
    output reg [7:0] seg  //default output wire [7:0] seg
);

  always @(bcd) begin
    case (bcd)
      4'h0: seg = 8'hc0;
      4'h1: seg = 8'hf9;
      4'h2: seg = 8'ha4;
      4'h3: seg = 8'hb0;
      4'h4: seg = 8'h99;
      4'h5: seg = 8'h92;
      4'h6: seg = 8'h82;
      4'h7: seg = 8'hf8;
      4'h8: seg = 8'h80;
      4'h9: seg = 8'h90;
      
      4'ha: seg = 8'h7f;
      4'hb: seg = 8'hff;

      4'hc: seg = 8'hc6;
      4'hd: seg = 8'ha1;
      4'he: seg = 8'h86;
      4'hf: seg = 8'h8e;
      default: seg = 8'hff;
    endcase
  end
endmodule

module decoder_2x4 (
    input [2:0] fndSet,
    output reg [3:0] fndCom
);
  always @(fndSet) begin
    case (fndSet)
      3'h0: fndCom = 4'b1110;
      3'h1: fndCom = 4'b1101;
      3'h2: fndCom = 4'b1011;
      3'h3: fndCom = 4'b0111;
      3'h4: fndCom = 4'b1011;
      default: fndCom = 4'b1111;
    endcase
  end
endmodule

module counter #(
    parameter MAX_COUNT = 4
) (
    input clk,
    input reset,
    output [$clog2(MAX_COUNT)- 1:0] count  //0123
);

  reg [$clog2(MAX_COUNT)-1:0] counter = 0;
  assign count = counter;

  always @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      counter <= 0;
    end else begin
      if (counter == MAX_COUNT - 1) begin
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end
  end
endmodule

module counter_dp #(parameter MAX_COUNT = 0)(
    input clk, 
    input reset,
    output reg [3:0] o_dp
);
    reg [$clog2(MAX_COUNT)-1:0] count;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            count <= 0;
        end else begin
            if(count == (MAX_COUNT-1)) begin
                count <= 0;
            end else begin
                if(count < 500) o_dp <= 11;
                else o_dp <= 10;
                count <= count + 1;
            end
        end
    end
endmodule


module clkDiv #(
    parameter MAX_COUNT = 100
) (
    input  clk,
    input  reset,
    output o_clk
);
  reg [$clog2(MAX_COUNT)- 1:0] counter = 0;  //$clog2(100_000)- 1 == log_2(100000 - 1)
  reg r_tick = 0;
  assign o_clk = r_tick;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      counter <= 0;
    end else begin
      if (counter == (MAX_COUNT - 1)) begin
        counter <= 0;
        r_tick  <= 1'b1;
      end else begin
        counter <= counter + 1;
        r_tick  <= 1'b0;
      end
    end
  end

endmodule
