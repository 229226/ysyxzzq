#include "sdram.hpp"
#include "trace.hpp"

static uint8_t sdram [2][SDRAM_SIZE];

extern "C" void sdram_read(uint32_t addr, uint8_t *data, uint8_t number) {
    *data = *((uint8_t *)((uint64_t)(sdram[number]) + addr));
    #ifdef MTRACE_CONFIG
        mtrace_read(SDRAM_ADDR_BASE + 
            ( ((addr&0xfffffffe) << 1) | (addr&0x00000001) | ((uint32_t)number << 1) )
            ,*data,1);
    #endif
}

extern "C" void sdram_write(uint32_t addr, uint8_t data, uint8_t number) {
    *((uint8_t *)((uint64_t)(sdram[number]) + addr)) = data;
    #ifdef MTRACE_CONFIG
        mtrace_write(SDRAM_ADDR_BASE +
            ( ((addr&0xfffffffe) << 1) | (addr&0x00000001) | ((uint32_t)number << 1) )
            ,data,1);
    #endif
}