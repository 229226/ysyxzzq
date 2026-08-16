MY_PROJ_PATH  ?= $(NPC_HOME)
DESIGN        ?= ADDER32_test
CLK_FREQ_MHZ  ?= 5000

VSRC_PATH	= $(MY_PROJ_PATH)/vsrc
RTL_FILES	?= 

TEST_PATH	= $(shell pwd)
RTL_FILES	+= $(TEST_PATH)/ADDER32_test.v

export MY_PROJ_PATH DESIGN CLK_FREQ_MHZ

include $(NPC_HOME)/yosys/yosys-sta.mk
