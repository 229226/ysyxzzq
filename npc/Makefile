TOP_NAME = ysyxSoCFull

VERILATOR = verilator
# 并行编译，使用所有 CPU 核心；自动 lint 关闭；拆分输出文件
NPROC ?= $(shell nproc 2>/dev/null || echo 1)
VERILATOR_FLAGS += -MMD --build -cc --trace-fst -O3 --autoflush
VERILATOR_FLAGS += -j $(NPROC)
#VERILATOR_FLAGS += --no-lint
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

#npc
VSRC_PATH = $(NPC_PATH)/vsrc
CSRC_PATH = $(NPC_PATH)/csrc
CINC_PATH = $(NPC_PATH)/include
VSRC = $(shell find $(VSRC_PATH) -name "*.v")
CSRC = $(shell find $(CSRC_PATH) -name "*.cpp")
HEADERS = $(shell find $(CINC_PATH) -name "*.hpp")

#SoC
SOC_PATH = $(abspath $(NPC_HOME)/../ysyxSoC)

VERILATOR_FLAGS += --timescale "1ns/1ns" --no-timing

SOC_VSRC_PATH = $(SOC_PATH)/perip
SOC_VINC_PATH = -I$(SOC_PATH)/perip/uart16550/rtl
SOC_VINC_PATH += -I$(SOC_PATH)/perip/spi/rtl
VSRC += $(shell find $(SOC_VSRC_PATH) -name "*.v")
VSRC += $(SOC_PATH)/build/ysyxSoCFull.v

#nvboard
INC_PATH ?=
NXDC_FILES = constr/ysyxSoC.nxdc

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_PATH)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES) | $(BUILD_PATH)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $(NXDC_FILES) $@

CSRC += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

#readline
LIBS = -lreadline
LDFLAGS += -lreadline

#capstone
LIBCAPSTONE = $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
CXXFLAGS += -I$(NEMU_HOME)/tools/capstone/repo/include
csrc/disasm.c: $(LIBCAPSTONE)
$(LIBCAPSTONE):
	$(MAKE) -C $(NEMU_HOME)tools/capstone

WAVE_FILE = $(BUILD_PATH)/waveform.fst

CXXFLAGS += -Wall -DTOP_NAME=V$(TOP_NAME)
CXXFLAGS += -I$(CINC_PATH) -I$(CINC_PATH)/io -I$(CINC_PATH)/trace -I$(INC_PATH)
CXXFLAGS += $(LIBS)

ARGS ?=
IMG ?=

$(BUILD_PATH):
	@mkdir -p $(BUILD_PATH)

$(BIN): $(VSRC) $(CSRC) $(HEADERS) $(NVBOARD_ARCHIVE)
	@$(VERILATOR) $(VERILATOR_FLAGS)\
		--top-module $(TOP_NAME)\
		$(VSRC) $(CSRC) $(NVBOARD_ARCHIVE)\
		$(SOC_VINC_PATH)\
		$(addprefix -CFLAGS ,$(CXXFLAGS))\
		$(addprefix -LDFLAGS ,$(LDFLAGS))\
		--Mdir $(OBJ_DIR)		\
		--exe -o $(abspath $(BIN))

NPC_EXEC := $(BIN) $(ARGS) $(IMG)

YOSYS_PROJ_DIR ?= $(abspath $(NPC_HOME)/yosys)


#fill_excel
FILL_EXCEL_SCRIPT ?= $(NPC_PATH)/tools/fill_excel.py
EXCEL_FILE ?= $(abspath $(NPC_PATH)/doc/NPC性能评估结果.xlsx)
SIM_LOG = $(BUILD_PATH)/npc.log

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
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
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

clean: 
	rm -rf $(BUILD_PATH)

.PHONY: all run gdb valgrind sim sta fill_excel clean
include ../Makefile