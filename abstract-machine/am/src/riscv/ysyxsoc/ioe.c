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

void __spi_flash_init();
uint32_t flash_read(uint32_t addr);

void __am_uart_init();
void __am_timer_init();

void __am_timer_rtc(AM_TIMER_RTC_T *);
void __am_timer_uptime(AM_TIMER_UPTIME_T *);
void __am_input_keybrd(AM_INPUT_KEYBRD_T *);

static void __am_timer_config(AM_TIMER_CONFIG_T *cfg) { cfg->present = true; cfg->has_rtc = true; }
static void __am_input_config(AM_INPUT_CONFIG_T *cfg) { cfg->present = true;  }
static void __am_uart_config(AM_INPUT_CONFIG_T *cfg) { cfg->present = false;  }

typedef void (*handler_t)(void *buf);
static void *lut[16] = {
    [AM_TIMER_CONFIG] = __am_timer_config,
    [AM_TIMER_RTC   ] = __am_timer_rtc,
    [AM_TIMER_UPTIME] = __am_timer_uptime,
    [AM_INPUT_CONFIG] = __am_input_config,
    [AM_INPUT_KEYBRD] = __am_input_keybrd,
    [AM_UART_CONFIG]  = __am_uart_config,
};

static void fail(void *buf) { panic("access nonexist register"); }

bool ioe_init(){
    for (int i = 0; i < LENGTH(lut); i++)
        if (!lut[i]) lut[i] = fail;
    
    __am_timer_init();
    __am_uart_init();
    return true;
}

void ioe_read (int reg, void *buf) { ((handler_t)lut[reg])(buf); }
void ioe_write(int reg, void *buf) { ((handler_t)lut[reg])(buf); }