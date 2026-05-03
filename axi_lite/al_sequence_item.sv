`ifndef AL_SEQUENCE_ITEM_SV
  `define AL_SEQUENCE_ITEM_SV

  class al_sequence_item extends uvm_sequence_item;
    
    `uvm_object_utils(al_sequence_item)
    
    // Transaction Items
    rand axi_op_t axi_op;
    rand aw_w_order_t aw_aw_order;
    rand int unsigned pre_drv_dly;
    rand int unsigned pst_drv_dly;
    
    // For driver -- write operation 
    rand axi_addr awaddr;
    rand axi_data wdata;
    
    // For driver -- read operation
    rand axi_addr araddr;
    
    // For monitor
    axi_resp bresp;
    
    axi_data rdata;
    axi_resp rresp;
    
    function new(string name="al_sequence_item");
      super.new(name);
    endfunction
    
    virtual function string convert2string();
      string result;
      
      if (axi_op == AXI_WRITE) begin
        result = $sformatf("%0s | awaddr: %02h, wdata: %08h", axi_op.name(), awaddr, wdata);
      end else begin
        result = $sformatf("%0s | araddr: %02h", axi_op.name(), araddr);
      end
      
      return result;
    endfunction
    
  endclass
`endif