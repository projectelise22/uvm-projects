`ifndef CC_AGENT_SV
  `define CC_AGENT_SV
  class cc_agent extends uvm_agent;
    `uvm_component_utils(cc_agent)
    
    // Fields
    uvm_sequencer#(.REQ(cc_sequence_item)) sequencer;
                   
    cc_driver driver;
    
    cc_monitor monitor;

    function new(string name="cc_agent", uvm_component parent=null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      sequencer = uvm_sequencer#(.REQ(cc_sequence_item))::type_id::create("sequencer", this);
      driver = cc_driver::type_id::create("driver", this);
      monitor = cc_monitor::type_id::create("monitor", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass
`endif