module KVSelectInvalidWay_tb;

  logic [3:0]   i_valid_way;
  logic [3:0]   o_killmask;

  KVSelectInvalidWay #(
    .WAY_NUM    (4  )
  ) DUT (
    .i_valid_way    (i_valid_way    ),
    .o_killmask     (o_killmask     )
  );

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, KVSelectInvalidWay_tb);
  end

  initial begin
    i_valid_way = 4'b0000;
    #2
    i_valid_way = 4'b0001;
    #2
    i_valid_way = 4'b0010;
    #2
    i_valid_way = 4'b0011;
    #2
    i_valid_way = 4'b0100;
    #2
    i_valid_way = 4'b0101;
    #2
    i_valid_way = 4'b0110;
    #2
    i_valid_way = 4'b0111;
    #2
    i_valid_way = 4'b1000;
    #2
    i_valid_way = 4'b1001;
    #2
    i_valid_way = 4'b1010;
    #2
    i_valid_way = 4'b1011;
    #2
    i_valid_way = 4'b1100;
    #2
    i_valid_way = 4'b1101;
    #2
    i_valid_way = 4'b1110;
    #2
    i_valid_way = 4'b1111;
    #2
    $finish;
  end
endmodule
