#include "sdram.hpp"
#include "trace.hpp"

static uint8_t sdram[SDRAM_SIZE];

extern "C" void sdram_read(uint32_t addr, uint8_t *data) {
    *data = *((uint8_t *)((uint64_t)sdram + addr));
    #ifdef MTRACE_CONFIG
        mtrace_read(SDRAM_ADDR_BASE + addr,*data,1);
    #endif
}

extern "C" void sdram_write(uint32_t addr, uint8_t data) {
    *((uint8_t *)((uint64_t)sdram + addr)) = data;
    #ifdef MTRACE_CONFIG
        mtrace_write(SDRAM_ADDR_BASE + addr,data,1);
    #endif
}