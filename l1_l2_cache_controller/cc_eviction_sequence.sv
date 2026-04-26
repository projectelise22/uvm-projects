`ifndef CC_EVICTION_SEQUENCE_SV
  `define CC_EVICTION_SEQUENCE_SV
  class cc_eviction_sequence extends uvm_sequence#(cc_sequence_item);
    `uvm_object_utils(cc_eviction_sequence)

    rand cc_addr addr_1;
    rand cc_addr addr_2;

    constraint c_addr {
      addr_1[1:0] == 0;
      addr_2[1:0] == 0;
      addr_1 != addr_2;
    }

    function new(string name="cc_eviction_sequence");
      super.new(name);
    endfunction

    virtual task body();
      cc_op op_arr[5] = '{CC_WRITE, CC_READ, CC_WRITE, CC_READ, CC_READ};
      cc_addr addr_arr[5] = '{addr_1, addr_1, addr_2, addr_1, addr_2};

      foreach(op_arr[i]) begin
        cc_sequence_item tr = cc_sequence_item::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize() with { op   == op_arr[i];
                                     addr == addr_arr[i]; });
        finish_item(tr);
      end
    endtask
  endclass
`endif