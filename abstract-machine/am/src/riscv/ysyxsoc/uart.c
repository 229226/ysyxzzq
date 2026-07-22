#include <ysyxsoc.h>
#include <am.h>

#define REC_ADDR        SERIAL_ADDR_BASE
#define TRA_ADDR        SERIAL_ADDR_BASE

#define DIVL_ADDR       SERIAL_ADDR_BASE+0
#define DIVH_ADDR       SERIAL_ADDR_BASE+1

#define LCR_ADDR        SERIAL_ADDR_BASE+3
#define LSR_ADDR        SERIAL_ADDR_BASE+5
#define LSR_REC_MASK    0b00000001
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

void __am_uart_recive(AM_UART_RX_T* rx){
    if((inb(LSR_ADDR)&LSR_REC_MASK)) rx->data = inb(REC_ADDR);
    else rx->data = 0xff;
}

void __am_uart_init(){
    set_rw(LCR_ADDR,LCR_LEN_8BIT);
    set_rw(LCR_ADDR,LCR_DIV);
    outb(DIVH_ADDR,0b00000000);
    outb(DIVL_ADDR,0b00000001);
    clr_rw(LCR_ADDR,LCR_DIV);
}