`ifndef CC_BASE_TEST_SV
  `define CC_BASE_TEST_SV
class cc_base_test extends uvm_test;
  `uvm_component_utils(cc_base_test)
  
  // Fields
  cc_environment env;
  cc_base_sequence base_seq;
  
  cc_vif vif;
  
  function new(string name="cc_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = cc_environment::type_id::create("env", this);
    if(!uvm_config_db#(cc_vif)::get(this, "", "vif", vif))
    `uvm_fatal("TB_ISSUE", "Base test could not get virtual interface")
  endfunction
  
  virtual task apply_reset();
    `uvm_info("TEST", "Applying reset...", UVM_LOW)
    env.agent.sequencer.stop_sequences();  // stop any running sequences

    // drive reset through interface
    vif.rst   <= 1'b1;
    vif.wr_en <= 1'b0;
    vif.rd_en <= 1'b0;
    vif.addr  <= 1'b0;
    vif.wdata <= 1'b0;

    repeat(5) @(posedge vif.clk);
    vif.rst <= 1'b0;
    repeat(2) @(posedge vif.clk);
    
    // reset software models
    env.scoreboard.reset_model();
    env.agent.coverage.reset_shadow();

    `uvm_info("TEST", "Reset complete", UVM_LOW)
  endtask
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "========================================", UVM_NONE)
    `uvm_info("TEST", " TEST START: cc_base_test", UVM_NONE)
    `uvm_info("TEST", "========================================", UVM_NONE)
    #300ns;
    
    base_seq = cc_base_sequence::type_id::create("base_seq");
    base_seq.start(env.agent.sequencer);
    
    `uvm_info("TEST", "========================================", UVM_NONE)
    `uvm_info("TEST", " TEST END: cc_base_test", UVM_NONE)
    `uvm_info("TEST", "========================================", UVM_NONE)
    phase.drop_objection(this);
  endtask
endclass
`endif