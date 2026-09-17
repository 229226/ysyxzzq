#include "mem.hpp"
#include "trace.hpp"
#include "npc_ioe.hpp"
#include "timer.hpp"
#include "flash.hpp"
#include "pmem.hpp"

int g_img_size = 0;

// ========== 地址所属的存储器类型 ==========
// 全 NPC 唯一一份地址表。icache 与 LSU 的 DPI 都只上报原始地址，到这里再分类。
// 区间参考 abstract-machine/scripts/ysyxsoclinker.ld 与 ysyxSoC/src/SoC.scala
// （注意 sdram 的末尾在各处写法不一：AM 链接脚本是 128M，这里沿用 128M；
//  SoC 实际综合出来是 32M，但只影响统计分类的标签，不影响正确性）。
MemType mem_type_of(uint32_t addr){
    if(addr >= 0x30000000 && addr < 0x31000000) return MEM_TYPE_FLASH;  // flash  16M
    if(addr >= 0x20000000 && addr < 0x20001000) return MEM_TYPE_MROM;   // mrom   4K
    if(addr >= 0xa0000000 && addr < 0xa8000000) return MEM_TYPE_SDRAM;  // sdram  128M
    if(addr >= 0x80000000 && addr < 0x80400000) return MEM_TYPE_PSRAM;  // psram  4M
    if(addr >= 0x0f000000 && addr < 0x0f002000) return MEM_TYPE_SRAM;    // sram   8K
    if(addr >= 0x10000000 && addr < 0x10001000) return MEM_TYPE_UART;    // uart   4K
    if(addr >= 0x10001000 && addr < 0x10002000) return MEM_TYPE_SPI;     // spi    4K
    if(addr >= 0x02000000 && addr < 0x02010000) return MEM_TYPE_CLINT;   // clint  64K
    return MEM_TYPE_OTHER;
}

const char *mem_type_name(MemType type){
    switch (type) {
    case MEM_TYPE_FLASH: return "flash";
    case MEM_TYPE_MROM:  return "mrom";
    case MEM_TYPE_SDRAM: return "sdram";
    case MEM_TYPE_PSRAM: return "psram";
    case MEM_TYPE_SRAM:  return "sram";
    case MEM_TYPE_UART:  return "uart";
    case MEM_TYPE_SPI:   return "spi";
    case MEM_TYPE_CLINT: return "clint";
    default:             return "other";
    }
}

const char *mem_type_range_str(MemType type){
    switch (type) {
    case MEM_TYPE_FLASH: return "0x30000000-0x30ffffff";
    case MEM_TYPE_MROM:  return "0x20000000-0x20000fff";
    case MEM_TYPE_SDRAM: return "0xa0000000-0xa7ffffff";
    case MEM_TYPE_PSRAM: return "0x80000000-0x803fffff";
    case MEM_TYPE_SRAM:  return "0x0f000000-0x0f001fff";
    case MEM_TYPE_UART:  return "0x10000000-0x10000fff";
    case MEM_TYPE_SPI:   return "0x10001000-0x10001fff";
    case MEM_TYPE_CLINT: return "0x02000000-0x0200ffff";
    default:             return "未映射";
    }
}

void init_mem(char *file_img){
    if(file_img == NULL){
        printf("npc:没有给出img文件\n");
        assert(0);
    }

    int img_fd = open(file_img,O_RDONLY,0644);
    assert(img_fd != -1);

    struct stat img_stat;
    assert(stat(file_img,&img_stat) == 0);
    int img_size = img_stat.st_size;
    assert(img_size > 0);
    #ifdef YSYXSOC_CONFIG
    assert(img_size <= FLASH_SIZE);
    #endif
    #ifdef NPC_CONFIG
    assert(img_size <= PMEM_SIZE);
    #endif
    g_img_size = img_size;

    int ret = 0;
    #ifdef NPC_CONFIG
    ret = read(img_fd,PMEM_Get_PADDR(),img_size);
    #endif
    #ifdef YSYXSOC_CONFIG
    ret = read(img_fd,Flash_Get_PADDR(),img_size);
    #endif
    assert(ret != -1);

    close(img_fd);
}

int mmio_check(int addr){
    if((addr & DEVICE_BASE_ADDR) == DEVICE_BASE_ADDR){
        return 1;
    }
    return 0;
}

static uint64_t timer = 0;
int mmio_read(int raddr){
    if(raddr == TIMER_ADDR){
        return (int)timer;
    }else if(raddr == TIMER_ADDR + 4)
    {
        timer = gettime();
        return (int)((timer) >> 32);
    }
    return 0;
}
void mmio_write(int waddr,int wdata,int wmask){
    if(waddr == SERIAL_ADDR){
        putc(wdata, stdout);
        fflush(stdout);
    }
}

extern "C" int mem_read(int raddr){
    if(mmio_check(raddr)){
        return mmio_read(raddr);
    }else{
        return pmem_read(raddr);
    }
}
extern "C" void mem_write(int waddr, int wdata, char wmask){
    if(mmio_check(waddr)){
        mmio_write(waddr,wdata,wmask);
        return;
    }else{
        pmem_write(waddr,wdata,wmask);
        return;
    }
}