#ifndef __SIM_HPP_
#define __SIM_HPP_

#include <verilated.h>
#include <verilated_fst_c.h>
#include <Vysyx_25080209_npc.h>
//DPI-C
#include "svdpi.h"
#include <Vysyx_25080209_npc__Dpi.h>

#include "common.hpp"
#include "mem.hpp"

void sim_init();
void sim_exit();
void sim_clk();
void step_and_dump();
int sim_exec_half();
int sim_exec_one();
int sim_exec(int turns);

#endif