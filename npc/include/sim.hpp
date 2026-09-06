#ifndef __SIM_HPP_
#define __SIM_HPP_

#include <verilated.h>
#include <verilated_fst_c.h>

#ifdef NPC_CONFIG
#include <VNPC.h>
#include <VNPC__Dpi.h>
#elif defined(YSYXSOC_CONFIG)
#include <VysyxSoCFull.h>
#include <VysyxSoCFull__Dpi.h>
#else
#error "No valid configuration: please define NPC_CONFIG or YSYXSOC_CONFIG"
#endif

// DPI-C
#include "svdpi.h"

#include "common.hpp"
#include "mem.hpp"

void verilator_init(int argc, char *argv[]);

void sim_init();
void sim_exit();
void sim_clock();
void step_and_dump();
int sim_exec_half();
int sim_exec_one();
int sim_exec(int turns);

#endif