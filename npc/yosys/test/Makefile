
# npc/yosys/test/ 下各模块 STA 测试的统一入口（实现见 run_all.sh）。
#   make                  并发跑全部，最后汇总面积和频率
#   make JOBS=16          调并发（默认 8）
#   make TESTS="ALU EXU"  只跑指定的几个
#   make summary          不重跑，只按现有产物汇总
#   make list             列出所有测试
#   make clean            清掉各测试的 result/（STA 结果一起删）
JOBS  ?= 16
TESTS ?= $(patsubst %/Makefile,%,$(wildcard */Makefile))

all run:
	./run_all.sh -j $(JOBS) $(TESTS)

summary:
	./run_all.sh -s $(TESTS)

list:
	@echo "可跑的测试: $(TESTS)"

clean:
	@for d in $(TESTS); do \
		printf "clean %-8s" "$$d"; \
		$(MAKE) -s -C $$d clean && echo "OK"; \
		rm -f $$d/run.log; \
	done

.PHONY: all run summary list clean
