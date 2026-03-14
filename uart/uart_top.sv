module uart_top #( parameter clk_freq=1_000_000,
                   parameter baud_rate=9600 )
                 ( input clk, rst,
                   input rx,
                   input [7:0] din_tx,
                   input newd,
                   output tx,
                   output [7:0] dout_rx,
                   output done_tx,
                   output done_rx );

  uart_tx #(clk_freq, baud_rate) i_uart_tx (.clk(clk), 
                                            .rst(rst), 
                                            .newd(newd), 
                                            .tx_data(din_tx), 
                                            .tx(tx),
                                            .done_tx(done_tx));
  uart_rx #(clk_freq, baud_rate) i_uart_rx (.clk(clk), 
                                            .rst(rst), 
                                            .rx(rx),
                                            .rx_data(dout_rx), 
                                            .done(done_rx));

endmodule

interface uart_if;
  logic clk;
  logic rst;
  logic uclk_rx;
  logic uclk_tx;
  logic rx;
  logic [7:0] din_tx;
  logic newd;
  logic tx;
  logic [7:0] dout_rx;
  logic done_tx;
  logic done_rx;

  clocking cb_rx_drv @(posedge uclk_rx);
    output rx;
    input dout_rx, done_rx;
  endclocking

  clocking cb_tx_drv @(posedge uclk_tx);
    output din_tx, newd;
    input tx, done_tx;
  endclocking

  clocking cb_rx_mon @(posedge uclk_rx);
    input rx, dout_rx, done_rx;
  endclocking

  clocking cb_tx_mon @(posedge uclk_tx);
    input din_tx, newd, tx, done_tx;
  endclocking

  modport rx_drv (clocking cb_rx_drv, input clk, rst);
  modport tx_drv (clocking cb_tx_drv, input clk, rst);
  modport rx_mon (clocking cb_rx_mon, input clk, rst);
  modport tx_mon (clocking cb_tx_mon, input clk, rst);
endinterface