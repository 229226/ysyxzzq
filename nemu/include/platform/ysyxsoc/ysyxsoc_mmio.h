#ifndef __YSYXSOC_MMIO_H__
#define __YSYXSOC_MMIO_H__

#include <common.h>

#define YSYX_MMIO_MNUM 16

#define ADDR_MROM   0x20000000
#define EADDR_MROM  0x20000fff
#define ADDR_SRAM   0x0f000000
#define EADDR_SRAM  0x0f001fff

typedef enum MMIO_RW {OR,OW,RAW} MMIO_RW;

typedef struct YSYXSOC_MMIO {
    paddr_t addr,eaddr;
    uint8_t *mem;
    uint32_t mask;
    MMIO_RW access;
} YSYXSOC_MMIO;

void ysyxsoc_mmio_init();
int ysyxsoc_add(YSYXSOC_MMIO mmio);
word_t ysyxsoc_read(paddr_t addr, int len);
void ysyxsoc_write(paddr_t addr, int len, word_t data);

#endif