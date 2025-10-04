#ifndef __MEM_HPP_
#define _MEM_HPP_

#include "common.hpp"

#define paddr_t uint32_t
#define RESETADDR 0x80000000

extern int mem_size;

void init_mem(char *file_img);
extern "C" int pmem_read(int raddr);
extern "C" void pmem_write(int waddr, int wdata, char wmask);

int mmio_check(int addr);

#endif