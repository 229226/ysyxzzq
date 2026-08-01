TOP_NAME = ysyxSoCFull

VERILATOR = verilator
VERILATOR_FLAGS += -MMD --build -cc --trace-fst -O3 --autoflush

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
$(SRC_AUTO_BIND): $(NXDC_FILES) $(BUILD_PATH)
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

all: $(BIN)

$(BUILD_PATH):
	@mkdir -p $(BUILD_PATH)

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

$(BIN):$(VSRC) $(CSRC) $(OBJ_DIR) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	@$(VERILATOR) $(VERILATOR_FLAGS)\
		--top-module $(TOP_NAME)\
		$(VSRC) $(CSRC) $(NVBOARD_ARCHIVE)\
		$(SOC_VINC_PATH)\
		$(addprefix -CFLAGS ,$(CXXFLAGS))\
		$(addprefix -LDFLAGS ,$(LDFLAGS))\
		--Mdir $(OBJ_DIR)		\
		--exe -o $(abspath $(BIN))

NPC_EXEC := $(BIN) $(ARGS) $(IMG)

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

clean: 
	rm -rf $(BUILD_PATH)

.PHONY: all sim run gdb valgrind
include ../Makefile
