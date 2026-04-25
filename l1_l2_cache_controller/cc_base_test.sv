`ifndef CC_BASE_TEST_SV
  `define CC_BASE_TEST_SV
class cc_base_test extends uvm_test;
  `uvm_component_utils(cc_base_test)
  
  // Fields
  cc_environment env;
  cc_base_sequence base_seq;
  
  function new(string name="cc_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = cc_environment::type_id::create("env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #300ns;
    
    base_seq = cc_base_sequence::type_id::create("base_seq");
    base_seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask
endclass
`endif