KVCache:
	verilator --binary --trace KVCache_tb.sv ../rtl/KVPriorityTree.sv ../rtl/KVCache.sv ../beh/KVMemory_beh.sv
	cd obj_dir ; ./VKVCache_tb

KVMemory_beh:
	verilator --binary --trace KVMemory_beh_tb.sv ../beh/KVMemory_beh.sv
	cd obj_dir ; ./VKVMemory_beh_tb

KVPriorityTree:
	verilator --binary --trace KVPriorityTree_tb.sv ../rtl/KVPriorityTree.sv
	cd obj_dir ; ./VKVPriorityTree_tb
clean:
	rm -r obj_dir

view:
	gtkwave ./obj_dir/wave.vcd
