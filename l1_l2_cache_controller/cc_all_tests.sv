`ifndef CC_ALL_TESTS_SV
  `define CC_ALL_TESTS_SV
  class cc_all_tests extends cc_base_test;
    `uvm_component_utils(cc_all_tests)
    
    // Fields
    cc_eviction_sequence eviction_seq;
    cc_write_hit_sequence write_hit_seq;
    cc_all_slots_sequence all_slots_seq;
    
    function new(string name="cc_all_tests", uvm_component parent=null);
      super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      
      #150ns;
      
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST START: cc_eviction_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      
      apply_reset();
      eviction_seq = cc_eviction_sequence::type_id::create("eviction_seq");
      assert(eviction_seq.randomize());
      eviction_seq.start(env.agent.sequencer);
      
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST END: cc_eviction_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      
      #150ns;
      
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST START: cc_write_hit_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      
      apply_reset();
      write_hit_seq = cc_write_hit_sequence::type_id::create("write_hit_seq");
      assert(write_hit_seq.randomize());
      write_hit_seq.start(env.agent.sequencer);
      
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST END: cc_write_hit_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      
      #300ns;
      
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST START: cc_all_slots_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      
      apply_reset();
      all_slots_seq = cc_all_slots_sequence::type_id::create("all_slots_seq");
      assert(all_slots_seq.randomize());
      all_slots_seq.start(env.agent.sequencer);
      
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST END: cc_all_slots_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      phase.drop_objection(this);
    endtask
  endclass
`endif