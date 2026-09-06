#include "flash.hpp"

static uint8_t flash[FLASH_SIZE];

extern "C" void flash_read(int32_t addr, int32_t *data) {
    *data = *(int32_t *)((uint64_t)flash+(addr&0xfffffffC));
}

void* Flash_Get_PADDR(){
    return (void *)flash;
}