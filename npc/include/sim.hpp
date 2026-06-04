#ifndef __SIM_HPP_
#define __SIM_HPP_

#include <verilated.h>
#include <verilated_fst_c.h>
#include <VysyxSoCTop.h>
//DPI-C
#include "svdpi.h"
#include <VysyxSoCTop__Dpi.h>

#include "common.hpp"
#include "mem.hpp"

#define TOP_NAME VysyxSoCTop

void sim_init();
void sim_exit();
void sim_clock();
void step_and_dump();
int sim_exec_half();
int sim_exec_one();
int sim_exec(int turns);

#endif