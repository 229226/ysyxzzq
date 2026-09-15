#ifndef __UTILS_PCTRACE_H__
#define __UTILS_PCTRACE_H__

#include <common.h>

// 以二进制方式记录 guest 的 PC 轨迹。顺序执行（pc == 上一条 + 4）的 PC 序列
// 会被压成一段，每段只落一条记录：start_pc(u32) + count(u32)，小端序。
// 输出到 build/pctrace.bin。
void pctrace_record(vaddr_t pc);

// 写出最后一段并关闭文件，在 CPU 结束运行时调用
void pctrace_close();

#endif
