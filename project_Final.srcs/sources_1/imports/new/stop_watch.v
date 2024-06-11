`timescale 1ns / 1ps

module stop_watch (
    input        clk,
    input        reset,
    input        run_stop_en,
    input        clear,
    output [6:0] sec,
    output [6:0] min
);

  wire w_tick;
  clkDiv #(
      .MAX_COUNT(100_000_000) 
  ) U_ClkDiv_1Hz (
      .clk  (clk),
      .reset(reset),
      .o_clk(w_tick)
  );

  SWCounter U_SWCounter (
      .clk(clk),
      .tick(w_tick),
      .reset(reset),
      .run_stop_en(run_stop_en),
      .clear(clear),
      .sec(sec),
      .min(min)
  );


endmodule

module SWCounter (
    input        clk,
    input        tick,
    input        reset,
    input        run_stop_en,
    input        clear,
    output [6:0] sec,
    output [6:0] min
);

  reg [6:0] sec_reg, sec_next, min_reg, min_next;
  assign sec = sec_reg;
  assign min = min_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      sec_reg <= 0;
      min_reg <= 0;
    end else begin
      sec_reg <= sec_next;
      min_reg <= min_next;
    end
  end

  always @(*) begin
    sec_next = sec_reg;
    min_next = min_reg;
    if (clear) begin
      sec_next = 0;
      min_next = 0;
    end else if (tick & run_stop_en) begin
      if (sec_next >= 59) begin
        min_next = min_reg + 1;
        sec_next = 0;
      end else if (min_next == 60) begin
        min_next = 0;
      end else begin
        sec_next = sec_reg + 1;
      end
    end
  end


endmodule
