#include <platform/ysyxsoc/ysyxsoc_sram.h>

static uint8_t ysyx_sram_mem [EADDR_SRAM-ADDR_SRAM+1] = {0};

void ysyxsoc_sram_init(){
    YSYXSOC_MMIO ysyx_sram = {
    .addr = ADDR_SRAM,
    .eaddr = EADDR_SRAM,
    .mem = ysyx_sram_mem,
    .mask = 0x00ffffff,
    .access = RAW
    };

    ysyxsoc_add(ysyx_sram);
}