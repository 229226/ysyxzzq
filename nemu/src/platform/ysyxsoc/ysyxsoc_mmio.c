#include <platform/ysyxsoc/ysyxsoc_mmio.h>
#include <platform/ysyxsoc/ysyxsoc_mrom.h>
#include <platform/ysyxsoc/ysyxsoc_sram.h>
#include <platform/ysyxsoc/ysyxsoc_flash.h>
#include <platform/ysyxsoc/ysyxsoc_psram.h>
#include <platform/ysyxsoc/ysyxsoc_sdram.h>
#include <platform/ysyxsoc/ysyxsoc_uart.h>
#include <platform/ysyxsoc/ysyxsoc_clint.h>
#include <isa.h>

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
    paddr_t offset = addr & (paddr_t)(mmio.lenth - 1);

    if(mmio.read != NULL) return mmio.read(offset, len);

    paddr_t *raddr = (paddr_t *)(mmio.mem + offset);
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
    paddr_t offset = addr & (paddr_t)(mmio.lenth - 1);

    if(mmio.write != NULL) { mmio.write(offset, len, data); return; }

    paddr_t *waddr = (paddr_t *)(mmio.mem + offset);
    switch (len)
    {
    case 1: *(uint8_t  *)waddr = data; return;
    case 2: *(uint16_t *)waddr = data; return;
    case 4: *(uint32_t *)waddr = data; return;
    default:break;
    }
}

void ysyxsoc_mmio_init(){
    // 让 guest 用 csrr 0xF11/0xF12 读到 ysyx 的标识，AM 的 trm.c 会把它打印出来。
    // cpu.csr[] 就是那个 4096 项的全局 CSR 数组，直接写即可。
    // 时序上没问题：本函数由 init_mem() 调用，之后的 init_isa()->restart() 只重置
    // mstatus 和 pc，不会动这两个寄存器，所以这里写的值能留到程序运行。
    cpu.csr[0xF11] = 0x79737978;   // mvendorid，即 "ysyx" 的 ASCII
    cpu.csr[0xF12] = 25080209;     // marchid，即学号

    ysyxsoc_mrom_init();
    ysyxsoc_sram_init();
    ysyxsoc_flash_init();
    ysyxsoc_psram_init();
    ysyxsoc_sdram_init();
    ysyxsoc_uart_init();
    ysyxsoc_clint_init();
}