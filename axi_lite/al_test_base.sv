`ifndef AL_TEST_BASE_SV
  `define AL_TEST_BASE_SV

class al_test_base extends uvm_test;
  `uvm_component_utils(al_test_base)
  
  function new(string name="al_test_base", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #200ns;
    phase.drop_objection(this);
  endtask
endclass
`endif