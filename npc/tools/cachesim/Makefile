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
BLOCK  ?= 4
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

# 扫一组配置做对比（每个配置会重新解压一遍 trace，比较慢）
sweep: $(TARGET)
	./$(TARGET) -i $(TRACE) -S

# 跑测试程序，数据生成在 test/build/ 下
check: $(TARGET)
	$(MAKE) -C test check

clean:
	rm -rf $(BUILD)

.PHONY: all run sweep check clean
