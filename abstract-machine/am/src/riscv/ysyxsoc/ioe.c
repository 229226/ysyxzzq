#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

uint32_t mask_2_offset(uint32_t mask){
    for (int i = 0; i < 32; i++)
    {
        if(((mask >> i) & 0x00000001) == 0x00000001) return i;
    }
    
    return 0;
}

void write_rw32(uintptr_t addr,uint32_t data,uint32_t mask){
    uint32_t rdata = inl(addr);
    //clear wdata reg
    rdata = rdata & (~mask);
    outl(addr,rdata | ((data << mask_2_offset(mask)) & mask));
}

uint32_t read_rw32(uintptr_t addr,uint32_t mask){
    return ((inl(addr)&mask) >> mask_2_offset(mask));
}

void __uart_init();
void __spi_flash_init();
uint32_t flash_read(uint32_t addr);

void ioe_read(int reg, void *buf){
    *((uint32_t*)buf) = flash_read((uint32_t)reg);
}

bool ioe_init(){
    __spi_flash_init();
    __uart_init();
    return true;
}