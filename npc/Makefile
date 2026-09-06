TOP_NAME ?= ysyxSoCFull
BOOT_PC ?= 30000000

VERILATOR = verilator
NPROC ?= $(shell nproc 2>/dev/null || echo 1)
VERILATOR_FLAGS += -MMD --build -cc --trace-fst -O3
VERILATOR_FLAGS += -j $(NPROC)
VERILATOR_FLAGS += --output-split 20000

# 检测并使用 ccache
CCACHE := $(shell which ccache 2>/dev/null)
ifneq ($(CCACHE),)
    CXX := $(CCACHE) $(CXX)
endif

GDB = gdb
VALGRIND = valgrind
GTKWAVE = gtkwave

NPC_PATH = $(abspath $(NPC_HOME))
WORK_PATH := $(shell pwd)
BUILD_PATH = $(WORK_PATH)/build
OBJ_DIR = $(BUILD_PATH)/obj_dir
BIN = $(BUILD_PATH)/$(TOP_NAME)

# 源代码路径
VSRC_PATH = $(NPC_PATH)/vsrc
CSRC_PATH = $(NPC_PATH)/csrc
CINC_PATH = $(NPC_PATH)/include
VSRC = $(shell find $(VSRC_PATH) -name "*.v")
CSRC = $(shell find $(CSRC_PATH) -name "*.cpp")
HEADERS = $(shell find $(CINC_PATH) -name "*.hpp")

# SoC
SOC_PATH = $(abspath $(NPC_HOME)/../ysyxSoC)
VERILATOR_FLAGS += --timescale "1ns/1ns" --no-timing
SOC_VSRC_PATH = $(SOC_PATH)/perip
SOC_VINC_PATH = -I$(SOC_PATH)/perip/uart16550/rtl
SOC_VINC_PATH += -I$(SOC_PATH)/perip/spi/rtl
VSRC += $(shell find $(SOC_VSRC_PATH) -name "*.v")
VSRC += $(SOC_PATH)/build/ysyxSoCFull.v

# NVBoard
INC_PATH ?=
NXDC_FILES = constr/ysyxSoC.nxdc
SRC_AUTO_BIND = $(abspath $(BUILD_PATH)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES) | $(BUILD_PATH)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $(NXDC_FILES) $@

ifeq ($(TOP_NAME),ysyxSoCFull)
CSRC += $(SRC_AUTO_BIND)
endif

include $(NVBOARD_HOME)/scripts/nvboard.mk

# readline
LIBS = -lreadline
LDFLAGS += -lreadline

# capstone
LIBCAPSTONE = $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
CXXFLAGS += -I$(NEMU_HOME)/tools/capstone/repo/include
csrc/disasm.c: $(LIBCAPSTONE)
$(LIBCAPSTONE):
	$(MAKE) -C $(NEMU_HOME)/tools/capstone

WAVE_FILE = $(BUILD_PATH)/waveform.fst

# ========== 编译选项 ==========
CXXFLAGS += -Wall -DTOP_NAME=V$(TOP_NAME)

# 根据 TOP_NAME 定义对应的 C++ 宏
ifeq ($(TOP_NAME),ysyxSoCFull)
    CXXFLAGS += -DYSYXSOC_CONFIG
else ifeq ($(TOP_NAME),NPC)
    CXXFLAGS += -DNPC_CONFIG
else
    $(error Unsupported TOP_NAME: $(TOP_NAME))
endif

CXXFLAGS += -I$(CINC_PATH) -I$(CINC_PATH)/io -I$(CINC_PATH)/trace -I$(INC_PATH)
CXXFLAGS += $(LIBS)

ARGS ?=
IMG ?=

$(BUILD_PATH):
	@mkdir -p $(BUILD_PATH)

$(BIN): $(VSRC) $(CSRC) $(HEADERS) $(NVBOARD_ARCHIVE) update-boot-pc
	@$(VERILATOR) $(VERILATOR_FLAGS)\
		--top-module $(TOP_NAME)\
		$(VSRC) $(CSRC) $(NVBOARD_ARCHIVE)\
		$(SOC_VINC_PATH)\
		$(addprefix -CFLAGS ,$(CXXFLAGS))\
		$(addprefix -LDFLAGS ,$(LDFLAGS))\
		--Mdir $(OBJ_DIR)\
		--exe -o $(abspath $(BIN))

