#ifndef __TRACE_HPP_
#define __TRACE_HPP_

#include "common.hpp"

#define log_write 

void trace_init();
void itrace_print(int ins);

void itrace_rb_pr();

void mtrace_read(uint32_t addr,uint32_t data,int data_wid);
void mtrace_write(uint32_t addr,uint32_t data,int data_wid);

#endif