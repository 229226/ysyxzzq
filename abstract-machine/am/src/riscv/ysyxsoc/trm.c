#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

extern char _heap_start;
int main(const char *args);

extern char _sram_start;
#define SRAM_SIZE (4 * 1024)
#define SRAM_END  ((uintptr_t)&_sram_start + SRAM_SIZE)

Area heap = RANGE(&_heap_start, SRAM_END);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  outb(SERIAL_ADDR,ch);
}

void halt(int code) {
  __asm__ volatile ("ebreak");
  while (1);
}

void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}