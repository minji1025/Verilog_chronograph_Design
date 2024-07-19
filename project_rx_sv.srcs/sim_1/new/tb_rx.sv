`timescale 1ns / 1ps


interface receiver_interface;
    logic clk;
    logic reset;
    logic rx;
    logic rx_done;
    logic [7:0] rx_data;
endinterface  //reg_interface


class transaction;
    rand logic rx;
    logic [7:0] rx_data;
    logic rx_done;

    task display(string name);
        $display("[%s] rx: %x, rx_data: %x", name, rx, rx_data);
    endtask
endclass  //transaction


class generator;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_event);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int count);
        repeat (count) begin
            trans = new(); // repeat 할때마다 trans를 생성해주고 transaction에 연결해주겠다.
            assert (trans.randomize())
            else $error("[GEN] trans.randomize() error!");
            gen2drv_mbox.put(trans);
            trans.display("GEN");
            if (gen_next_event == 1'b1) begin
                $display("done");
            end
            @(gen_next_event);
        end
    endtask  //
endclass  //generator


class driver;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual receiver_interface receiver_intf;

    integer counter;

    function new(virtual receiver_interface receiver_intf,
                 mailbox#(transaction) gen2drv_mbox);
        this.receiver_intf = receiver_intf;
        this.gen2drv_mbox = gen2drv_mbox;

        counter = 0;
    endfunction  //new()



    task reset();
        receiver_intf.rx <= 1'b0;
        receiver_intf.reset <= 1'b1;
        repeat (5) @(posedge receiver_intf.clk);
        receiver_intf.reset <= 1'b0;
        repeat (5) @(posedge receiver_intf.clk);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(trans);
            if (counter % 10 == 0) begin
                receiver_intf.rx <= 1'b0;  // input
                $display("START");
            end else if (counter % 10 == 9) begin
                receiver_intf.rx <= 1'b1;
                $display("END");
            end else begin
                receiver_intf.rx <= trans.rx;
            end
            trans.display("DRV");
            counter++;
        end
    endtask
endclass  //driver



class monitor;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    virtual receiver_interface receiver_intf;

    function new(virtual receiver_interface receiver_intf,
                 mailbox#(transaction) mon2scb_mbox);
        this.receiver_intf = receiver_intf;
        this.mon2scb_mbox  = mon2scb_mbox;
    endfunction  //new()

    task run();
        forever begin
            trans = new();
            repeat (32) @(posedge receiver_intf.clk);
            trans.rx = receiver_intf.rx;
            trans.rx_data = receiver_intf.rx_data;
            trans.rx_done = receiver_intf.rx_done;
            repeat (32) @(posedge receiver_intf.clk);
            mon2scb_mbox.put(trans);
            trans.display("MON");
        end
    endtask
endclass  //monitor

class scoreboard;
    mailbox #(transaction) mon2scb_mbox;
    transaction trans;
    event gen_next_event;


    int total_cnt, pass_cnt, fail_cnt;
    int br_cnt;

    reg [7:0] scb_fifo[$:7];  // $ us queue (fifo). golden reference
    reg [7:0] scb_fifo_data;

    reg [7:0] data;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_event = gen_next_event;
        total_cnt = 0;
        pass_cnt = 0;
        fail_cnt = 0;
    endfunction  //new()


    task run();
        forever begin
            mon2scb_mbox.get(trans);

            if ((total_cnt % 10 > 0) && (total_cnt % 10 < 9)) begin
                data = {trans.rx, data[7:1]};
            end

            if (total_cnt % 10 == 9) begin
                trans.display("SCB");
                if (data == trans.rx_data) begin
                    $display(" ---> PASS! %x == %x // total_cnt : %d", data,
                             trans.rx_data, total_cnt);
                    pass_cnt++;
                end else begin
                    $display(" ---> FAIL! %x == %x // total_cnt : %d", data,
                             trans.rx_data, total_cnt);
                    fail_cnt++;
                end
            end
            total_cnt++;
            ->gen_next_event;
        end
    endtask
endclass  //scoreboard


class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    event gen_next_event;


    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    function new(virtual receiver_interface receiver_intf);
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, gen_next_event);
        drv = new(receiver_intf, gen2drv_mbox);
        mon = new(receiver_intf, mon2scb_mbox);
        scb = new(mon2scb_mbox, gen_next_event);
    endfunction

    task report();
        $display("========================");
        $display("==    Final Report    ==");
        $display("Total Test : %d", scb.total_cnt);
        $display("Pass Count : %d", scb.pass_cnt);
        $display("Fail Count : %d", scb.fail_cnt);
        $display("=========================");
        $display("test bench is finished!");
        $display("=========================");
    endtask

    task prev_run();
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
        prev_run();
        run();
    endtask
endclass



module tb_rx ();
    environment env;
    receiver_interface receiver_intf ();

    uart dut (
        .clk(receiver_intf.clk),
        .reset(receiver_intf.reset),
        .rx(receiver_intf.rx),
        .rx_done(receiver_intf.rx_done),
        .rx_data(receiver_intf.rx_data)
    );

    always #5 receiver_intf.clk = ~receiver_intf.clk;

    initial begin
        receiver_intf.clk = 1'b0;
    end

    initial begin
        env = new(receiver_intf);
        env.run_test();
    end
endmodule
