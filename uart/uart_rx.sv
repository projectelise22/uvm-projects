module uart_rx #( parameter clk_freq=1_000_000, 
                  parameter baud_rate)
                ( input clk, rst, 
                  input rx,
                  output reg [7:0] rx_data,
                  output reg done );

  localparam clk_cnt = (clk_freq/baud_rate);

  integer count = 0;
  integer counts = 0;

  reg uclk = 1'b0;

  enum bit[1:0] { IDLE = 1'b00, START = 1'b01 } state;

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

  always @(posedge uclk) begin
    if (rst) begin
        rx_data <= 8'h00;
        done    <= 1'b0;
        counts  <= 0;
    end else begin
        case (state)
          IDLE: begin
            rx_data <= 8'h00;
            done    <= 1'b0;
            counts  <= 0;

            if (rx <= 1'b0)
              state <= START;
            else
              state <= IDLE;
          end
          START: begin
            if (counts <= 7) begin
                counts  <= counts + 1;
                rx_data <= {rx, rx_data[7:1]};
            end else begin
                counts <= 0;
                done   <= 1'b1;
                state  <= IDLE;
            end
          end
          default: state <= IDLE;
        endcase
    end
  end
endmodule