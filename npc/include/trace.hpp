#ifndef __TRACE_HPP_
#define __TRACE_HPP_

#include "common.hpp"

void trace_init();
void itrace_print(int ins);

void itrace_rb_pr();

void mtrace_pread(uint32_t addr,uint32_t data);
void mtrace_pwrite(uint32_t addr,uint32_t data);

#endif