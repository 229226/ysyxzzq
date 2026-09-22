CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++14 -Wall
INCLUDES  = -Iinclude

# src/ 下的源文件自动收集，.o 名字由源文件名推出、统一放进 build/
BUILD  = build
SRCS   = $(wildcard src/*.cpp)
OBJS   = $(addprefix $(BUILD)/,$(notdir $(SRCS:.cpp=.o)))
TARGET = $(BUILD)/cachesim

# 默认按 NPC icache 的配置跑：块大小 32 位(4B)、16 个块、直接映射，共 64B
TRACE  ?= ../../pctrace.bin.bz2
SIZE   ?= 64
BLOCK  ?= 64
ASSOC  ?= 1
WINDOW ?= 256
REF    ?=

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

$(BUILD)/%.o: src/%.cpp include/cachesim.hpp | $(BUILD)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c -o $@ $<

$(BUILD):
	mkdir -p $(BUILD)

# 跑一次仿真。参数可以覆盖，例如：
#   make run SIZE=512 BLOCK=32 ASSOC=2
#   make run WINDOW=256          前瞻窗口调大，全相联基准更接近最优
#   make run WINDOW=0            退回纯 LRU 基准
#   make run REF=-R              额外跑两倍窗口的参照，估计基准精度
#   make run TRACE=/path/to/other.bin.bz2
run: $(TARGET)
	./$(TARGET) -i $(TRACE) -s $(SIZE) -b $(BLOCK) -a $(ASSOC) -K $(WINDOW) $(REF)

# 扫一组配置做对比：多核并行跑，汇总成表格 + CSV（实现见 sweep.py）。
# 默认网格 512~16K × 16/32/64B 块 × 1/2/4 路，跑到 ../../result/cachesim/<时间戳>/ 下
# （已被 .gitignore 忽略）。
# 参数可以覆盖，例如：
#   make psweep                                全部核一起上
#   make psweep NPROC=8                        压到 8 路
#   make psweep SWEEP_ARGS="--size 512:4096 --assoc 1:4"
#   make psweep SWEEP_ARGS="--window 0,64,256 --size 2K --block 32 --assoc 2"
#   make psweep-dry                            只看网格和命令行，不真跑
# 注意两点：扫描期间不要重新 make（会覆盖正在执行的 build/cachesim）；
# 另外 `make psweep -j8` 的 -j8 是给 make 的，要改并发得用 NPROC=8
# （或 SWEEP_ARGS="-j 8"，它拼在后面，argparse 后者胜出）。
PY     ?= python3
NPROC  ?= $(shell nproc 2>/dev/null || echo 1)
SWEEP_ARGS ?=
PSWEEP  = $(PY) sweep.py -i $(abspath $(TRACE)) --cachesim $(abspath $(TARGET)) \
	-j $(NPROC) $(SWEEP_ARGS)

psweep: $(TARGET)
	$(PSWEEP)

psweep-dry: $(TARGET)
	$(PSWEEP) --dry-run

# 跑测试程序，数据生成在 test/build/ 下
check: $(TARGET)
	$(MAKE) -C test check

clean:
	rm -rf $(BUILD)

.PHONY: all run psweep psweep-dry check clean
