`ifndef CC_COVERAGE_SV
  `define CC_COVERAGE_SV

  class cc_coverage extends uvm_component;
    `uvm_component_utils(cc_coverage)

    // Fields
    uvm_analysis_imp#(cc_sequence_item, cc_coverage) imp;
    
    logic shadow_valid [`CACHE_SLOT];
    logic [`TAG_WIDTH-1:0] shadow_tag [`CACHE_SLOT];
    logic eviction_occurred;
    logic [$clog2(`CACHE_SLOT)-1:0] eviction_slot;

    // Covergroup 1: transaction items
    covergroup cover_cc with function sample(cc_sequence_item tr);
      cp_op: coverpoint tr.op {
        bins write = {CC_WRITE};
        bins read  = {CC_READ};
        option.comment = "CPU Operation";
      }

      cp_outcome: coverpoint tr.hit {
        bins hit  = {1'b1};
        bins miss = {1'b0};
        option.comment = "Outcome of CPU operation";
      }
      
      cp_slot: coverpoint tr.addr[$clog2(`CACHE_SLOT)-1:0] {
        bins slot_0 = {2'b00};
        bins slot_1 = {2'b01};
        bins slot_2 = {2'b10};
        bins slot_3 = {2'b11};
        option.comment = "Cache slots";
      }

      cx_op_outcome: cross cp_op, cp_outcome;
      
      cx_op_slot: cross cp_op, cp_slot;
    endgroup
    
    // Covergroup 2 - eviction only, sampled on writes
    covergroup cover_eviction;
      cp_eviction: coverpoint eviction_occurred {
        bins eviction    = {1'b1};
        bins no_eviction = {1'b0};
      }
      
      cp_eviction_slot: coverpoint eviction_slot {
        bins slot_0 = {2'b00};
        bins slot_1 = {2'b01};
        bins slot_2 = {2'b10};
        bins slot_3 = {2'b11};
      }
      
      cx_eviction_slot: cross cp_eviction, cp_eviction_slot;
    endgroup

    function new(string name="cc_coverage", uvm_component parent=null);
      super.new(name, parent);

      cover_cc = new();
      cover_eviction = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      imp = new("imp", this);
    endfunction

    virtual function void write(cc_sequence_item tr);
      logic [1:0] index = tr.addr[$clog2(`CACHE_SLOT)-1:0];
      logic [5:0] addr_tag = tr.addr[`ADDR_WIDTH-1:$clog2(`CACHE_SLOT)];
      
      if (tr.op == CC_WRITE) begin
        eviction_occurred   = shadow_valid[index] &&
                              (shadow_tag[index] != addr_tag);
        eviction_slot       = index;
        shadow_valid[index] = 1'b1;
        shadow_tag[index]   = addr_tag;
        
        cover_eviction.sample();
      end
      
      cover_cc.sample(tr);
    endfunction
    
    virtual function void reset_shadow();
      for(int i=0; i<`CACHE_SLOT; i++) begin
        shadow_valid[i] = 1'b0;
        shadow_tag[i]   = '0;
      end
      `uvm_info("COV", "Coverage shadow model reset", UVM_LOW)
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
      real overall;
      
      super.report_phase(phase);

      `uvm_info("COV", "----------------------------------------", UVM_NONE)
      `uvm_info("COV", "  FUNCTIONAL COVERAGE SUMMARY",           UVM_NONE)
      `uvm_info("COV", "----------------------------------------", UVM_NONE)
      `uvm_info("COV", "  -- Transaction Coverage --",            UVM_NONE)
      `uvm_info("COV", $sformatf("  cp_op:          %0.2f%%", cover_cc.cp_op.get_coverage()),      UVM_NONE)
      `uvm_info("COV", $sformatf("  cp_outcome:     %0.2f%%", cover_cc.cp_outcome.get_coverage()), UVM_NONE)
      `uvm_info("COV", $sformatf("  cp_slot:        %0.2f%%", cover_cc.cp_slot.get_coverage()),    UVM_NONE)
      `uvm_info("COV", $sformatf("  cx_op_outcome:  %0.2f%%", cover_cc.cx_op_outcome.get_coverage()), UVM_NONE)
      `uvm_info("COV", $sformatf("  cx_op_slot:     %0.2f%%", cover_cc.cx_op_slot.get_coverage()),    UVM_NONE)
      `uvm_info("COV", "  -- Eviction Coverage --",              UVM_NONE)
      `uvm_info("COV", $sformatf("  cp_eviction:      %0.2f%%", cover_eviction.cp_eviction.get_coverage()),       UVM_NONE)
      `uvm_info("COV", $sformatf("  cx_eviction_slot: %0.2f%%", cover_eviction.cx_eviction_slot.get_coverage()), UVM_NONE)
      
      overall = (cover_cc.get_coverage() + cover_eviction.get_coverage()) / 2.0;
      `uvm_info("COV", "----------------------------------------", UVM_NONE)
      `uvm_info("COV", $sformatf("  OVERALL: %0.2f%%", overall), UVM_NONE)
      `uvm_info("COV", "----------------------------------------", UVM_NONE)
    endfunction

  endclass
`endif