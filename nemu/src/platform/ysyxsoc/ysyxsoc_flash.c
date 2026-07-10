#include <platform/ysyxsoc/ysyxsoc_flash.h>

static uint8_t ysyx_flash_mem [LEN_FLASH] = {0};

void ysyxsoc_flash_init(){
    YSYXSOC_MMIO ysyx_flash = {
    .addr = ADDR_FLASH,
    .lenth = LEN_FLASH,
    .mem = ysyx_flash_mem,
    .access = OR
    };

    ysyxsoc_add(ysyx_flash);
}