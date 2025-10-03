#include <am.h>
#include <nemu.h>

#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t data = inl(KBD_ADDR);
  if(data&KEYDOWN_MASK){
    kbd->keydown = 1;
    kbd->keycode = data & 0x00FF;
  }else{
    kbd->keydown = 0;
    kbd->keycode = data & 0x00FF;
  }
}
