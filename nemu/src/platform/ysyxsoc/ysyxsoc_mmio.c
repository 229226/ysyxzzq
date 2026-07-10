#include <platform/ysyxsoc/ysyxsoc_mmio.h>
#include <platform/ysyxsoc/ysyxsoc_mrom.h>
#include <platform/ysyxsoc/ysyxsoc_sram.h>
#include <platform/ysyxsoc/ysyxsoc_flash.h>
#include <platform/ysyxsoc/ysyxsoc_psram.h>

static YSYXSOC_MMIO ysyx_mmio_list[YSYX_MMIO_MNUM];
static int ysyxsoc_mmio_num = 0;

int ysyxsoc_add(YSYXSOC_MMIO mmio){
    if(ysyxsoc_mmio_num < YSYX_MMIO_MNUM){
        Log("添加ysyxSoC外设 addr = 0x%08x",mmio.addr);
        ysyx_mmio_list[ysyxsoc_mmio_num] = mmio;
        ysyxsoc_mmio_num++;
        return 0;
    }

    return 1;
}

YSYXSOC_MMIO ysyx_mmio_find(paddr_t addr){
    for (int i = 0; i < ysyxsoc_mmio_num; i++)
    {
        if((addr >= ysyx_mmio_list[i].addr)&&
            (addr <= (ysyx_mmio_list[i].addr + ysyx_mmio_list[i].lenth - 1)))
        return ysyx_mmio_list[i];
    }

    Assert(0,"ysyx_mmio中无匹配地址 addr = 0x%x",addr);
}

word_t ysyxsoc_read(paddr_t addr, int len){
    YSYXSOC_MMIO mmio = ysyx_mmio_find(addr);
    paddr_t *raddr = (paddr_t *)(mmio.mem + (addr&((paddr_t)(mmio.lenth-1))));
    switch (len)
    {
    case 1: return *(uint8_t  *)raddr;
    case 2: return *(uint16_t *)raddr;
    case 4: return *(uint32_t *)raddr;
    default:break;
    }
    return 0;
}

void ysyxsoc_write(paddr_t addr, int len, word_t data){
    YSYXSOC_MMIO mmio = ysyx_mmio_find(addr);
    paddr_t *waddr = (paddr_t *)(mmio.mem + (addr&(mmio.lenth - 1)));
    switch (len)
    {
    case 1: *(uint8_t  *)waddr = data; return;
    case 2: *(uint16_t *)waddr = data; return;
    case 4: *(uint32_t *)waddr = data; return;
    default:break;
    }
}

void ysyxsoc_mmio_init(){
    ysyxsoc_mrom_init();
    ysyxsoc_sram_init();
    ysyxsoc_flash_init();
    ysyxsoc_psram_init();
}