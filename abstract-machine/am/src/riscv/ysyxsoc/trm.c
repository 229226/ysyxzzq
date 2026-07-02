#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>
#include <klib.h>

extern char _data_loadaddr,_sdata,_edata;
extern char _heap_start;
extern char _heap_end;
Area heap = RANGE(&_heap_start, &_heap_end);

int main(const char *args);

static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  while((inb(SERIAL_ADDR_BASE+5)&0b00100000) != 0b00100000);
  outb(SERIAL_ADDR_BASE,ch);
}

void halt(int code) {
  __asm__ volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}

void _trm_init() {
  //bootloader
  memcpy(&_sdata,&_data_loadaddr,&_edata-&_sdata);

  ioe_init();

  char text[5];
  text[4] = '\0';
  uint32_t mvendorid;
  uint32_t marchid;
  __asm__ volatile("csrr %0, 0xF11" : "=r"(mvendorid)); 
  __asm__ volatile("csrr %0, 0xF12" : "=r"(marchid)); 
  *((uint32_t*)text) =  ((mvendorid & 0x000000FFu) << 24) |
                        ((mvendorid & 0x0000FF00u) << 8)  |
                        ((mvendorid & 0x00FF0000u) >> 8)  |
                        ((mvendorid & 0xFF000000u) >> 24);
  printf("%s",text);
  printf("%d\n",marchid);

  int ret = main(mainargs);
  halt(ret);
}