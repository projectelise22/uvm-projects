`ifndef CC_SCOREBOARD_SV
  `define CC_SCOREBOARD_SV
  class cc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cc_scoreboard)
    
    // Fields
    uvm_analysis_imp#(cc_sequence_item, cc_scoreboard) imp;
    
    cache_line_t cache_model [`CACHE_SLOT];
    
    int pass_count;
    int fail_count;

    function new(string name="cc_scoreboard", uvm_component parent=null);
      super.new(name, parent);
      
      pass_count = 0;
      fail_count = 0;
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      imp = new("imp", this);
    endfunction
    
    
    virtual function void write(cc_sequence_item tr);
      logic [1:0] index = tr.addr[$clog2(`CACHE_SLOT)-1:0];
      logic [5:0] addr_tag = tr.addr[`ADDR_WIDTH-1:$clog2(`CACHE_SLOT)];
      
      bit expect_hit;
      expect_hit = (cache_model[index].valid) &&
                   (cache_model[index].tag === addr_tag);
      
      case (tr.op)
        CC_WRITE: begin
          cache_model[index].valid = 1'b1;
          cache_model[index].tag = addr_tag;
          cache_model[index].data = tr.data;
          `uvm_info("DEBUG", $sformatf("Write recorded, %0s", tr.convert2string()), UVM_LOW);
        end
        
        CC_READ: begin
          // address hit check
          if( expect_hit ) begin
            if( tr.hit !== 1'b1 ) begin
              `uvm_error("DUT_ERROR", "Expecting hit but got MISS");
              fail_count++;
            end else begin
              // data check
              if( tr.data !== cache_model[index].data ) begin
                `uvm_error("DUT_ERROR", $sformatf("Read data not equal to expected data! %0s, expected: %0h", tr.convert2string(), cache_model[index].data));
                fail_count++;
              end else begin
                `uvm_info("TEST PASS", $sformatf("%0s, expected: %0h", tr.convert2string(), cache_model[index].data), UVM_LOW);
                pass_count++;
              end
            end
                           
          // never written in this address
          end else begin
            if( tr.miss !== 1'b1 ) begin
              `uvm_error("DUT_ERROR", "Address was not written before but got HIT");
              fail_count++;
            end else begin
              `uvm_info("TEST PASS", "Address was not written before and got MISS", UVM_LOW);
              pass_count++;
            end
          end
        end
        
      endcase
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      
      `uvm_info("INFO", $sformatf("SCOREBOARD SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count), UVM_NONE);
    endfunction
  endclass
`endif