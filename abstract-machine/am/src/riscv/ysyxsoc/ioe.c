#include <am.h>
#include <klib-macros.h>

void __uart_init();

bool ioe_init(){
    __uart_init();
    return true;
}