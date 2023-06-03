module KVSelectInvalidWay_tb;

  logic         i_clk = '1;
  logic [3:0]   i_hitway;
  logic [3:0]   i_index;
  logic [3:0]   o_killmask;

  KVLRU DUT (
    .i_clk          (i_clk          ),
    .i_rstn         (),
    .i_hitway       (i_hitway       ),
    .i_index        (i_index        ),
    .o_killmask     (o_killmask     )
  );

  always #1 begin
    i_clk   <= ~i_clk;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, KVLRU_tb);
  end

  initial begin
    #20
    $finish;
  end
endmodule
