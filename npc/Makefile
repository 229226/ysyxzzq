TOP_NAME = ysyx_25080209_npc

VERILATOR = verilator
VERILATOR_FLAGS += -MMD --build -cc --trace-fst -O3

WAVE_FILE = $(BUILD_PATH)/waveform.fst
GTKWAVE = gtkwave

BUILD_PATH = ./build
OBJ_DIR = $(BUILD_PATH)/obj_dir
BIN = $(BUILD_PATH)/$(TOP_NAME)

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

VSRC_PATH = $(abspath ./vsrc)
CSRC_PATH = $(abspath ./csrc)
VSRC = $(shell find $(VSRC_PATH) -name "*.v")
CSRC = $(shell find $(CSRC_PATH) -name "*.cpp")

CFLAGS += -DTOP_NAME=V$(TOP_NAME)

$(BIN):$(VSRC) $(CSRC) $(OBJ_DIR)
	@rm -rf $(OBJ_DIR)
	@$(VERILATOR) $(VERILATOR_FLAGS)\
		--top-module $(TOP_NAME)\
		$(VSRC) $(CSRC)\
		$(addprefix -CFLAGS ,$(CFLAGS))\
		--Mdir $(OBJ_DIR)		\
		--exe -o $(abspath $(BIN))
		
all: 

run: $(BIN)
	@$^
	
sim: run
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(GTKWAVE) $(WAVE_FILE)

clean: 
	rm -rf $(BUILD_PATH)

.PHONY: all sim run
include ../Makefile
