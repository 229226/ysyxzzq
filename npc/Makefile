TOP_NAME = ysyx_25080209_npc

VERILATOR = verilator
VERILATOR_FLAGS += -MMD --build -cc --trace-fst -O3

GDB = gdb
VALGRIND = valgrind
GTKWAVE = gtkwave

NPC_PATH = $(abspath $(NPC_HOME))

WORK_PATH = $(pwd)
BUILD_PATH = $(WORK_PATH)./build
OBJ_DIR = $(BUILD_PATH)/obj_dir
BIN = $(BUILD_PATH)/$(TOP_NAME)

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

VSRC_PATH = $(NPC_PATH)/vsrc
CSRC_PATH = $(NPC_PATH)/csrc
INC_PATH = $(NPC_PATH)/include
VSRC = $(shell find $(VSRC_PATH) -name "*.v")
CSRC = $(shell find $(CSRC_PATH) -name "*.cpp")

LIBS = -lreadline

WAVE_FILE = $(BUILD_PATH)/waveform.fst

CFLAGS += -Wall -DTOP_NAME=V$(TOP_NAME)
CFLAGS += -I$(INC_PATH) $(LIBS)

LDFLAGS += -lreadline

ARGS ?=

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
		$(addprefix -CFLAGS ,$(CFLAGS))\
		$(addprefix -LDFLAGS ,$(LDFLAGS))\
		--Mdir $(OBJ_DIR)		\
		--exe -o $(abspath $(BIN))
		
all: 

NPC_EXEC := $(BIN) $(ARGS)

run: $(BIN)
	$(call git_commit, "run RTL")
	$(NPC_EXEC)

gdb: $(BIN)
	$(call git_commit, "gdb RTL")
	$(GDB) -s $(BIN) --args $(NPC_EXEC)
	
valgrind: $(BIN)
	$(VALGRIND) $^ $(ARGS)

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(NPC_EXEC)
	$(GTKWAVE) $(WAVE_FILE)

clean: 
	rm -rf $(BUILD_PATH)

.PHONY: all sim run gdb valgrind
include ../Makefile
