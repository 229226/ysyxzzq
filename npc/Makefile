TOP_NAME = ysyxSoCTop

VERILATOR = verilator
VERILATOR_FLAGS += -MMD --build -cc --trace-fst -O3 --autoflush

GDB = gdb
VALGRIND = valgrind
GTKWAVE = gtkwave

NPC_PATH = $(abspath $(NPC_HOME))

WORK_PATH = $(pwd)
BUILD_PATH = $(WORK_PATH)./build
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

LIBS = -lreadline

WAVE_FILE = $(BUILD_PATH)/waveform.fst

CFLAGS += -Wall -DTOP_NAME=V$(TOP_NAME)
CFLAGS += -I$(CINC_PATH) -I$(CINC_PATH)/io -I$(CINC_PATH)/trace
CFLAGS += $(LIBS)

LDFLAGS += -lreadline

ARGS ?=
IMG ?=

all: $(BIN)

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

LIBCAPSTONE = $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
CFLAGS += -I $(NEMU_HOME)/tools/capstone/repo/include
csrc/disasm.c: $(LIBCAPSTONE)
$(LIBCAPSTONE):
	$(MAKE) -C $(NEMU_HOME)tools/capstone

$(BIN):$(VSRC) $(CSRC) $(OBJ_DIR)
	@rm -rf $(OBJ_DIR)
	@$(VERILATOR) $(VERILATOR_FLAGS)\
		--top-module $(TOP_NAME)\
		$(VSRC) $(CSRC) \
		$(SOC_VINC_PATH)\
		$(addprefix -CFLAGS ,$(CFLAGS))\
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
