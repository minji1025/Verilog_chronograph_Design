`timescale 1ns / 1ps

module uart_fifo (
    input        clk,
    input        reset,
    input        tx_en,
    input  [7:0] tx_data,
    output       tx_full,
    output       tx,
    input        rx,
    input        rx_en,
    output [7:0] rx_data,
    output       rx_empty
);

  wire w_tx_fifo_empty, w_tx_done, w_rx_done;
  wire [7:0] w_tx_fifo_rdata, w_rx_data;

  uart U_UART (
      .clk(clk),
      .reset(reset),
      .start(~w_tx_fifo_empty),
      .tx_data(w_tx_fifo_rdata),
      .tx(tx),
      .tx_done(w_tx_done),
      .rx(rx),
      .rx_data(w_rx_data),
      .rx_done(w_rx_done)
  );

  FIFO #(
      .ADDR_WIDTH(10),
      .DATA_WIDTH(8)
  ) U_Tx_FIFO (
      .clk  (clk),
      .reset(reset),
      .wr_en(tx_en),
      .full (tx_full),
      .wdata(tx_data),
      .rd_en(w_tx_done),
      .empty(w_tx_fifo_empty),
      .rdata(w_tx_fifo_rdata)
  );

  FIFO #(
      .ADDR_WIDTH(10),
      .DATA_WIDTH(8)
  ) U_Rx_FIFO (
      .clk  (clk),
      .reset(reset),
      .wr_en(w_rx_done),
      .full (),
      .wdata(w_rx_data),
      .rd_en(rx_en),
      .empty(rx_empty),
      .rdata(rx_data)
  );

endmodule
