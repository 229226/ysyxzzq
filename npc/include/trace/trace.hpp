#ifndef __TRACE_HPP_
#define __TRACE_HPP_

#include "common.hpp"
#include <cstdarg>
#include <string>

void trace_init();
void itrace_print(int ins);
void itrace_rb_pr();
void mtrace_read(uint32_t addr,uint32_t data,int data_wid);
void mtrace_write(uint32_t addr,uint32_t data,int data_wid);

void trace_printf(const char *format, ...);

// guest 经 UART 打印的全部内容（trace.cpp 里 uart_putchar 逐个字符收集），
// 供仿真结束后解析 microbench 的耗时/得分
const std::string &uart_log();

#endif