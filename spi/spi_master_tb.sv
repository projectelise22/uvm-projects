`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  rand logic newd;
  rand logic [11:0] din;
  logic cs;
  logic mosi;
  logic [11:0] serial_data;

  function new(string inst="transaction");
    super.new(inst);
  endfunction

  `uvm_object_utils_begin(transaction)
  `uvm_field_int(newd, UVM_DEFAULT);
  `uvm_field_int(din, UVM_DEFAULT);
  `uvm_field_int(cs, UVM_DEFAULT);
  `uvm_field_int(mosi, UVM_DEFAULT);
  `uvm_object_utils_end
endclass

class base_seq extends uvm_sequence;
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
        assert(tx.randomize())
          `uvm_info(get_name(), $sformatf("newd: %0d, din: 0x%02h (%012b)", tx.newd, tx.din, tx.din), UVM_NONE)
        else 
          `uvm_error(get_name(), "Tx randomization failed");
        finish_item(tx);
    end
  endtask
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver);

  transaction tx;
  virtual spi_if.drv s_if;

  function new(string path="driver", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if.drv)::get(this, "", "s_if", s_if))
      `uvm_error(get_name(), "Getting interface failed");
      tx = transaction::type_id::create("tx");
  endfunction

  task reset_dut();
    @(posedge s_if.clk);
    s_if.rst  <= 1'b1;
    s_if.cb_drv.newd <= 1'b0;
    s_if.cb_drv.din  <= 8'h00;
    
    repeat (5) @(posedge s_if.clk);
    s_if.rst <= 1'b0;
  endtask

  virtual task run_phase(uvm_phase phase);
    reset_dut();
    forever begin
      seq_item_port.get_next_item(tx);
      @(s_if.cb_drv);
      s_if.cb_drv.newd <= tx.newd;
      s_if.cb_drv.din  <= tx.din;
      `uvm_info(get_name(), $sformatf("newd: %0d, din: 0x%02h (%012b)", tx.newd, tx.din, tx.din), UVM_NONE)
      
      // wait for cs to assert then deassert
      if (tx.newd) begin
        repeat (3) @(s_if.cb_drv);
        s_if.cb_drv.newd <= 1'b0;
        wait(s_if.cb_drv.cs == 1'b0);
        wait(s_if.cb_drv.cs == 1'b1);
      end
      seq_item_port.item_done();
    end
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);

  virtual spi_if.mon s_if;
  uvm_analysis_port#(transaction) port;

  function new(string path="monitor", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if.mon)::get(this, "", "s_if", s_if))
      `uvm_error(get_name(), "Getting interface failed");
      port = new("port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      transaction tx;
      tx = transaction::type_id::create("tx");

      // Wait for CS to go low (start of frame)
      @(negedge s_if.cb_mon.cs);

      // Wait **one SCLK** to start transaction one cycle after CS goes low
      @(s_if.cb_mon);

      // Capture static signals at transaction start
      tx.newd = s_if.cb_mon.newd;
      tx.din  = s_if.cb_mon.din;
      tx.cs   = s_if.cb_mon.cs;
      `uvm_info(get_name(), $sformatf("cs: %0d, newd: %0d, din: 0x%02h (%012b)", tx.cs, tx.newd, tx.din, tx.din), UVM_NONE)

      // Capture 12 serial bits, one per SCLK
      for (int i = 0; i <= 11; i++) begin
        tx.serial_data[i] = s_if.cb_mon.mosi;
        @(s_if.cb_mon);
      end

      // Write transaction after frame is complete
      port.write(tx);
    end
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
    if (tx.serial_data == tx.din) begin
      `uvm_info(get_name(), "Test Passed", UVM_NONE);
    end else begin
      `uvm_error(get_name(), "Test Failed");
    end
    
    `uvm_info(get_name(), $sformatf("din: 0x%02h (%012b), mosi_serial: 0x%02h (%012b)", tx.din, tx.din, tx.serial_data, tx.serial_data), UVM_NONE);
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
  base_seq b_seq;

  function new(string path="test", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = environment::type_id::create("env", this);
    b_seq = base_seq::type_id::create("b_seq", this);
    b_seq.count = 10;
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    b_seq.start(env.agt.sqr);
    #100;
    phase.drop_objection(this);
  endtask
endclass

module tb;
  // interface
  spi_if s_if();

  // dut master
  spi_master i_spi_m(.clk(s_if.clk),
                     .rst(s_if.rst),
                     .newd(s_if.newd),
                     .din(s_if.din),
                     .cs(s_if.cs),
                     .mosi(s_if.mosi),
                     .sclk(s_if.sclk));

  // dut slave
  spi_slave i_spi_s(.cs(s_if.cs),
                    .mosi(s_if.mosi),
                    .sclk(s_if.sclk),
                    .dout(s_if.dout),
                    .done(s_if.done));


  // initialize rstn and clk
  initial begin
    s_if.rst = 1'b0;
    s_if.clk = 1'b0;
  end

  // generate clk
  always #10 s_if.clk = ~s_if.clk;

  // set interface and run test
  initial begin
    uvm_config_db#(virtual spi_if.drv)::set(null, "*", "s_if", s_if);
    uvm_config_db#(virtual spi_if.mon)::set(null, "*", "s_if", s_if);
    run_test("test");
  end

  // waveform
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule