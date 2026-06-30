#include <ysyxsoc.h>
#include <am.h>

#define DIVL_ADDR       SERIAL_ADDR_BASE+0
#define DIVH_ADDR       SERIAL_ADDR_BASE+1

#define LCR_ADDR        SERIAL_ADDR_BASE+3
#define LCR_DIV         0b10000000
#define LCR_LEN_8BIT    0b00000011

void set_rw(uintptr_t addr,uint8_t mask){
    uint8_t rdata = inb(addr);
    outb(addr,rdata|mask);
}
void clr_rw(uintptr_t addr,uint8_t mask){
    uint8_t rdata = inb(addr);
    outb(addr,(rdata&(~mask)));
}

void __uart_init(){
    set_rw(LCR_ADDR,LCR_LEN_8BIT);
    set_rw(LCR_ADDR,LCR_DIV);
    outb(DIVH_ADDR,0b00000000);
    outb(DIVL_ADDR,0b00000001);
    clr_rw(LCR_ADDR,LCR_DIV);
}