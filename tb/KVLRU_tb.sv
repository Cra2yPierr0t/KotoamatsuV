module KVSelectInvalidWay_tb;

  logic         i_clk;
  logic [3:0]   i_valid_way;
  logic [3:0]   i_hitway;
  logic [3:0]   i_index;
  logic [3:0]   o_killmask;

  KVLRU DUT (
    .i_clk          (i_clk          ),
    .i_rstn         (),
    .i_valid_way    (i_valid_way    ),
    .i_hitway       (i_hitway       ),
    .i_index        (i_index        ),
    .o_killmask     (o_killmask     )
  );

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, KVLRU_tb);
  end

  initial begin
    #2
    i_valid_way = 4'b0001;
    #2
    #2
    #2
    $finish;
  end
endmodule
