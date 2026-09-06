#include "mrom.hpp"

static uint8_t mrom[MROM_SIZE];

extern "C" void mrom_read(int32_t addr, int32_t *data) {
    *data = *(int32_t *)((uint64_t)mrom+(addr&0xfffffffC));
}