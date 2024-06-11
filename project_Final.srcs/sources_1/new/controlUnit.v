`timescale 1ns / 1ps

module controlUnit(
    input        clk,
    input        reset,
    input        btn_C,         //Mode 변경
    input        btn_R,         // Clock Set, Stopwatch RunStop
    input        btn_L,         // ClockSet Minup, Stopwatch Clear
    input        btn_U,         //ClockSet Houp , Clock Change
    input  [7:0] Uart_rx_data,  //UART RX
    output       mode_sel,
    output       change_en,
    output       set_en,
    output       min_data_en,
    output       hour_data_en,
    output       run_stop_en,
    output       clear
);

  Contorll_Mode U_Mode (
      .clk(clk),
      .reset(reset),
      .btn_mode(btn_C),
      .Uart_rx_data(Uart_rx_data),
      .mode_sel(mode_sel)
  );

  Controll_Timer U_Timer (
      .clk(clk),
      .reset(reset),
      .mode_sel(mode_sel),
      .btn_change(btn_U),  //hour:min <-> sec :ms
      .btn_set(btn_R),     //Time Setting <-> RUN
      .btn_minup(btn_L),     //MINUp
      .btn_hourup(btn_U),    //HOURUP
      .Uart_rx_data(Uart_rx_data),
      .change_en(change_en),
      .set_en(set_en),
      .min_data_en(min_data_en),
      .hour_data_en(hour_data_en)
  );

  Controll_StopWatch U_StopWatch (
      .clk(clk),
      .reset(reset),
      .mode_sel(mode_sel),
      .btn_run_stop(btn_R),
      .btn_clear(btn_L),
      .Uart_rx_data(Uart_rx_data),
      .run_stop_en(run_stop_en),
      .clear(clear)
  );

endmodule

module Contorll_Mode (
    input        clk,
    input        reset,
    input        btn_mode,
    input  [7:0] Uart_rx_data,
    output       mode_sel
);

  parameter CLOCK = 1'b0, STOPWATCH = 1'b1;  //Mode 설정
  reg state, state_next;
  reg mode_sel_reg, mode_sel_next;

  assign mode_sel = mode_sel_reg;

  //state Register
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      state <= CLOCK;
      mode_sel_reg <= 1'b0;
    end else begin
      state <= state_next;
      mode_sel_reg <= mode_sel_next;
    end
  end

  //Next State Combinational Logic Circuit
  always @(*) begin
    state_next = state;
    case (state)
      CLOCK: begin
        if ((btn_mode == 1'b1) || (Uart_rx_data == "M")) state_next = STOPWATCH;
      end
      STOPWATCH: begin
        if ((btn_mode == 1'b1) || (Uart_rx_data == "M")) state_next = CLOCK;
      end
    endcase
  end

  //Output Combinational Logic Circuit
  //Moore Machine
  always @(*) begin
    mode_sel_next = mode_sel_reg;
    case (state)
      CLOCK: begin
        mode_sel_next = 1'b0;
      end
      STOPWATCH: begin
        mode_sel_next = 1'b1;
      end
    endcase
  end
endmodule

module Controll_StopWatch (
    input        clk,
    input        reset,
    input        mode_sel,
    input        btn_run_stop,
    input        btn_clear,
    input  [7:0] Uart_rx_data,
    output       run_stop_en,
    output       clear
);

  parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;
  reg [1:0] state, state_next;
  reg rs_en_reg, rs_en_next;
  reg clear_reg, clear_next;

  assign run_stop_en = rs_en_reg;
  assign clear = clear_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      state <= STOP;
      rs_en_reg <= 1'b0;
      clear_reg <= 1'b0;
    end else begin
      state <= state_next;
      rs_en_reg <= rs_en_next;
      clear_reg <= clear_next;
    end
  end

  always @(*) begin
    state_next = state;
    if (mode_sel) begin
      case (state)
        STOP: begin
          if ((btn_clear == 1'b1)||(Uart_rx_data == "C")) state_next = CLEAR;
          else if ((btn_run_stop == 1'b1)||(Uart_rx_data == "R")) state_next = RUN;
        end
        RUN: begin
          if ((btn_run_stop == 1'b1)||(Uart_rx_data == "S")) state_next = STOP;
        end
        CLEAR: begin
          state_next = STOP;
        end
      endcase
    end
  end

  //Output Combinational Logic Circuit
  //Moore Machine
  always @(*) begin
    rs_en_next = 1'b0;
    clear_next = 1'b0;
    case (state)
      STOP: begin
        rs_en_next = 1'b0;
      end
      RUN: begin
        rs_en_next = 1'b1;
      end
      CLEAR: begin
        clear_next = 1'b1;
      end
    endcase
  end

endmodule

module Controll_Timer (
    input        clk,
    input        reset,
    input        mode_sel,
    input        btn_change,    //hour:min <-> sec :ms
    input        btn_set,       //Time Setting <-> RUN
    input        btn_minup,     //MINUp
    input        btn_hourup,    //HOURUP
    input  [7:0] Uart_rx_data,
    output       change_en,
    output       set_en,
    output       min_data_en,
    output       hour_data_en
);

  parameter CLOCK = 1'b0, SET = 1'b1;
  parameter HOURMIN = 1'b0, SECMS = 1'b1;
  parameter NONE = 2'b00, MINUP = 2'b01, HOURUP = 2'b10;

  reg set_state, set_state_next;
  reg time_state, time_state_next;
  reg [1:0] up_state, up_state_next;

  reg change_en_reg, change_en_next;
  reg set_en_reg, set_en_next;
  reg min_data_reg, min_data_next;
  reg hour_data_reg, hour_data_next;

  assign change_en = change_en_reg;
  assign set_en    = set_en_reg;
  assign min_data_en  = min_data_reg;
  assign hour_data_en = hour_data_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      time_state    <= HOURMIN;
      change_en_reg <= 1'b0;
      set_state     <= CLOCK;
      set_en_reg    <= 1'b0;
      up_state      <= NONE;
      min_data_reg  <= 1'b0;
      hour_data_reg <= 1'b0;
    end else begin
      time_state    <= time_state_next;
      change_en_reg <= change_en_next;
      set_state     <= set_state_next;
      set_en_reg    <= set_en_next;
      up_state      <= up_state_next;
      min_data_reg  <= min_data_next;
      hour_data_reg <= hour_data_next;
    end
  end

  //Next time_state Combinational Logic Circuit
  always @(*) begin
    time_state_next = time_state;
    set_state_next  = set_state;
    up_state_next   = up_state;
    if (!mode_sel) begin  //mode_sel != 1 -> 0이므로 Clock 상태
      case (set_state)  //CLOCK, SET 이냐
        CLOCK: begin
          if ((btn_set == 1'b1)||(Uart_rx_data == "S")) set_state_next = SET;
          else begin
            case (time_state)
              HOURMIN: begin
                if ((btn_change == 1'b1)||(Uart_rx_data == "C")) time_state_next = SECMS;
              end
              SECMS: begin
                if ((btn_change == 1'b1)||(Uart_rx_data == "C")) time_state_next = HOURMIN;
              end
            endcase
          end
        end
        SET: begin
          if ((btn_set == 1'b1)||(Uart_rx_data == "S")) set_state_next = CLOCK;
          else begin
            case (up_state)
              NONE: begin
                if ((btn_minup == 1'b1)||(Uart_rx_data == "U")) up_state_next = MINUP;
                else if ((btn_hourup == 1'b1)||(Uart_rx_data == "H")) up_state_next = HOURUP;
              end
              MINUP: begin
                up_state_next = NONE;
              end
              HOURUP: begin
                up_state_next = NONE;
              end
            endcase
          end
        end
      endcase
    end
  end

  //Output Combinational Logic Circuit
  //Moore Machine
  always @(*) begin
    change_en_next = change_en_reg;
    set_en_next    = set_en_reg;
    min_data_next = min_data_reg;
    hour_data_next = hour_data_reg;
    case (set_state)  //CLOCK, SET 이냐
      CLOCK: begin
        set_en_next = 1'b1;
        case (time_state)
          HOURMIN: begin
            change_en_next = 1'b0;
          end
          SECMS: begin
            change_en_next = 1'b1;
          end
        endcase
      end
      SET: begin
        set_en_next = 1'b0;
        case (up_state)
          NONE: begin
            min_data_next  = 1'b0;
            hour_data_next = 1'b0;
          end
          MINUP: begin
            min_data_next = 1'b1;
          end
          HOURUP: begin
            hour_data_next = 1'b1;
          end
        endcase
      end
    endcase
  end

endmodule