`ifndef CC_UVM_PKG_SV
  `define CC_UVM_PKG_SV

  `include "uvm_macros.svh"
  `include "cache_ctrl_if.sv"
  
  package cc_uvm_pkg;

    import uvm_pkg::*;

    parameter int ADDR_WIDTH = 8;
    parameter int DATA_WIDTH = 32;

    `include "cc_types.sv"   

    `include "cc_sequence_item.sv"
    `include "cc_base_sequence.sv"

    `include "cc_driver.sv"
    `include "cc_monitor.sv"
    `include "cc_agent.sv"
    `include "cc_scoreboard.sv"
    `include "cc_environment.sv"

    `include "cc_base_test.sv"
  
  endpackage
`endif