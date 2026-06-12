#include <platform/ysyxsoc/ysyxsoc_mmio.h>
#include <platform/ysyxsoc/ysyxsoc_mrom.h>
#include <platform/ysyxsoc/ysyxsoc_sram.h>

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
    for (int i = 0; i < YSYX_MMIO_MNUM; i++)
    {
        if((addr >= ysyx_mmio_list[i].addr)&&(addr <= ysyx_mmio_list[i].eaddr))
        return ysyx_mmio_list[i];
    }

    Assert(0,"ysyx_mmio中无匹配地址 addr = 0x%x",addr);
}

word_t ysyxsoc_read(paddr_t addr, int len){
    YSYXSOC_MMIO mmio = ysyx_mmio_find(addr);
    uint32_t data = * ((uint32_t*)(&mmio.mem[addr&mmio.mask]));
    switch (len)
    {
    case 1:data = data&0x000000ff; break;
    case 2:data = data&0x0000ffff; break;
    case 4:data = data&0xffffffff; break;
    default:data = 0;break;
    }
    return data;
}

void ysyxsoc_write(paddr_t addr, int len, word_t data){
    YSYXSOC_MMIO mmio = ysyx_mmio_find(addr);
    switch (len)
    {
    case 1:* ((uint8_t*)(&mmio.mem[addr&mmio.mask]))
             = data&0x000000ff; break;
    case 2:* ((uint16_t*)(&mmio.mem[addr&mmio.mask]))
             = data&0x0000ffff; break;
    case 4:* ((uint32_t*)(&mmio.mem[addr&mmio.mask]))
             = data&0xffffffff; break;
    default:break;
    }
}

void ysyxsoc_mmio_init(){
    ysyxsoc_mrom_init();
    ysyxsoc_sram_init();
}