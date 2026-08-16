MY_PROJ_PATH ?= $(NPC_HOME)
DESIGN ?= ysyx_25080209
SDC_FILE ?= $(MY_PROJ_PATH)/gcd.sdc
RTL_FILES ?= $(shell find $(MY_PROJ_PATH)/vsrc -name "*.v")
export CLK_FREQ_MHZ ?= 5000
PDK = nangate45

PROJ_PATH = $(shell pwd)
SHELL := /bin/bash

IEDA = $(YOSYS_HOME)/bin/iEDA

RESULT_PATH = $(PROJ_PATH)/result
RESULT_DIR = $(PROJ_PATH)/result/$(DESIGN)-$(CLK_FREQ_MHZ)MHz

SCRIPT_DIR = $(YOSYS_HOME)/scripts
NETLIST_SYN_V   = $(RESULT_DIR)/$(DESIGN).netlist.syn.v
NETLIST_FIXED_V = $(RESULT_DIR)/$(DESIGN).netlist.fixed.v
TIMING_RPT = $(RESULT_DIR)/$(DESIGN).rpt

init:
	bash -c "$$(wget -O - https://ysyx.oscc.cc/slides/resources/scripts/init-yosys-sta.sh)"

syn: $(NETLIST_SYN_V)
$(NETLIST_SYN_V): $(RTL_FILES) $(SCRIPT_DIR)/yosys.tcl
	mkdir -p $(@D)
	echo tcl $(SCRIPT_DIR)/yosys.tcl $(DESIGN) $(PDK) \"$(RTL_FILES)\" $@ | yosys -l $(@D)/yosys.log -s -

fix-fanout: $(NETLIST_FIXED_V)
$(NETLIST_FIXED_V): $(SCRIPT_DIR)/fix-fanout.tcl $(SDC_FILE) $(NETLIST_SYN_V)
	set -o pipefail && $(IEDA) -script $^ $(DESIGN) $(PDK) $@ 2>&1 | tee $(RESULT_DIR)/fix-fanout.log
	echo tcl $(SCRIPT_DIR)/yosys-area.tcl $(DESIGN) $(PDK) $@ | yosys -l $(@D)/yosys-fixed.log -s -

sta: $(TIMING_RPT)
$(TIMING_RPT): $(SCRIPT_DIR)/sta.tcl $(SDC_FILE) $(NETLIST_FIXED_V)
	set -o pipefail && $(IEDA) -script $^ $(DESIGN) $(PDK) 2>&1 | tee $(RESULT_DIR)/sta.log

svg:
	yosys -p "read_verilog $(NETLIST_SYN_V); proc; opt; write_json $(RESULT_PATH)/output.json"
	netlistsvg $(RESULT_PATH)/output.json -o $(RESULT_PATH)/output.svg

show:
	yosys -p "read_verilog $(RTL_FILES) ; hierarchy -top top; proc; opt; show"

clean:
	-rm -rf result/

.PHONY: init syn fix-fanout sta svg show clean 