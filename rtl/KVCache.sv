module KVCache #(
  parameter DATA_WIDTH  = 32,
  parameter ADDR_WIDTH  = 32,
  parameter WAY_NUM     = 2,
  parameter LINE_SIZE   = 4,
  parameter LINE_NUM    = 64,
  localparam LINEOFFSET_WIDTH = $clog2(LINE_SIZE),
  localparam INDEX_WIDTH = $clog2(LINE_NUM / WAY_NUM),
  localparam TAG_WIDTH = ADDR_WIDTH - (INDEX_WIDTH + LINEOFFSET_WIDTH),
  localparam LINE_WIDTH = DATA_WIDTH * LINE_SIZE,
  localparam LINE_NUM_PER_WAY = LINE_NUM / WAY_NUM
)(
  input  logic i_clk,
  input  logic i_rstn,
  // Processor Signal
  // Load
  output logic [DATA_WIDTH-1:0] o_load_data,
  output logic                  o_load_valid,
  input  logic                  i_load_ready,
  input  logic [ADDR_WIDTH-1:0] i_load_addr,
  input  logic                  i_load_valid,
  output logic                  o_load_ready,
  // Store
  input  logic [DATA_WIDTH-1:0] i_store_data,
  input  logic [ADDR_WIDTH-1:0] i_store_addr,
  input  logic                  i_store_valid,
  output logic                  o_store_ready,

  // Memory Signal
  // Fetch
  input  logic [DATA_WIDTH-1:0] i_fetch_data[LINE_SIZE-1:0],
  input  logic                  i_fetch_valid,
  output logic                  o_fetch_ready,
  output logic [ADDR_WIDTH-1:0] o_fetch_addr,
  output logic                  o_fetch_valid,
  input  logic                  i_fetch_ready,
  // Write
  input  logic                  i_line_valid,
  output logic                  o_line_ready,
  input  logic [LINE_WIDTH-1:0] i_line_data,
  output logic [ADDR_WIDTH-1:0] o_line_addr,
  output logic [LINE_WIDTH-1:0] o_line_data
);

  logic                  w_o_load_valid;
  logic [DATA_WIDTH-1:0] w_o_load_data;

  logic                  w_o_fetch_ready;
  logic [ADDR_WIDTH-1:0] w_o_fetch_addr;
  logic                  w_o_fetch_valid;

  logic               w_miss;
  logic               r_miss;
  logic [WAY_NUM-1:0] w_hitway;
  logic [WAY_NUM-1:0] r_hitway;

  logic [DATA_WIDTH-1:0] w_rdata;
  logic [DATA_WIDTH-1:0] w_rdataway[WAY_NUM-1:0];
  logic [DATA_WIDTH-1:0] w_wdataway[WAY_NUM-1:0];
  logic [WAY_NUM-1:0] w_cachemissway;
  logic w_cachemiss;

  // Cache Register
  logic [WAY_NUM-1:0]           w_cache_valid;
  logic [TAG_WIDTH-1:0]         w_cache_tag[WAY_NUM];
  logic [DATA_WIDTH-1:0]        w_cache_line[WAY_NUM-1:0][LINE_SIZE-1:0];
  logic [LINE_NUM_PER_WAY-1:0]  r_cache_valid[WAY_NUM-1:0];
  logic [TAG_WIDTH-1:0]         r_cache_tag[WAY_NUM-1:0][LINE_NUM_PER_WAY-1:0];
  logic [DATA_WIDTH-1:0]        r_cache_line[WAY_NUM-1:0][LINE_NUM_PER_WAY-1:0][LINE_SIZE-1:0];

  // Killmask
  logic [WAY_NUM-1:0]           w_killmask;
  logic [WAY_NUM-1:0]           r_killmask = 1;

  // Rename Signal
  logic [TAG_WIDTH-1:0]         w_tag;
  logic [INDEX_WIDTH-1:0]       w_index;
  logic [LINEOFFSET_WIDTH-1:0]  w_lineoffset;
  always_comb begin
    w_tag           = i_load_addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
    w_index         = i_load_addr[INDEX_WIDTH+LINEOFFSET_WIDTH-1:LINEOFFSET_WIDTH];
    w_lineoffset    = i_load_addr[LINEOFFSET_WIDTH-1:0];
  end

  // Hit Check Logic
  generate 
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : HIT_CHECK_LOGIC
      always_comb begin
        w_hitway[way] = r_cache_valid[way][w_index] & (r_cache_tag[way][w_index] == w_tag);
      end
    end
  endgenerate
  assign w_miss = ~|w_hitway;

  always_ff @(posedge i_clk) begin
    r_hitway    <=  w_hitway;
    r_miss      <=  w_miss;
  end

  // Fetch Logic
  // Store Data to Cache
  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : FETCH_LOGIC
      always_comb begin
        if(w_miss && r_killmask[way] && i_fetch_valid) begin
          w_cache_valid[way]    = 1'b1;
          w_cache_tag[way]      = w_tag;
          w_cache_line[way]     = i_fetch_data;
        end else begin
          w_cache_valid[way]    = r_cache_valid[way][w_index];
          w_cache_tag[way]      = r_cache_tag[way][w_index];
          w_cache_line[way]     = r_cache_line[way][w_index];
        end
      end
    end
  endgenerate

  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : FETCH_TO_CACHE
      always_ff @(posedge i_clk) begin
        r_cache_valid[way][w_index] <= w_cache_valid[way];
        r_cache_tag[way][w_index]   <= w_cache_tag[way];
        r_cache_line[way][w_index]  <= w_cache_line[way];
      end
    end
  endgenerate

  // Send Data to Processor
  always_comb begin
    if(~o_load_valid | i_load_ready) begin
      if(r_miss) begin
        w_o_load_data   = i_fetch_data[w_lineoffset];
        w_o_load_valid  = i_fetch_valid;
      end else begin
        w_o_load_data   = w_rdata;
        w_o_load_valid  = i_load_valid;
      end
    end else begin
      w_o_load_data     = o_load_data;
      w_o_load_valid    = o_load_valid;
    end
  end

  always_ff @(posedge i_clk) begin
    o_load_data     <= w_o_load_data;
    o_load_valid    <= w_o_load_valid;
  end

  // Send Address to Cache
  always_comb begin
    if((~o_fetch_valid | i_fetch_ready) && r_miss) begin
      w_o_fetch_valid   = i_load_valid;
      w_o_fetch_addr    = i_load_addr;
    end else begin
      w_o_fetch_valid   = o_fetch_valid;
      w_o_fetch_addr    = o_fetch_addr;
    end
  end

  always_ff @(posedge i_clk) begin
    o_fetch_valid   <= w_o_fetch_valid;
    o_fetch_addr    <= w_o_fetch_addr;
  end
  
  // Cache Algorithm
  generate 
    if(WAY_NUM < 2) begin
      always_comb begin
        w_killmask <= r_killmask;
      end
    end else begin
      always_comb begin
        w_killmask = {r_killmask[WAY_NUM-2:0], r_killmask[WAY_NUM-1]};
      end
    end
  endgenerate

  always_ff @(posedge i_clk) begin
    r_killmask  <= w_killmask;
  end

  // Load Logic 
  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : LOAD_LOGIC
      always_comb begin
        w_rdataway[way] = r_cache_line[way][w_index][w_lineoffset];
      end
    end
  endgenerate

  // Extract Hit Data
  KVPriorityTree #(
    .DATA_WIDTH (DATA_WIDTH ),
    .DATA_NUM   (WAY_NUM    )
  ) SelectReadDataWay (
    .i_datas    (w_rdataway ),
    .i_valid    (w_hitway   ),
    .o_data     (w_rdata    )
  );


  // Store Logic
  always_comb begin

  end


  // Write Logic
  always_comb begin

  end

endmodule
