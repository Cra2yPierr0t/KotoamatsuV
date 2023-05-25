module KVPriorityTree_tb;

  logic [31:0] i_datas[3:0];
  logic [3:0] i_valid;
  logic [31:0] o_data;

  KVPriorityTree #(
    .DATA_WIDTH (32 ),
    .DATA_NUM   (4  )
  ) DUT (
    .i_datas    (i_datas),
    .i_valid    (i_valid),
    .o_data     (o_data )
  );
  
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, KVPriorityTree_tb);
  end

  initial begin
    i_valid = 4'b0001;
    i_datas[0] = 32'h0000_0000;
    i_datas[1] = 32'h0000_ffff;
    i_datas[2] = 32'hffff_0000;
    i_datas[3] = 32'hffff_ffff;
    #10
    i_valid = 4'b0010;
    #10
    i_valid = 4'b0100;
    #10
    i_valid = 4'b1000;
    #10
    i_valid = 4'b0011;
    #10
    i_valid = 4'b0000;
    #10
    $finish;
  end
endmodule