NPC_EXEC := $(BIN) $(ARGS) $(IMG)

YOSYS_PROJ_DIR ?= $(abspath $(NPC_HOME)/yosys)

FILL_EXCEL_SCRIPT ?= $(NPC_PATH)/tools/fill_excel.py
EXCEL_FILE ?= $(abspath $(NPC_PATH)/doc/NPC性能评估结果.xlsx)
SIM_LOG = $(BUILD_PATH)/npc.log

IFU_FILE := $(VSRC_PATH)/ysyx_25080209_IFU.v
update-boot-pc:
	@if grep -qE "^[[:space:]]*parameter BOOT_PC[[:space:]]=[[:space:]]*32'h$(BOOT_PC);[[:space:]]*$$" \
		$(IFU_FILE); then \
		echo ">>> BOOT_PC = 0x$(BOOT_PC), unchanged."; \
	else \
		echo ">>> BOOT_PC changed -> 0x$(BOOT_PC)"; \
		sed -i -E "s/^[[:space:]]*parameter BOOT_PC.*/    parameter BOOT_PC = 32'h$(BOOT_PC);/" \
			$(IFU_FILE); \
	fi

all: $(BIN)

run: $(BIN)
	$(call git_commit, "run RTL")
	$(NPC_EXEC)

gdb: $(BIN)
	$(call git_commit, "gdb RTL")
	$(GDB) -s $(BIN) --args $(NPC_EXEC)

valgrind: $(BIN)
	$(VALGRIND) $(NPC_EXEC)

sim: $(BIN)
	$(call git_commit, "sim RTL")
	$(NPC_EXEC)
	$(GTKWAVE) $(WAVE_FILE)

sta:
	$(MAKE) -C $(YOSYS_PROJ_DIR) sta

fill_excel:
	@echo "Filling Excel with performance data..."
	@if [ ! -f $(FILL_EXCEL_SCRIPT) ]; then \
		echo "Error: script $(FILL_EXCEL_SCRIPT) not found."; \
		exit 1; \
	fi
	@python3 $(FILL_EXCEL_SCRIPT) $(SIM_LOG) $(EXCEL_FILE)
	@echo "Excel updated at $(EXCEL_FILE)"

#进行perf仿真时需要开启NPC的TRACE功能以输出数据
perf: sta
	$(MAKE) -C $(NPC_HOME)/../am-kernels/benchmarks/microbench ARCH=riscv32e-npcsoc run mainargs=train

clean:
	rm -rf $(BUILD_PATH)

# ========== Flame Graph ==========
PERF_DATA  ?= $(BUILD_PATH)/perf.data
FLAME_SVG  ?= $(BUILD_PATH)/flamegraph.svg

flame: $(BIN)
	@# 检查依赖
	@if [ -z "$(FLAMEG_HOME)" ]; then \
		echo "ERROR: FLAMEG_HOME is not set. Please export it, e.g., export FLAMEG_HOME=/path/to/FlameGraph"; \
		exit 1; \
	fi
	@if ! command -v perf >/dev/null 2>&1; then \
		echo "ERROR: perf not found. Please install linux-tools-common and linux-tools-generic"; \
		exit 1; \
	fi
	@echo "=== Recording performance with perf (cpu-clock sampling) ==="
	perf record -g -e cpu-clock -F 1000000 --call-graph fp -o $(PERF_DATA) -- $(NPC_EXEC)
	@echo "=== Generating flame graph ==="
	perf script -i $(PERF_DATA) | \
		$(FLAMEG_HOME)/stackcollapse-perf.pl | \
		$(FLAMEG_HOME)/flamegraph.pl > $(FLAME_SVG)
	@echo "=== Flame graph saved to: $(FLAME_SVG) ==="
	@echo "You can view it with: xdg-open $(FLAME_SVG)  (or any browser)"
	@# 检查文件大小，若太小可能没有样本
	@if [ ! -s $(FLAME_SVG) ] || [ $$(stat -c%s $(FLAME_SVG)) -lt 1000 ]; then \
		echo "WARNING: Flame graph is very small or empty. Try running 'perf script -i $(PERF_DATA) | head -20' to inspect."; \
	fi

clean-flame:
	rm -f $(PERF_DATA) $(FLAME_SVG)

# ==============================================

.PHONY: all run gdb valgrind sim sta fill_excel clean flame clean-flame
include ../Makefile