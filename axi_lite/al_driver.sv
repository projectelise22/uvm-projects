`ifndef AL_DRIVER_SV
  `define AL_DRIVER_SV
  class al_driver extends uvm_driver#(al_sequence_item);
    `uvm_component_utils(al_driver)
    
    // Virtual interface
    axi_lite_vif vif;
    
    function new(string name="al_driver", uvm_component parent=null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if(!uvm_config_db#(axi_lite_vif)::get(this, "", "vif", vif))
        `uvm_fatal("DRV", "Failed to get axi lite virtual interface!");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      al_sequence_item item;
      
      // Initialize all inputs to be driven
      vif.awaddr  <= 0;
      vif.awvalid <= 0;
      vif.wdata   <= 0;
      vif.wvalid  <= 0;
      vif.bready  <= 0;
      vif.araddr  <= 0;
      vif.arvalid <= 0;
      vif.rready  <= 0;
      
      forever begin
        seq_item_port.get_next_item(item);
        drive_item(item);
        seq_item_port.item_done();
      end
    endtask
    
    // --------------- Operation tasks
    virtual task drive_item(al_sequence_item item);
      if (item.op == AXI_WRITE) begin
        drive_write(item);
      end else begin
        drive_read(item);
      end
    endtask
    
    virtual task drive_write(al_sequence_item item);
      case (item.aw_w_order)
        SIMULTANEOUS: begin
          // Drive AW and W channels at the same time
          fork
            drive_aw(item.awaddr);
            drive_w(item.wdata);
          join
        end
        
        AW_FIRST: begin
          // Drive AW first before W
          drive_aw(item.awaddr);
          drive_w(item.wdata);
        end
        
        W_FIRST: begin
          // Drive W first before AW
          drive_w(item.wdata);
          drive_aw(item.awaddr);
        end
      endcase
      
      // Accept the write response by asserting bready
      @(posedge vif.clk);
      vif.bready <= 1'b1;
      
      // Wait for DUT to assert bvalid to complete handshake
      @(posedge vif.clk iff (vif.bvalid && vif.bready));
      vif.bready <= 1'b0;
      
      `uvm_info("DRV", $sformatf("WRITE done: awaddr=0x%0h wdata=0x%0h bresp=%0b", item.awaddr, item.wdata, vif.bresp), UVM_MEDIUM);
    endtask
    
    virtual task drive_read(al_sequence_item item);
      // Drive AR channel
      drive_ar(item.araddr);
      
      // Accept the read response 
      // Assert rready and wait for rvalid from DUT
      @(posedge vif.clk);
      vif.rready <= 1'b1;
      
      @(posedge vif.clk iff (vif.rvalid && vif.rready));
      vif.rready <= 1'b0;
      
      `uvm_info("DRV", $sformatf("READ done: araddr=0x%0h rdata=0x%0h rresp=%0b",
               item.araddr, vif.rdata, vif.rresp), UVM_MEDIUM)
    endtask
    
    // --------------- Channel Tasks
    virtual task drive_aw(axi_addr addr);
      @(posedge vif.clk);
      vif.awvalid <= 1'b1;
      vif.awaddr  <= addr;
      
      // Wait for handshake — DUT asserts awready
      @(posedge vif.clk iff vif.awready);
      vif.awvalid <= 1'b0;
      vif.awaddr  <= 0;
    endtask
    
    virtual task drive_w(axi_data data);
      @(posedge vif.clk);
      vif.wvalid <= 1'b1;
      vif.wdata  <= data;
      
      // Wait for handshake — DUT asserts wready
      @(posedge vif.clk iff vif.wready);
      vif.wvalid <= 1'b0;
      vif.wdata  <= 0;
    endtask
    
    virtual task drive_ar(axi_addr addr);
      @(posedge vif.clk);
      vif.arvalid <= 1'b1;
      vif.araddr  <= addr;
      
      // Wait for handshake — DUT asserts arready
      @(posedge vif.clk iff vif.arready);
      vif.arvalid <= 1'b0;
      vif.araddr  <= 0;
    endtask
  endclass
`endif