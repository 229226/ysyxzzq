#include <am.h>

#define FB_ADDR 0x21000000

#define VGA_HEI 480
#define VGA_WID 640

void __am_gpu_init() {
//   int i,j;
//   int w = VGA_WID;
//   int h = VGA_HEI;
//   uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
//   for (i = 0; i < (VGA_HEI/2); i ++){
//     for(j = 0; j < (VGA_WID/2); j ++){
//         fb[i*VGA_WID + j] = 0x00FFFFFF;
//     }
//   }
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = VGA_WID, .height = VGA_HEI,
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  uint32_t screen_w = VGA_WID;
  uint32_t screen_h = VGA_HEI;
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
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
