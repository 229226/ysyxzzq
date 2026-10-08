# npc/yosys/test/ 下各模块 STA 测试的统一入口（实现见 run_all.sh）。
#   make                  并发跑全部，最新结果写进 build/sta_summary.csv
#   make JOBS=16          调并发（默认 8）
#   make TESTS="ALU EXU"  只跑指定的几个
#   make record           跑完顺便把这次结果追加到 doc/sta_summary.csv
#   make save             不重跑，直接把当前结果追加到记录表
#   make summary          不重跑，只按现有产物重打汇总
#   make log              打印记录表
#   make list             列出所有测试
#   make clean            清掉各测试的 result/（STA 结果一起删）
JOBS  ?= 16
TESTS ?= $(patsubst %/Makefile,%,$(wildcard */Makefile))

NPC_DIR = $(abspath $(CURDIR)/../..)
STAGE   = $(NPC_DIR)/build/sta_summary.csv
LOG     = $(NPC_DIR)/doc/sta_summary.csv

all run:
	./run_all.sh -j $(JOBS) $(TESTS)

record:
	./run_all.sh -j $(JOBS) -r $(TESTS)

save:
	./run_all.sh -s -r $(TESTS)

summary:
	./run_all.sh -s $(TESTS)

log:
	@[ -f $(LOG) ] && cat $(LOG) || echo "还没有记录表，先跑 make record"

list:
	@echo "可跑的测试: $(TESTS)"

clean:
	@for d in $(TESTS); do \
		printf "clean %-8s" "$$d"; \
		$(MAKE) -s -C $$d clean && echo "OK"; \
		rm -f $$d/run.log; \
	done
	@rm -f $(STAGE)

.PHONY: all run record save summary log list clean
