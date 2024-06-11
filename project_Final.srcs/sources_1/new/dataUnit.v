`timescale 1ns / 1ps


module dataUnit (
    input        clk,
    input        reset,
    input        mode_sel,
    input        set_en,
    input        change_en,
    input        min_data_en,
    input        hour_data_en,
    input        run_stop_en,
    input        clear,
    output [6:0] fndFront,
    output [6:0] fndBack
);

  // front:back 시계-> 시:분 <-> 초:ms/ StopWatch -> 분:초
  wire [6:0] w_timer_ms_min, w_timer_sec_hour;
  wire [6:0] w_stopwatch_sec, w_stopwatch_min;

  mux21 U_FNDFront (
      .sel(mode_sel),
      .x0 (w_timer_ms_min),
      .x1 (w_stopwatch_sec),
      .y  (fndFront)
  );
  mux21 U_FNDBack (
      .sel(mode_sel),
      .x0 (w_timer_sec_hour),
      .x1 (w_stopwatch_min),
      .y  (fndBack)
  );

  stop_watch U_stopWatch (
      .clk(clk),
      .reset(reset),
      .run_stop_en(run_stop_en),
      .clear(clear),
      .sec(w_stopwatch_sec),
      .min(w_stopwatch_min)
  );

  Timer U_Timer (
      .clk(clk),
      .reset(reset),
      .set_en(set_en),
      .change_en(change_en),
      .min_data_en(min_data_en),
      .hour_data_en(hour_data_en),
      .ms_min(w_timer_ms_min),
      .sec_hour(w_timer_sec_hour)
  );

endmodule

module mux21 (
    input sel,
    input [6:0] x0,
    input [6:0] x1,
    output reg [6:0] y
);

  always @(*) begin  //* :always 문안에 있는 모든 변수에 대해
    case (sel)
      1'b0: y = x0;
      1'b1: y = x1;
      default: y = x0;
    endcase
  end
endmodule
