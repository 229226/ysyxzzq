#include <platform/ysyxsoc/ysyxsoc_mrom.h>

static uint8_t ysyx_mrom_mem [LEN_MROM] = {0};

void ysyxsoc_mrom_init(){
    YSYXSOC_MMIO ysyx_mrom = {
    .addr = ADDR_MROM,
    .lenth = LEN_MROM,
    .mem = ysyx_mrom_mem,
    .access = OR
    };

    ysyxsoc_add(ysyx_mrom);
}