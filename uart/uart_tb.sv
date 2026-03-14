`include "uvm_macros.svh"
import uvm_pkg::*;

// Transaction class
class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);

  typedef enum bit { WRITE = 1'b0, READ = 1'b1 } op_t;
  rand op_t op;
  // RX
  rand logic [7:0] rx_data;
  rand logic rx;
  logic [7:0] dout_rx;
  logic done_rx;
  // TX
  rand logic [7:0] din_tx;
  rand logic newd;
  logic [7:0] tx_data;
  logic tx;
  logic done_tx;

  function new(string inst="transaction");
    super.new(inst);
  endfunction

  constraint c_op {
    op dist { WRITE := 1, READ := 1 };
  }

  constraint c_op_imp {
    op == WRITE -> { 
        newd    == 1'b1;
        rx_data == 8'h00; 
        rx      == 1'b1;
    }

    op == READ -> {
        newd   == 1'b0;
        din_tx == 8'h00;
        rx     == 1'b0; 
    }
  }
endclass

class base_seq extends uvm_sequence #(transaction);
  `uvm_object_utils(base_seq);

  transaction tx;
  int count;

  function new(string inst="base_seq");
    super.new(inst);
  endfunction

  virtual task body();
    repeat (count) begin
        tx = transaction::type_id::create("tx");
        start_item(tx);
        assert(tx.randomize()) begin
          if (tx.op == transaction::WRITE)
            `uvm_info(get_name(), $sformatf("WRITE OP, newd: %0d, tx.din_tx: %02h (%08b)", tx.newd, tx.din_tx, tx.din_tx), UVM_NONE)
          else
            `uvm_info(get_name(), $sformatf("READ OP, rx_data: %02h (%08b)", tx.rx_data, tx.rx_data), UVM_NONE)
        end else
          `uvm_error(get_name(), "Randomization failed")
        finish_item(tx);
    end
  endtask
endclass

class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver);

  transaction tx;
  virtual uart_if.rx_drv u_if_rx;
  virtual uart_if.tx_drv u_if_tx;

  function new(string path="driver", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual uart_if.rx_drv)::get(this, "", "u_if_rx", u_if_rx))
      `uvm_error(get_name(), "Getting RX interface failed");
    if(!uvm_config_db#(virtual uart_if.tx_drv)::get(this, "", "u_if_tx", u_if_tx))
      `uvm_error(get_name(), "Getting TX interface failed");
    tx = transaction::type_id::create("tx");
  endfunction

  task reset_dut();
    @(posedge u_if_tx.clk);
    u_if_tx.rst    <= 1'b1;
    u_if_tx.cb_tx_drv.din_tx <= 8'h00;
    u_if_tx.cb_tx_drv.newd   <= 1'b0;

    u_if_rx.cb_rx_drv.rx  <= 1'b1;
    repeat (5) @(posedge u_if_tx.clk);
    u_if_tx.rst    <= 1'b0;
  endtask

  task tx_send(transaction tx);
    // Start transfer
    @(u_if_tx.cb_tx_drv);
    u_if_tx.cb_tx_drv.newd   <= tx.newd;
    u_if_tx.cb_tx_drv.din_tx <= tx.din_tx;

    // Deassert newd
    @(u_if_tx.cb_tx_drv);
    u_if_tx.cb_tx_drv.newd   <= 1'b0;

    // Wait for done_tx
    @(posedge u_if_tx.cb_tx_drv.done_tx);
  endtask

  task rx_receive(transaction tx);
    // Invoke rx
    @(u_if_rx.cb_rx_drv);
    u_if_rx.cb_rx_drv.rx <= tx.rx;

    // Start sending data
    for (int i=0; i<=7; i++) begin
      @(u_if_rx.cb_rx_drv);
      u_if_rx.cb_rx_drv.rx <= tx.rx_data[i];
    end

    // Deassert rx
    @(u_if_rx.cb_rx_drv);
    u_if_rx.cb_rx_drv.rx <= 1'b1;

    // Wait for done_rx
    @(posedge u_if_rx.cb_rx_drv.done_rx);
  endtask

  virtual task run_phase(uvm_phase phase);
    reset_dut();
    forever begin
      seq_item_port.get_next_item(tx);
        if(tx.op == transaction::WRITE)
          tx_send(tx);
        else
          rx_receive(tx);
      seq_item_port.item_done();
    end
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);

  virtual uart_if.rx_mon u_if_rx;
  virtual uart_if.tx_mon u_if_tx;
  uvm_analysis_port#(transaction) port; 

  function new(string path="monitor", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual uart_if.rx_mon)::get(this, "", "u_if_rx", u_if_rx))
      `uvm_error(get_name(), "Getting RX interface failed");
    if(!uvm_config_db#(virtual uart_if.tx_mon)::get(this, "", "u_if_tx", u_if_tx))
      `uvm_error(get_name(), "Getting TX interface failed");
    port = new("port", this);
  endfunction

  task tx_mon();
    forever begin
        transaction tx;
        tx = transaction::type_id::create("tx");

        @(negedge u_if_tx.cb_tx_mon.tx);
        tx.din_tx = u_if_tx.cb_tx_mon.din_tx;
        tx.newd   = u_if_tx.cb_tx_mon.newd;
        tx.op     = transaction::WRITE;

        for(int i=0; i<=7; i++) begin
            @(u_if_tx.cb_tx_mon);
            tx.tx_data[i] = u_if_tx.cb_tx_mon.tx;
        end

        @(posedge u_if_tx.cb_tx_mon.done_tx);
        `uvm_info(get_name(), $sformatf("WRITE OP: newd: %0d, din_tx: %02h, tx_data: %02h", tx.newd, tx.din_tx, tx.tx_data), UVM_NONE);
        port.write(tx);
    end
  endtask

  task rx_mon();
    forever begin
        transaction tx;
        tx = transaction::type_id::create("tx");

        @(negedge u_if_rx.cb_rx_mon.rx);
        tx.op = transaction::READ;
        
        for(int i=0; i<=7; i++) begin
            @(u_if_rx.cb_rx_mon);
            tx.rx_data[i] = u_if_rx.cb_rx_mon.rx;
        end

        @(posedge u_if_rx.cb_rx_mon.done_rx);
        tx.dout_rx = u_if_rx.cb_rx_mon.dout_rx;
        `uvm_info(get_name(), $sformatf("READ OP: dout_rx: %02h, rx_data: %02h", tx.dout_rx, tx.rx_data), UVM_NONE);
        port.write(tx);
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    fork
        tx_mon();
        rx_mon();
    join_none
  endtask
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);

  uvm_analysis_imp#(transaction, scoreboard) imp; 

  function new(string path="scoreboard", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction

  function void write(transaction tx);
    if (tx.op == transaction::WRITE) begin
        if (tx.tx_data == tx.din_tx)
          `uvm_info(get_name(), "Test Passed!", UVM_NONE)
        else 
          `uvm_info(get_name(), "Test Failed!", UVM_NONE)

        `uvm_info(get_name(), $sformatf("din_tx: %02h, tx_data: %02h", tx.din_tx, tx.tx_data), UVM_NONE);
    end else begin
        if (tx.dout_rx == tx.rx_data)
          `uvm_info(get_name(), "Test Passed!", UVM_NONE)
        else 
          `uvm_info(get_name(), "Test Failed!", UVM_NONE)

        `uvm_info(get_name(), $sformatf("rx_data: %02h, dout_rx: %02h", tx.rx_data, tx.dout_rx), UVM_NONE);
    end
  endfunction
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent);

  uvm_sequencer#(transaction) sqr;
  driver drv;
  monitor mon;
  
  function new(string path="agent", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = uvm_sequencer#(transaction)::type_id::create("sqr", this);
    drv = driver::type_id::create("drv", this);
    mon = monitor::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass

class environment extends uvm_env;
  `uvm_component_utils(environment);

  agent agt;
  scoreboard scb;

  function new(string path="environment", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = agent::type_id::create("agt", this);
    scb = scoreboard::type_id::create("scb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.port.connect(scb.imp);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);

  environment env;
  base_seq seq;

  function new(string path="test", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = environment::type_id::create("env", this);
    seq = base_seq::type_id::create("seq", this);
    seq.count = 10;
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.agt.sqr);
    phase.drop_objection(this);
    #100;
  endtask
endclass

module tb;

  // if
  uart_if u_if();

  // uart top
  uart_top#(1_000_000, 9600) i_uart_top (.clk(u_if.clk),
                                         .rst(u_if.rst),
                                         .rx(u_if.rx),
                                         .din_tx(u_if.din_tx),
                                         .newd(u_if.newd),
                                         .tx(u_if.tx),
                                         .dout_rx(u_if.dout_rx),
                                         .done_tx(u_if.done_tx),
                                         .done_rx(u_if.done_rx));

  // generate clock
  initial begin
    u_if.clk <= 1'b0;
  end

  always #10 u_if.clk <= ~u_if.clk;

  // run test
  initial begin
    uvm_config_db#(virtual uart_if.tx_drv)::set(null, "*", "u_if_tx", u_if);
    uvm_config_db#(virtual uart_if.tx_mon)::set(null, "*", "u_if_tx", u_if);
    uvm_config_db#(virtual uart_if.rx_drv)::set(null, "*", "u_if_rx", u_if);
    uvm_config_db#(virtual uart_if.rx_mon)::set(null, "*", "u_if_rx", u_if);
    uvm_config_db#(int)::set(null, "*", "count", 10);
    run_test("test");
  end

  // waveform
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
  assign u_if.uclk_tx = i_uart_top.i_uart_tx.uclk;
  assign u_if.uclk_rx = i_uart_top.i_uart_rx.uclk;

endmodule