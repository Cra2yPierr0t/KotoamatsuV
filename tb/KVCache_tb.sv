module KVCache_tb;

  parameter DATA_WIDTH  = 32;
  parameter ADDR_WIDTH  = 32;
  parameter WAY_NUM     = 2;
  parameter LINE_SIZE   = 4;
  parameter LINE_NUM    = 64;
  localparam LINE_WIDTH = LINE_NUM * LINE_SIZE;

  logic i_clk = 1'b0;
  logic i_rstn;
  // Processor Signal
  // Load
  logic [DATA_WIDTH-1:0] o_load_data;
  logic                  o_load_valid;
  logic                  i_load_ready;
  logic [ADDR_WIDTH-1:0] i_load_addr;
  logic                  i_load_valid;
  logic                  o_load_ready;
  // Memory Signal
  // Fetch
  logic [DATA_WIDTH-1:0] i_fetch_data[LINE_SIZE-1:0];
  logic                  i_fetch_valid;
  logic                  o_fetch_ready;
  logic [ADDR_WIDTH-1:0] o_fetch_addr;
  logic                  o_fetch_valid;
  logic                  i_fetch_ready;

  always #1 begin
    i_clk <= ~i_clk;
  end

  KVCache DUT(
    .i_clk  (i_clk  ),
    .i_rstn (i_rstn ),
    // Processor Signal
    // Load
    .o_load_data    (o_load_data    ),
    .o_load_valid   (o_load_valid   ),
    .i_load_ready   (i_load_ready   ),
    .i_load_addr    (i_load_addr    ),
    .i_load_valid   (i_load_valid   ),
    .o_load_ready   (o_load_ready   ),
    // Store
    .i_store_data   (),
    .i_store_addr   (),
    .i_store_valid  (),
    .o_store_ready  (),
    // Memory Signal
    // Fetch
    .i_fetch_data   (i_fetch_data   ),
    .i_fetch_valid  (i_fetch_valid  ),
    .o_fetch_ready  (o_fetch_ready  ),
    .o_fetch_addr   (o_fetch_addr   ),
    .o_fetch_valid  (o_fetch_valid  ),
    .i_fetch_ready  (i_fetch_ready  ),
    // Write
    .o_write_data   (),
    .o_write_addr   (),
    .o_write_valid  (),
    .i_write_ready  ()
  );

  KVMemory_beh Memory_beh (
    .i_clk          (i_clk          ),
    .i_rstn         (i_rstn         ),
    .i_read_addr    (o_fetch_addr   ),
    .i_read_valid   (o_fetch_valid  ),
    .o_read_ready   (i_fetch_ready  ),
    .o_read_data    (i_fetch_data   ),
    .o_read_valid   (i_fetch_valid  ),
    .i_read_ready   (o_fetch_ready  )
  );
  
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, KVCache_tb);
  end

  initial begin
    #10
    i_load_ready    = '1;
    i_load_addr     = 32'h1111_1001;
    i_load_valid    = '1;
    #2
    wait(o_load_ready);
    i_load_valid    = '0;
    #20
    i_load_valid    = '1;
    #2
    wait(o_load_ready);
    i_load_valid    = '0;
    #20
    i_load_addr     = 32'h1111_1004;
    i_load_valid    = '1;
    #2
    wait(o_load_ready);
    i_load_valid    = '0;
    #20
    i_load_addr     = 32'h1111_1002;
    i_load_valid    = '1;
    #2
    wait(o_load_ready);
    i_load_valid    = '0;
    #100
    $finish;
  end
endmodule
