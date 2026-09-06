#include "mem.hpp"
#include "trace.hpp"
#include "npc_ioe.hpp"
#include "timer.hpp"
#include "flash.hpp"
#include "pmem.hpp"

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