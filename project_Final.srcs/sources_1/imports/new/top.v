`timescale 1ns / 1ps

module top (
    input        clk,
    input        reset,
    input        btn_C,    //Mode 변경
    input        btn_R,    // Clock Set, Stopwatch RunStop
    input        btn_L,    // ClockSet Minup, Stopwatch Clear
    input        btn_U,    //ClockSet Houp , Clock Change
    input        rx,
    output       tx,
    output [7:0] fndFont,
    output [3:0] fndCom
);

  wire w_sel;
  wire w_change;
  wire w_mode_sel, w_change_en, w_set_en, w_min_data_en, w_hour_data_en, w_run_stop_en, w_clear;
  wire w_rx_empty;
  wire [7:0] w_rx_data;
  wire [6:0] w_fndFront, w_fndBack;

  uart_fifo U_UART (
      .clk(clk),
      .reset(reset),
      .tx_en(~w_rx_empty),
      .tx_data(w_rx_data),
      .tx_full(),
      .tx(tx),
      .rx(rx),
      .rx_en(~w_rx_empty),
      .rx_data(w_rx_data),
      .rx_empty(w_rx_empty)
  );

  controlUnit U_ControlUnit (
      .clk(clk),
      .reset(w_reset),
      .btn_C(w_btn_C),  //Mode 변경
      .btn_R(w_btn_R),  // Clock Set, Stopwatch RunStop
      .btn_L(w_btn_L),  // ClockSet Minup, Stopwatch Clear
      .btn_U(w_btn_U),  //ClockSet Houp , Clock Change
      .Uart_rx_data(w_rx_data),  //UART RX
      .mode_sel(w_mode_sel),
      .change_en(w_change_en),
      .set_en(w_set_en),
      .min_data_en(w_min_data_en),
      .hour_data_en(w_hour_data_en),
      .run_stop_en(w_run_stop_en),
      .clear(w_clear)
  );

  dataUnit U_dataUnit (
      .clk(clk),
      .reset(w_reset),
      .mode_sel(w_mode_sel),
      .change_en(w_change_en),
      .set_en(w_set_en),
      .min_data_en(w_min_data_en),
      .hour_data_en(w_hour_data_en),
      .run_stop_en(w_run_stop_en),
      .clear(w_clear),
      .fndFront(w_fndFront),
      .fndBack(w_fndBack)
  );

  FNDController U_FNDController (
      .clk(clk),
      .reset(reset),
      .digit_Front(w_fndFront),
      .digit_Back(w_fndBack),
      .fndFont(fndFont),
      .fndCom(fndCom)
  );

  Button U_btn_C (
      .clk(clk),
      .in (btn_C),
      .out(w_btn_C)
  );
  Button U_btn_L (
      .clk(clk),
      .in (btn_L),
      .out(w_btn_L)
  );

  Button U_btn_R (
      .clk(clk),
      .in (btn_R),
      .out(w_btn_R)
  );
  Button U_btn_U (
      .clk(clk),
      .in (btn_U),
      .out(w_btn_U)
  );
  Button U_btn_D (
      .clk(clk),
      .in (reset),
      .out(w_reset)
  );
endmodule
