`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  rand logic wr_en;
  rand logic rd_en;
  rand logic [15:0] din;
  logic [15:0] dout;
  logic empty;
  logic full;

  function new(string inst="transaction");
    super.new(inst);
  endfunction

  `uvm_object_utils_begin(transaction)
  `uvm_field_int(wr_en, UVM_DEFAULT);
    `uvm_field_int(rd_en, UVM_DEFAULT);
    `uvm_field_int(din, UVM_DEFAULT);
    `uvm_field_int(dout, UVM_DEFAULT);
  `uvm_object_utils_end
endclass

class generator extends uvm_sequence;
  `uvm_object_utils(generator);

  transaction tr;

  function new(string inst="generator");
    super.new(inst);
  endfunction

  virtual task body();
    tr = transaction::type_id::create("tr");
    // Write data
    repeat (5) begin
        start_item(tr);
        assert(tr.randomize() with { tr.wr_en == 1; tr.rd_en == 0; });
        `uvm_info(get_name(), $sformatf("Write tx with din: %0d", tr.din), UVM_NONE);
        finish_item(tr);
    end

    // Read data
    repeat (5) begin
        start_item(tr);
        assert(tr.randomize() with { tr.wr_en == 0; tr.rd_en == 1; });
        `uvm_info(get_name(), $sformatf("Read tx"), UVM_NONE);
        finish_item(tr);
    end
  endtask
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver);

  virtual sfifo_if.drv s_if;
  transaction tr;

  function new(string path="driver", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual sfifo_if.drv)::get(this, "", "s_if", s_if))
      `uvm_error(get_name(), "No interface found");
    tr = transaction::type_id::create("tr");
  endfunction

  task reset_dut();
    s_if.rstn  <= 1'b0;
    s_if.drv_cb.wr_en <= 1'b0;
    s_if.drv_cb.rd_en <= 1'b0;
    s_if.drv_cb.din   <= 0;

    repeat (5) @(s_if.drv_cb);
    s_if.rstn  <= 1'b1;
    `uvm_info(get_name(), "Reset asserted.", UVM_NONE);
  endtask

  virtual task run_phase(uvm_phase phase);
    reset_dut();
    forever begin
        seq_item_port.get_next_item(tr);
        @(s_if.drv_cb);
        s_if.drv_cb.wr_en <= tr.wr_en;
        s_if.drv_cb.rd_en <= tr.rd_en;
        s_if.drv_cb.din <= tr.din;
        seq_item_port.item_done();
        `uvm_info(get_name(), $sformatf("wr_en: %0d, rd_en: %0d, din: %0d", tr.wr_en, tr.rd_en, tr.din), UVM_NONE);
    end
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);

  uvm_analysis_port#(transaction) port;
  virtual sfifo_if.mon s_if;

  function new(string path="monitor", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    port = new("port", this);
    if(!uvm_config_db#(virtual sfifo_if.mon)::get(this, "", "s_if", s_if))
      `uvm_error(get_name(), "No interface found");
  endfunction

  virtual task run_phase(uvm_phase phase);
    logic prev_rd_en = 0;
    
    @(posedge s_if.rstn);
    forever begin
        transaction tr;
        tr = transaction::type_id::create("tr");
        // Capture control
        @(s_if.mon_cb);
        tr.wr_en = s_if.mon_cb.wr_en;
        tr.rd_en = s_if.mon_cb.rd_en;
        tr.din   = s_if.mon_cb.din;
        tr.full  = s_if.mon_cb.full;
        tr.empty = s_if.mon_cb.empty;

        // If previous read, capture dout in current cycle
        if (prev_rd_en) begin
          tr.dout = s_if.mon_cb.dout;
          tr.rd_en = 1'b1;
          port.write(tr);
        end
      
        // Update prev_rd_en
        prev_rd_en = s_if.mon_cb.rd_en;
      
        // If write, capture same cycle
        if (tr.wr_en) 
          port.write(tr);
    end
  endtask
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);

  bit [15:0] fifo_model [$];
  int depth;
  uvm_analysis_imp#(transaction, scoreboard) imp;

  function new(string path="scoreboard", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
    if(!uvm_config_db#(int)::get(this, "", "depth", depth))
      `uvm_error(get_name(), "depth not set");
  endfunction

  function void write_fifo(bit[15:0] data);
    if(fifo_model.size() >= depth) begin
        `uvm_error(get_name(), "FIFO full, overflow detected");
    end else begin
        fifo_model.push_back(data);
        `uvm_info(get_name(), $sformatf("Written data: %0d", data), UVM_NONE);
    end
  endfunction

  function bit [15:0] read_fifo();
    bit [15:0] data;

    if(fifo_model.size() == 0) begin
        `uvm_error(get_name(), "FIFO empty, underflow detected");
    end else begin
        data = fifo_model.pop_front();
        `uvm_info(get_name(), $sformatf("Read data: %0d", data), UVM_NONE);
    end

    return data;
  endfunction

  function void write(transaction tr);
    bit [15:0] exp_data;
    if(tr.rd_en && !tr.empty) begin
        exp_data = read_fifo();
        assert(exp_data == tr.dout) begin
          `uvm_info(get_name(),"Matched wr and rd data:", UVM_NONE);
          `uvm_info(get_name(),$sformatf("Read data: %0d, Expected data: %0d", tr.dout, exp_data), UVM_NONE);
        end else begin
          `uvm_warning(get_name(), "Mismatched data");
          `uvm_info(get_name(),$sformatf("Read data: %0d, Expected data: %0d", tr.dout, exp_data), UVM_NONE);
        end
    end

    if(tr.wr_en && !tr.full)
        write_fifo(tr.din);
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
  generator gen;

  function new(string path="test", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = environment::type_id::create("env", this);
    gen = generator::type_id::create("gen", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    gen.start(env.agt.sqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass

module tb;

  // if and depth
  sfifo_if s_if();
  int depth = 8;

  // dut
  sfifo i_sfifo(.rstn(s_if.rstn),
                .clk(s_if.clk),
                .wr_en(s_if.wr_en),
                .rd_en(s_if.rd_en),
                .din(s_if.din),
                .dout(s_if.dout),
                .empty(s_if.empty),
                .full(s_if.full));

  // initialize rstn and clk
  initial begin
    s_if.rstn = 1'b0;
    s_if.clk = 1'b0;
  end

  // generate clk
  always #10 s_if.clk = ~s_if.clk;

  // set interface and run test
  initial begin
    uvm_config_db#(virtual sfifo_if.drv)::set(null, "*", "s_if", s_if);
    uvm_config_db#(virtual sfifo_if.mon)::set(null, "*", "s_if", s_if);
    uvm_config_db#(int)::set(null, "*", "depth", depth);
    run_test("test");
  end

  // waveform
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule