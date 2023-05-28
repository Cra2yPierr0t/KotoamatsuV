module KVMemory_beh_tb;

  logic i_clk   = 1'b0;
  logic i_rstn;
  logic i_read_valid;
  logic [31:0] i_read_addr;
  logic i_read_ready;

  always #1 begin
    i_clk   <= ~i_clk;
  end

  KVMemory_beh DUT (
    .i_clk          (i_clk          ),
    .i_rstn         (i_rstn         ),
    .i_read_addr    (i_read_addr    ),
    .i_read_valid   (i_read_valid   ),
    .o_read_ready   (),
    .o_read_data    (),
    .o_read_valid   (),
    .i_read_ready   (i_read_ready   )
  );

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, KVMemory_beh_tb);
  end

  initial begin
    #10
    i_read_ready    = 1'b1;
    i_read_valid    = 1'b1;
    i_read_addr     = 32'h0000_0001;
    #2
    #10
    i_read_addr     = 32'h0000_0004;
    #20
    $finish;
  end

endmodule
