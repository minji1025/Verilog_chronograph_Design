`timescale 1ns / 1ps

module Timer (
    input        clk,
    input        reset,
    input        set_en,
    input        change_en,
    input        min_data_en,
    input        hour_data_en,
    output [6:0] ms_min,
    output [6:0] sec_hour
);

  wire w_tick;

  clkDiv #(
      .MAX_COUNT(1_000_000)
  ) U_ClkDiv_ms (  //1ms의 시간
      .clk  (clk),
      .reset(reset),
      .o_clk(w_tick)
  );

  timecounter U_timecounter (
      .clk         (clk),
      .tick        (w_tick),
      .reset       (reset),
      .set_en      (set_en),
      .change_en   (change_en),     //time hour:min <-> sec:ms change
      .min_data_en (min_data_en),
      .hour_data_en(hour_data_en),
      .ms_min      (ms_min),        //FND min <-> ms 위치 Data
      .sec_hour    (sec_hour)       //FND hour <-> sec 위치 Data
  );

endmodule

module timecounter (
    input        clk,
    input        tick,
    input        reset,
    input        set_en,
    input        change_en,     //time hour:min <-> sec:ms change
    input        min_data_en,
    input        hour_data_en,
    output [6:0] ms_min,        //FND min <-> ms 위치 Data
    output [6:0] sec_hour       //FND hour <-> sec 위치 Data
);

  reg [6:0] sec_reg, min_reg, ms_reg, hour_reg;
  reg [6:0] sec_next, min_next, ms_next, hour_next;

  assign ms_min   = change_en ? ms_reg : min_reg;  //change에 따라 Data 결졍
  assign sec_hour = change_en ? sec_reg : hour_reg;  //change에 따라 Data 결졍
  //삼항 연산자 참조

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      ms_reg   <= 0;
      sec_reg  <= 0;
      min_reg  <= 0;
      hour_reg <= 0;
    end else begin
      ms_reg   <= ms_next;
      sec_reg  <= sec_next;
      min_reg  <= min_next;
      hour_reg <= hour_next;
    end
  end

  always @(*) begin
    ms_next   = ms_reg;
    sec_next  = sec_reg;
    min_next  = min_reg;
    hour_next = hour_reg;
    if (tick & set_en) begin
      if (ms_next >= 100) begin
        sec_next = sec_reg + 1;
        ms_next  = 0;
      end else if (sec_next >= 60) begin
        min_next = min_reg + 1;
        sec_next = 0;
      end else if (min_next >= 59) begin
        hour_next = hour_reg + 1;
        min_next  = 0;
      end else if (hour_next == 24) begin
        hour_next = 0;
      end else begin
        ms_next = ms_reg + 1;
      end
    end else if (!set_en) begin
      if (min_data_en) begin
        if (min_next >= 60) begin
          hour_next = hour_reg + 1;
          min_next  = 0;
        end else begin
          min_next = min_reg + 1;
        end
      end
      else if (hour_data_en) begin
        if (hour_next == 24) begin
          hour_next = 0;
        end else begin
          hour_next = hour_reg + 1;
        end
      end
    end
  end

endmodule
