#include "psram.hpp"
#include "trace.hpp"

static uint8_t psram[PSRAM_SIZE];

extern "C" void psram_read(uint32_t addr, uint8_t *data) {
    *data = *((uint8_t *)((uint64_t)psram + addr));
    #ifdef MTRACE_CONFIG
        mtrace_read(PSRAM_ADDR_BASE + addr,*data,1);
    #endif
}

extern "C" void psram_write(uint32_t addr, uint8_t data) {
    *((uint8_t *)((uint64_t)psram + addr)) = data;
    #ifdef MTRACE_CONFIG
        mtrace_write(PSRAM_ADDR_BASE + addr,data,1);
    #endif
}