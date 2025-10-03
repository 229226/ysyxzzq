#include <am.h>
#include <nemu.h>
#include <stdio.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
  // int i;
  // uint32_t data = inl(VGACTL_ADDR);
  // int w = (data >> 16);  // TODO: get the correct width
  // int h = (data & 0xFFFF);  // TODO: get the correct height
  // uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  // for (i = 0; i < w * h; i ++) fb[i] = i;
  // outl(SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t data = inl(VGACTL_ADDR);

  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = (data >> 16), .height = (data & 0xFFFF),
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  uint32_t data = inl(VGACTL_ADDR);
  uint32_t screen_w = data >> 16;
  uint32_t screen_h = data & 0xFFFF;
  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;

  uint32_t screen_x = 0;
  uint32_t screen_y = 0;
  for (uint32_t pix_y = 0; pix_y < ctl->h; pix_y++)
    {
      for (uint32_t pix_x = 0; pix_x < ctl->w; pix_x++)
      {
        screen_x = pix_x + ctl->x;
        screen_y = pix_y + ctl->y;
        if(screen_y <= screen_h && screen_x <= screen_w){
          fb[screen_y*screen_w + screen_x] = ((uint32_t *)ctl->pixels)[pix_y*ctl->w + pix_x];
        }
      }
    }
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
