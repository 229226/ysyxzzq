#include <platform/ysyxsoc/ysyxsoc_psram.h>

static uint8_t ysyx_psram_mem [LEN_PSRAM] = {0};

void ysyxsoc_psram_init(){
    YSYXSOC_MMIO ysyx_psram = {
    .addr = ADDR_PSRAM,
    .lenth = LEN_PSRAM,
    .mem = ysyx_psram_mem,
    .access = RAW
    };

    ysyxsoc_add(ysyx_psram);
}