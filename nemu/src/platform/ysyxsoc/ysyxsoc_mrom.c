#include <platform/ysyxsoc/ysyxsoc_mrom.h>

static uint8_t ysyx_mrom_mem [EADDR_MROM-ADDR_MROM+1] = {0};

void ysyxsoc_mrom_init(){
    YSYXSOC_MMIO ysyx_mrom = {
    .addr = ADDR_MROM,
    .eaddr = EADDR_MROM,
    .mem = ysyx_mrom_mem,
    .mask = 0x00000fff,
    .access = OR
    };

    ysyxsoc_add(ysyx_mrom);
}