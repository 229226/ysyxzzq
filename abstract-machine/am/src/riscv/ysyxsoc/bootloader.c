#include <klib.h>

extern char _loadaddr,_sladdr,_eladdr;

__attribute__((section("bootloader"))) void *my_memcpy
(void *dest, const void *src, size_t n) {
    char *d = dest;
    const char *s = src;
    while (n--) *d++ = *s++;
    return dest;
}

__attribute__((section("bootloader"))) void _bootloader(){
    my_memcpy(&_sladdr,&_loadaddr,&_eladdr - &_sladdr);
}