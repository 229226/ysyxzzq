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
#define ADDR_SDRAM  0xa0000000
#define LEN_SDRAM   0x08000000
#define ADDR_UART   0x10000000
#define LEN_UART    0x00001000
#define ADDR_CLINT  0x02000000
#define LEN_CLINT   0x00010000

typedef enum MMIO_RW {OR,OW,RAW} MMIO_RW;

typedef struct YSYXSOC_MMIO {
    paddr_t addr;
    uint32_t lenth;
    uint8_t *mem;
    MMIO_RW access;
    // 设备自定义的读写行为，offset 为相对 addr 的偏移。
    // 为 NULL 时退化为对 mem 的普通内存访问（ROM/RAM 类设备用这种）。
    word_t (*read)(paddr_t offset, int len);
    void   (*write)(paddr_t offset, int len, word_t data);
} YSYXSOC_MMIO;

YSYXSOC_MMIO ysyx_mmio_find(paddr_t addr);
void ysyxsoc_mmio_init();
int ysyxsoc_add(YSYXSOC_MMIO mmio);
word_t ysyxsoc_read(paddr_t addr, int len);
void ysyxsoc_write(paddr_t addr, int len, word_t data);

#endif