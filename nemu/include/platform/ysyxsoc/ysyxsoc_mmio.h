#ifndef __YSYXSOC_MMIO_H__
#define __YSYXSOC_MMIO_H__

#include <common.h>

#define YSYX_MMIO_MNUM 16

#define ADDR_MROM   0x20000000
#define LEN_MROM    0x00001000
#define ADDR_SRAM   0x0f000000
#define LEN_SRAM    0x00002000
#define ADDR_FLASH  0x30000000
#define LEN_FLASH   0x01000000
#define ADDR_PSRAM  0x80000000
#define LEN_PSRAM   0x00400000

typedef enum MMIO_RW {OR,OW,RAW} MMIO_RW;

typedef struct YSYXSOC_MMIO {
    paddr_t addr;
    uint32_t lenth;
    uint8_t *mem;
    MMIO_RW access;
} YSYXSOC_MMIO;

YSYXSOC_MMIO ysyx_mmio_find(paddr_t addr);
void ysyxsoc_mmio_init();
int ysyxsoc_add(YSYXSOC_MMIO mmio);
word_t ysyxsoc_read(paddr_t addr, int len);
void ysyxsoc_write(paddr_t addr, int len, word_t data);

#endif