#ifndef __PMEM_HPP_
#define __PMEM_HPP_

#include "common.hpp"

#define RESETADDR       0x80000000
#define PMEM_SIZE       0x01000000

int pmem_read(int raddr);
void pmem_write(int waddr, int wdata, char wmask);

void* PMEM_Get_PADDR();

#endif