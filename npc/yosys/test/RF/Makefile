MY_PROJ_PATH  ?= $(NPC_HOME)
DESIGN        ?= RF_test
CLK_FREQ_MHZ  ?= 5000

VSRC_PATH	= $(MY_PROJ_PATH)/vsrc
RTL_FILES	?= $(VSRC_PATH)/RegisterFile.v

TEST_PATH	= $(shell pwd)
RTL_FILES	+= $(TEST_PATH)/RF_test.v

export MY_PROJ_PATH DESIGN CLK_FREQ_MHZ

include $(NPC_HOME)/yosys/yosys-sta.mk