class transaction;

  rand bit oper;
  bit wr_en;
  bit rd_en;
  rand logic [7:0] data_in;
  bit full;
  bit empty;
  logic [7:0] data_out;

endclass

class generator;

  transaction tr;
  mailbox #(transaction) mbx; // to driver

  int count;

  event next;
  event done;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    for (int i=0; i<count; i++) begin
        tr = new();
        assert(tr.randomize() with {oper == 1'b1;})
        else $error("Randomization of transaction failed!");
        mbx.put(tr);
        @(next);
    end
    for (int i=0; i<count; i++) begin
        tr = new();
        assert(tr.randomize() with {oper == 1'b0;})
        else $error("Randomization of transaction failed!");
        mbx.put(tr);
        @(next);
    end
    -> done;
  endtask
endclass

class driver;
  virtual fifo_if f_if; // to dut
  transaction tr;
  mailbox #(transaction) mbx; // from generator

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task reset();
    @(posedge f_if.clk);
    f_if.rst <= 1'b1;
    f_if.wr_en <= 1'b0;
    f_if.rd_en <= 1'b0;
    f_if.data_in <= 8'h00;
    repeat (5) @(posedge f_if.clk);
    f_if.rst <= 1'b0;
    $display("[DRV] Reset asserted");
  endtask

  task write(transaction tr);
    @(posedge f_if.clk);
    f_if.rst   <= 1'b0;
    f_if.wr_en <= 1'b1;
    f_if.rd_en <= 1'b0;
    f_if.data_in <= tr.data_in;
    @(posedge f_if.clk);
    f_if.wr_en <= 1'b0;
    $display("[DRV] Data Write: 0x%02h", tr.data_in);
    @(posedge f_if.clk);
  endtask

  task read();
    @(posedge f_if.clk);
    f_if.rst   <= 1'b0;
    f_if.wr_en <= 1'b0;
    f_if.rd_en <= 1'b1;
    @(posedge f_if.clk);
    f_if.rd_en <= 1'b0;
    $display("[DRV] Data Read");
    @(posedge f_if.clk);
  endtask

  task run();
    forever begin
        mbx.get(tr);
        if (tr.oper)
          write(tr);
        else
          read();
    end
  endtask
endclass

class monitor;
  virtual fifo_if f_if; // from dut
  transaction tr;
  mailbox #(transaction) mbx; // to scoreboard

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      tr = new();

      repeat (2) @(posedge f_if.clk);
      tr.wr_en    = f_if.wr_en;
      tr.rd_en    = f_if.rd_en;
      tr.data_in  = f_if.data_in;
      tr.full     = f_if.full;
      tr.empty    = f_if.empty;

      @(posedge f_if.clk);
      tr.data_out = f_if.data_out;

      mbx.put(tr);
      $display("[MON] : wr_en:%0d rd_en:%0d data_in:0x%02h data_out:0x%02h full:%0d empty:%0d", tr.wr_en, tr.rd_en, tr.data_in, tr.data_out, tr.full, tr.empty);
    end
  endtask
endclass

class scoreboard;
  transaction tr;
  mailbox #(transaction) mbx; // from monitor

  event next; // to generator

  logic [7:0] data_queue [$];
  logic [7:0] temp_data;
  int error_cnt = 0;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
        mbx.get(tr);
        if(tr.wr_en) begin
            if(!tr.full) begin
                data_queue.push_back(tr.data_in);
              $display("[SCO] : Data stored in queue :0x%02h, queue size: %0d", tr.data_in, $size(data_queue));
            end else
              $display("[SCO] : FIFO is full");
        end 

        if(tr.rd_en) begin
            if(!tr.empty) begin
                temp_data = data_queue.pop_front();
                if (tr.data_out == temp_data)
                  $display("[SCO] : Data matched");
                else begin
                  $display("[SCO] : Data mismatched");
                  error_cnt++;
                end
            end else
              $display("[SCO] : FIFO is empty");
        end

        ->next;
    end
  endtask
endclass

class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;

  mailbox #(transaction) gdm;
  mailbox #(transaction) msm;
  event next_gs;
  
  virtual fifo_if f_if;

  function new(virtual fifo_if f_if);
    gdm = new();
    gen = new(gdm);
    drv = new(gdm);

    msm = new();
    mon = new(msm);
    sco = new(msm);

    this.f_if = f_if;
    drv.f_if = this.f_if;
    mon.f_if = this.f_if;

    gen.next = next_gs;
    sco.next = next_gs;
  endfunction

  task pre_test();
    drv.reset();
  endtask

  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask

  task post_test();
    wait(gen.done.triggered);
    if(sco.error_cnt > 0)
      $display("Test Failed! Error count; %0d", sco.error_cnt);
    else
      $display("Test Passed!");
    $finish();
  endtask

  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass

module tb;
  // interface
  fifo_if f_if();

  // dut
  fifo i_fifo(.clk(f_if.clk),
              .rst(f_if.rst),
              .wr_en(f_if.wr_en),
              .rd_en(f_if.rd_en),
              .data_in(f_if.data_in),
              .data_out(f_if.data_out),
              .full(f_if.full),
              .empty(f_if.empty));
  
  // initialize
  initial f_if.clk <= 0;

  // generate clock
  always #10 f_if.clk <= ~f_if.clk;

  // setup tb and run test
  environment env;

  initial begin
    env = new(f_if);
    env.gen.count = 16;
    env.run();
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars;
  end

endmodule