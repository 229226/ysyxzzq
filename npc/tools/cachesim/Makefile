CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++14 -Wall
INCLUDES  = -Iinclude

SRCS   = src/main.cpp src/cachesim.cpp
OBJS   = $(SRCS:.cpp=.o)
TARGET = cachesim

# 默认按 NPC icache 的配置跑：块大小 32 位(4B)、16 个块、直接映射，共 64B
TRACE  ?= ../../pctrace.bin.bz2
SIZE   ?= 64
BLOCK  ?= 4
ASSOC  ?= 1
WINDOW ?= 256
REF	   ?= 

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

%.o: %.cpp include/cachesim.hpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c -o $@ $<

# 跑一次仿真。参数可以覆盖，例如：
#   make run SIZE=512 BLOCK=32 ASSOC=2
#   make run WINDOW=256          前瞻窗口调大，全相联基准更接近最优
#   make run WINDOW=0            退回纯 LRU 基准
#   make run TRACE=/path/to/other.bin.bz2
run: $(TARGET)
	./$(TARGET) -i $(TRACE) -s $(SIZE) -b $(BLOCK) -a $(ASSOC) -K $(WINDOW) $(REF)

# 扫一组配置做对比（每个配置会重新解压一遍 trace，比较慢）
sweep: $(TARGET)
	./$(TARGET) -i $(TRACE) -S

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all run sweep clean
