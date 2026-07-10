#include <platform/ysyxsoc/ysyxsoc_sram.h>

static uint8_t ysyx_sram_mem [LEN_SRAM] = {0};

void ysyxsoc_sram_init(){
    YSYXSOC_MMIO ysyx_sram = {
    .addr = ADDR_SRAM,
    .lenth = LEN_SRAM,
    .mem = ysyx_sram_mem,
    .access = RAW
    };

    ysyxsoc_add(ysyx_sram);
}