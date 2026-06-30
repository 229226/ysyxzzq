#ifndef YSYXSOC_H__
#define YSYXSOC_H__

#include ISA_H
#include <stdint.h>

#define SERIAL_ADDR_BASE    0x10000000
#define SPI_MASTER_ADDR_BASE 0x10001000

void write_rw32(uintptr_t addr,uint32_t data,uint32_t mask);
uint32_t read_rw32(uintptr_t addr,uint32_t mask);

#endif