// Generating a burst sequence
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  //Fields
  rand logic [7:0] addr;
  rand logic [7:0] data;
  
  //Constraints
  constraint c_addr_4byte_aligned {
    addr[1:0] == 0;
  }
  
  `uvm_object_utils(transaction);
  
  function new(string inst="transaction");
    super.new(inst);
  endfunction
  
  virtual function string display_item();
    string result = $sformatf("addr: %02h (%08b), data: %02h", addr, addr, data);
    return result;
  endfunction
endclass

class burst_seq extends uvm_sequence#(transaction);
  
  // Fields
  rand logic[7:0] start_addr;
  rand int burst_len;
  
  //Constraints 
  constraint c_burst_len {
    burst_len inside {[16:32]};
  }

  constraint c_start_addr_align {
    start_addr[1:0] == 0;
  }
  
  constraint c_addr_valid_region {
    //start_address should not be inside reserved region
    !(start_addr inside {[8'h20:8'h5F]});
    
    //cast to int so that overflow is detected
    //start address range should not hit reserved region
    !( int'(start_addr + (15*4)) inside {[8'h20:8'h5F]} );
    
    //end of address range should not be higher than limit
    int'(start_addr + (15*4)) <= 8'hFF;
  }
  
  `uvm_object_utils(burst_seq);
  
  function new(string inst="burst_seq");
    super.new(inst);
  endfunction
  
  virtual task body();
    transaction tr;
    
    //Create addresses based on burst_len
    `uvm_info("INFO", $sformatf("Burst Length: %0d", burst_len), UVM_LOW);
    for (int i=0; i<burst_len; i++) begin
      tr = transaction::type_id::create("tr");
      
      start_item(tr);
      assert(tr.randomize with { addr == start_addr + (i*4); });
      finish_item(tr);
      
      `uvm_info("DEBUG", $sformatf("%0s", tr.display_item()), UVM_LOW);
    end
  endtask
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver);
  
  function new(string name="driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      transaction tr = transaction::type_id::create("tr");
      seq_item_port.get_next_item(tr);
      `uvm_info("DEBUG", $sformatf("%0s", tr.display_item()), UVM_LOW);
      seq_item_port.item_done();
    end
  endtask
endclass

class sample_test extends uvm_test;
  driver drv;
  uvm_sequencer#(transaction) sqr;
  burst_seq seq;
  
  `uvm_component_utils(sample_test);
  
  function new(string name="sample_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = uvm_sequencer#(transaction)::type_id::create("sqr", this);
    drv = driver::type_id::create("drv", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    #100ns;
    
    // Burst Sequence
    seq = burst_seq::type_id::create("seq");
    assert(seq.randomize() with { burst_len  == 16;
                                  start_addr == 8'h00; });
    seq.start(sqr);
    
    phase.drop_objection(this);
  endtask
endclass

module tb;
  initial begin
    run_test("sample_test");
  end
endmodule