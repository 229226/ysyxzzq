#include <platform/ysyxsoc/ysyxsoc_sdram.h>

static uint8_t ysyx_sdram_mem [LEN_SDRAM] = {0};

void ysyxsoc_sdram_init(){
    YSYXSOC_MMIO ysyx_sdram = {
    .addr = ADDR_SDRAM,
    .lenth = LEN_SDRAM,
    .mem = ysyx_sdram_mem,
    .access = RAW
    };

    ysyxsoc_add(ysyx_sdram);
}
