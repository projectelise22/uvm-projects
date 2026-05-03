`ifndef AL_UVM_PKG_SV
  `define AL_UVM_PKG_SV

  `include "uvm_macros.svh"
  `include "axi_lite_if.sv"

  package al_uvm_pkg;
    import uvm_pkg::*;

    `include "al_types.sv"

    `include "al_sequence_item.sv"
    `include "al_driver.sv"

    `include "al_test_base.sv"

  endpackage
`endif