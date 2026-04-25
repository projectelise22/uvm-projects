`ifndef CC_BASE_SEQUENCE_SV
  `define CC_BASE_SEQUENCE_SV

  class cc_base_sequence extends uvm_sequence#(cc_sequence_item);
    `uvm_object_utils(cc_base_sequence)

    function new(string name="cc_base_sequence");
      super.new(name);
    endfunction

    virtual task body();
      
      cc_sequence_item wr_tr = cc_sequence_item::type_id::create("wr_tr");
      cc_sequence_item rd_tr = cc_sequence_item::type_id::create("rd_tr");
      
      // CPU write
      start_item(wr_tr);
      assert(wr_tr.randomize() with {op   == CC_WRITE;
                                     addr == 8'h4C;} );
      finish_item(wr_tr);
      
      // CPU read
      start_item(rd_tr);
      assert(rd_tr.randomize() with {op   == CC_READ;
                                     addr == 8'h4C;} );
      finish_item(rd_tr);
      
    endtask
  endclass
`endif