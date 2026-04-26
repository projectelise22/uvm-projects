`ifndef CC_EVICTION_TEST_SV
  `define CC_EVICTION_TEST_SV
  class cc_eviction_test extends cc_base_test;
    `uvm_component_utils(cc_eviction_test)
    
    // Fields
    cc_eviction_sequence eviction_seq;
    
    function new(string name="cc_eviction_test", uvm_component parent=null);
      super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST START: cc_eviction_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      
      #300;
      
      eviction_seq = cc_eviction_sequence::type_id::create("eviction_seq");
      assert(eviction_seq.randomize());
      eviction_seq.start(env.agent.sequencer);
      
      `uvm_info("TEST", "========================================", UVM_NONE)
      `uvm_info("TEST", " TEST END: cc_eviction_test", UVM_NONE)
      `uvm_info("TEST", "========================================", UVM_NONE)
      phase.drop_objection(this);
    endtask
  endclass
`endif