#include "psram.hpp"

static uint8_t psram[PSRAM_SIZE];

extern "C" void psram_read(int32_t addr, int32_t *data) {
    *data = *((int32_t *)((uint64_t)psram+(addr&0xfffffffC)));
}

extern "C" void psram_write(int32_t addr, int32_t data) {
    *((int32_t *)((uint64_t)psram+(addr&0xfffffffC))) = data;
}