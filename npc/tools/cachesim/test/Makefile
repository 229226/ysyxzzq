CXX       ?= g++
CXXFLAGS  ?= -O2 -std=c++14 -Wall
CACHESIM  ?= ../cachesim

all: gen_trace
	./gen_trace

gen_trace: gen_trace.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^

# 生成测试数据并逐个跑 cachesim 对比 3C 结果
check: all
	sh run_tests.sh

clean:
	rm -f gen_trace *.bin.bz2 cases.txt

.PHONY: all check clean
