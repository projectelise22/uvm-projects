`ifndef CC_SEQUENCE_ITEM_SV
  `define CC_SEQUENCE_ITEM_SV

  class cc_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(cc_sequence_item)
    
    // Transaction items to generate write
    rand cc_op op;
    rand cc_addr addr;
    rand cc_data data;
    
    // Transaction items for monitor
    logic hit;
    logic miss;
    
    function new (string name="cc_sequence_item");
      super.new(name);
    endfunction
    
    virtual function string convert2string();
      string result = $sformatf("op: %0s addr: 0x%0h, data: 0x%0h", op.name(), addr, data);
      return result;
    endfunction
    
  endclass
`endif