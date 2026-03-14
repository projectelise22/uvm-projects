module uart_tx #( parameter clk_freq = 1_000_000,
                  parameter baud_rate = 9600)
                ( input clk, rst,
                  input newd,
                  input [7:0] tx_data,
                  output reg tx,
                  output reg done_tx );

  localparam clk_cnt = (clk_freq / baud_rate);

  integer count  = 0;
  integer counts = 0;

  reg uclk = 0;

  enum bit [1:0] { IDLE     = 2'b00,
                   START    = 2'b01,
                   TRANSFER = 2'b10,
                   DONE     = 2'b11 } state;

  // uart clock gen
  // bit duration for the whole cycle
  always @(posedge clk) begin
    if (count < clk_cnt/2)
      count <= count + 1;
    else begin
      count <= 0;
      uclk  <= ~uclk;
    end
  end

  // uart tx fsm
  reg [7:0] din;
  always @(posedge uclk) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        case (state)
        IDLE: begin
            counts  <= 0;
            tx      <= 1'b1;
            done_tx <= 1'b0;

            if (newd) begin
                state <= TRANSFER;
                din   <= tx_data;
                tx    <= 1'b0;
            end else begin
                state <= IDLE;
            end
        end
        TRANSFER: begin
            if (counts <= 7) begin
                counts <= counts + 1;
                tx     <= din[counts];
                state  <= TRANSFER;
            end else begin
                counts  <= 0;
                tx      <= 1'b1;
                done_tx <= 1'b1;
                state   <= IDLE;
            end
        end
        default: state <= IDLE;
        endcase 
    end
  end
endmodule