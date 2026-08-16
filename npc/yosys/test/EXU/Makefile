MY_PROJ_PATH  ?= $(NPC_HOME)
DESIGN        ?= EXU_test
CLK_FREQ_MHZ  ?= 5000

VSRC_PATH	= $(MY_PROJ_PATH)/vsrc
RTL_FILES	?= $(VSRC_PATH)/ysyx_25080209_EXU.v
RTL_FILES	+= $(VSRC_PATH)/ysyx_25080209_ALU.v
RTL_FILES	+= $(VSRC_PATH)/MuxKeyWithDefault.v
RTL_FILES	+= $(VSRC_PATH)/MuxKeyInternal.v

TEST_PATH	= $(shell pwd)
RTL_FILES	+= $(TEST_PATH)/EXU_test.v

export MY_PROJ_PATH DESIGN CLK_FREQ_MHZ

include $(NPC_HOME)/yosys/yosys-sta.mk
