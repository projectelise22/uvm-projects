`ifndef CC_MONITOR_SV
  `define CC_MONITOR_SV

class cc_monitor extends uvm_monitor;
  `uvm_component_utils(cc_monitor)
  
  // Fields
  cc_vif vif;
  uvm_analysis_port#(cc_sequence_item) port;
  
  function new(string name="cc_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db#(cc_vif)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Failure to get virtual interface in monitor");
    
    port = new("port", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    cc_sequence_item tr;
    
    forever begin
      collect_item(tr);
    end
  endtask
  
  virtual task collect_item(cc_sequence_item tr);
    
    @(posedge vif.clk);
    
    if (vif.wr_en === 1'b1 || vif.rd_en === 1'b1) begin
      tr = cc_sequence_item::type_id::create("tr");
      
      if(vif.wr_en === 1'b1) begin
        tr.op   = CC_WRITE;
        tr.addr = vif.addr;
        tr.data = vif.wdata;
      end else if (vif.rd_en === 1'b1) begin
        tr.op   = CC_READ;
        tr.addr = vif.addr;
        tr.data = vif.rdata;
      end
      
      tr.hit  = vif.hit;
      tr.miss = vif.miss;
      
      `uvm_info("MON", $sformatf("%0s", tr.convert2string()), UVM_LOW);
    port.write(tr);
    end
  
  endtask
  
endclass
`endif