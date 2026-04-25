`ifndef CC_ENVIRONMENT_SV
  `define CC_ENVIRONMENT_SV
class cc_environment extends uvm_env;
  `uvm_component_utils(cc_environment)
  
  // Fields
  cc_agent agent;
  cc_scoreboard scoreboard;
  
  function new(string name="cc_environment", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    agent = cc_agent::type_id::create("agent", this);
    scoreboard = cc_scoreboard::type_id::create("scoreboard", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    agent.monitor.port.connect(scoreboard.imp);
  endfunction
  
endclass
`endif