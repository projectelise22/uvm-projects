`ifndef CC_DRIVER_SV
  `define CC_DRIVER_SV

  class cc_driver extends uvm_driver#(.REQ(cc_sequence_item));
    `uvm_component_utils(cc_driver)
    
    // Fields
    cc_vif vif;
    
    function new(string name="cc_driver", uvm_component parent=null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(cc_vif)::get(this, "", "vif", vif))
        `uvm_fatal("TB ISSUE", "Failure to get virtual interface in driver");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      cc_sequence_item tr;
      
      forever begin
        seq_item_port.get_next_item(tr);
        
        drive_item(tr);
        
        seq_item_port.item_done();
      end
    endtask
    
    virtual task drive_item(cc_sequence_item tr);
      @(posedge vif.clk);
      
      case (tr.op)
        
        CC_WRITE: begin
          vif.wr_en <= 1'b1;
          vif.rd_en <= 1'b0;
          vif.addr  <= tr.addr;
          vif.wdata <= tr.data;
          
          @(posedge vif.clk);
          vif.wr_en <= 1'b0;
          
          `uvm_info("DEBUG", $sformatf("%0s", tr.convert2string()), UVM_LOW);
        end
        
        CC_READ: begin
          vif.rd_en <= 1'b1;
          vif.wr_en <= 1'b0;
          vif.addr  <= tr.addr;
          
          @(posedge vif.clk);
          vif.rd_en <= 1'b0;
          
          `uvm_info("DEBUG", $sformatf("%0s", tr.convert2string()), UVM_LOW);
        end
        
      endcase
      
    endtask
    
  endclass
`endif