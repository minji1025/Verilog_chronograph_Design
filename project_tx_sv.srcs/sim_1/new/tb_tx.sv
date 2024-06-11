`timescale 1ns / 1ps `timescale 1ns / 1ps


interface uart_interface;
  logic clk;
  logic reset;
  logic start;
  logic [7:0] tx_data;
  logic tx;
  logic tx_done;
endinterface

class transaction;
  rand logic [7:0] tx_data;
  logic start;
  logic tx;

  function display(string name);
    $display("[%s] tx_data: %x, tx: %d ", name, tx_data, tx);
  endfunction  //new()
endclass  //className

class generator;
  transaction trans;
  mailbox #(transaction) gen2drv_mbox;
  event gen_next_event;
  int tcount;
  function new(mailbox#(transaction) gen2drv_mbox, event gen_next_event);
    this.gen2drv_mbox = gen2drv_mbox;
    this.gen_next_event = gen_next_event;
    tcount = 0;
  endfunction  //new()

  task run(int count);
    repeat (count) begin
      if (tcount % 10 == 0) begin
        trans = new();
        assert (trans.randomize())
        else $error("[GEN] trans.randomize() error!");
        trans.display("GEN");
      end
      gen2drv_mbox.put(trans);
      tcount++;
      @(gen_next_event);
    end
  endtask
endclass


class driver;
  transaction trans;
  mailbox #(transaction) gen2drv_mbox;
  virtual uart_interface uart_intf;

  integer count;

  function new(virtual uart_interface uart_intf, mailbox#(transaction) gen2drv_mbox);
    this.uart_intf = uart_intf;
    this.gen2drv_mbox = gen2drv_mbox;
    count = 0;
  endfunction

  task reset();
    uart_intf.tx_data <= 0;
    uart_intf.start   <= 1'b1;
    uart_intf.reset   <= 1'b1;
    repeat (5) @(posedge uart_intf.clk);
    uart_intf.reset <= 1'b0;
  endtask

  task run();
    forever begin
      gen2drv_mbox.get(trans);
      if (count % 10 == 0) begin
        uart_intf.start = 1'b1;
        trans.display("DRV");
        $display("START");
        uart_intf.tx_data = trans.tx_data;
        @(posedge uart_intf.clk);
        uart_intf.start = 1'b0;
      end else if (count % 10 == 9) begin
        $display("STOP");
      end else begin
        uart_intf.tx_data = trans.tx_data;
      end
      count++;
    end
  endtask
endclass

class monitor;
  virtual uart_interface uart_intf;
  mailbox #(transaction) mon2scb_mbox;
  transaction trans;
  //event drv_next_event;

  function new(virtual uart_interface uart_intf, mailbox#(transaction) mon2scb_mbox);
    this.uart_intf = uart_intf;
    this.mon2scb_mbox = mon2scb_mbox;
  endfunction  //new()
  task run();
    forever begin
      trans = new();
      @(posedge uart_intf.clk);
      trans.tx_data = uart_intf.tx_data;
      repeat (32)
        @(posedge uart_intf.clk); //baudrate (4) * br_cnt(16) = 64 -> 중간 지점을 위하여 @clk ->32
      trans.tx = uart_intf.tx;
      repeat (32) @(posedge uart_intf.clk);
      //$display("tx : %b", uart_intf.tx);
      mon2scb_mbox.put(trans);
      trans.display("MON");
    end
  endtask  //run
endclass  //monitor

class scoreboard;
  mailbox #(transaction) mon2scb_mbox;
  transaction trans;
  event gen_next_event;

  reg [7:0] tx_data;

  int total_cnt, pass_cnt, fail_cnt;
  function new(mailbox#(transaction) mon2scb_mbox, event gen_next_event);
    this.mon2scb_mbox = mon2scb_mbox;
    this.gen_next_event = gen_next_event;
    total_cnt = 0;
    pass_cnt = 0;
    fail_cnt = 0;
  endfunction

  task run();
    forever begin
      mon2scb_mbox.get(trans);
      //data = {data[6:0],trans.out};
      tx_data = {trans.tx, tx_data[7:1]};  //DATA 9번 넣어지는데 Start bit 짤림 
      trans.display("SCB");
      if (total_cnt % 10 == 8) begin
        if (trans.tx_data == tx_data) begin
          $display("--> PASS %b==%b //  %d", trans.tx_data, tx_data, total_cnt);
          pass_cnt++;
        end else begin
          $display("--> Fail %b==%b  //  %d", trans.tx_data, tx_data, total_cnt);
          fail_cnt++;
        end
      end
      if (total_cnt % 10 == 9) begin
        $display("IDLE");
      end
      ->gen_next_event;
      total_cnt++;
    end
  endtask
endclass



class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;

  event gen_next_event;

  mailbox #(transaction) gen2drv_mbox;
  mailbox #(transaction) mon2scb_mbox;

  function new(virtual uart_interface uart_intf);
    gen2drv_mbox = new();
    mon2scb_mbox = new();

    gen = new(gen2drv_mbox, gen_next_event);
    mon = new(uart_intf, mon2scb_mbox);
    drv = new(uart_intf, gen2drv_mbox);
    scb = new(mon2scb_mbox, gen_next_event);
  endfunction
  task report();
    $display("=======================");
    $display("==Final Repoert==");
    $display("=======================");
    $display("Total test:%d", scb.total_cnt);
    $display("Pass test: %d", scb.pass_cnt);
    $display("Fail test: %d", scb.fail_cnt);
    $display("=======================");
    $display("test bench is finished");
    $display("=======================");
  endtask

  task pre_run();
    drv.reset();
  endtask

  task run();
    fork
      gen.run(100);
      drv.run();
      mon.run();
      scb.run();
    join_any
    report();
    #10 $finish;
  endtask
  task run_test();
    pre_run();
    run();
  endtask
endclass




module tb_tx ();
  environment env;
  uart_interface uart_intf ();

  uart dut (
      .clk(uart_intf.clk),
      .reset(uart_intf.reset),
      .start(uart_intf.start),
      .tx_data(uart_intf.tx_data),
      .tx(uart_intf.tx),
      .tx_done(uart_intf.tx_done),
      .rx(),
      .rx_data(),
      .rx_done()
  );

  always #5 uart_intf.clk = ~uart_intf.clk;

  initial begin
    uart_intf.clk = 1'b0;
  end

  initial begin
    env = new(uart_intf);
    env.run_test();
  end

endmodule

