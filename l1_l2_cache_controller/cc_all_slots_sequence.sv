`ifndef CC_ALL_SLOTS_SEQUENCE_SV
  `define CC_ALL_SLOTS_SEQUENCE_SV
  class cc_all_slots_sequence extends uvm_sequence#(cc_sequence_item);
    `uvm_object_utils(cc_all_slots_sequence)
    
    rand cc_addr addr;
    
    function new(string name="cc_all_slots_sequence");
      super.new(name);
    endfunction
    
    virtual task body();
      cc_sequence_item wr_tr;
      cc_sequence_item rd_tr;
      
      for (int i=0; i<`CACHE_SLOT; i++) begin
        wr_tr = cc_sequence_item::type_id::create("wr_tr");
        rd_tr = cc_sequence_item::type_id::create("rd_tr");
        
        addr[1:0] = i;
        
        // CPU Write
        start_item(wr_tr);
        assert( wr_tr.randomize() with { op == CC_WRITE;
                                         addr == local::addr; } );
        finish_item(wr_tr);
        
        // CPU Read
        start_item(rd_tr);
        assert( rd_tr.randomize() with { op == CC_READ;
                                         addr == local::addr; } );
        finish_item(rd_tr);
        
      end
    endtask
  endclass
`endif