CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++14 -Wall

# src/ 下的源文件自动收集，.o 名字由源文件名推出，和生成器、测试数据
# （*.bin.bz2）、cases.txt 一起都放进 build/
BUILD    = build
SRCS     = $(wildcard src/*.cpp)
OBJS     = $(addprefix $(BUILD)/,$(notdir $(SRCS:.cpp=.o)))
GEN      = $(BUILD)/gen_trace
CACHESIM ?= ../build/cachesim

all: $(GEN)
	./$(GEN) $(BUILD)

$(GEN): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

$(BUILD)/%.o: src/%.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD):
	mkdir -p $(BUILD)

# 生成测试数据并逐个跑 cachesim 对比 3C 结果
check: all
	sh run_tests.sh

clean:
	rm -rf $(BUILD)

.PHONY: all check clean
