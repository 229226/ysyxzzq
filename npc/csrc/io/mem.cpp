#include "mem.hpp"
#include "moniter.hpp"
#include "trace.hpp"
#include "npc_ioe.hpp"
#include "timer.hpp"
#include "psram.hpp"

const int mem_size = 0x10000000;
static uint8_t flash[0x10000000];

//SoC
extern "C" void flash_read(int32_t addr, int32_t *data) {
    *data = *(int32_t *)((uint64_t)flash+(addr&0xfffffffC));
}
extern "C" void mrom_read(int32_t addr, int32_t *data) {
    *data = *(int32_t *)(addr&0xfffffffC);
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

    //烧入MROM
    // int mem_fd = open("./build/mem", O_CREAT|O_RDWR,0644);
    // assert(mem_fd != -1);

    // int ret_ft = ftruncate(mem_fd,mem_size);
    // assert(ret_ft != -1);
    
    // void* mmap_ret = mmap((void *)RESETADDR,mem_size, PROT_READ|PROT_WRITE,MAP_SHARED,mem_fd, 0);
    // assert(mmap_ret != MAP_FAILED);

    // memset((void *)RESETADDR, 0, mem_size);

    // ssize_t ret = read(img_fd,(void *)RESETADDR,img_size);
    // assert(ret != -1);

    //烧入flash
    //lseek(img_fd, 0, SEEK_SET);
    int ret = read(img_fd,flash,img_size);
    assert(ret != -1);

    //将char-test加载到flash
    // int ct_fd = open("/home/zzq/ysyx-workbench/npc/char_test/char-test.bin",O_RDONLY,0644);
    // assert(ct_fd != -1);

    // struct stat ct_stat;
    // assert(stat("/home/zzq/ysyx-workbench/npc/char_test/char-test.bin",&ct_stat) == 0);
    // int ct_size = ct_stat.st_size;
    
    // ret = read(ct_fd,flash,ct_size);
    // assert(ret != -1);

    // close(ct_fd);

    close(img_fd);

    //烧入mrom
    //close(mem_fd);
}

int pmem_check(uint32_t addr){
    if(addr >= RESETADDR && addr <= (RESETADDR + mem_size - 1)){
        return 1;
    }
    npc_status.status = NPC_ERROR;
    printf("npc:地址在mem之外 addr = 0x%08x\n",addr);
    return 0;
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

extern "C" int pmem_read(int raddr){
    if(mmio_check(raddr)){
        return mmio_read(raddr);
    }

    uint32_t addr = (uint32_t)raddr;
    int data = *(int *)addr;

    #ifdef MTRACE_CONFIG
        mtrace_pread(addr,data);
    #endif
    return data;
}
extern "C" void pmem_write(int waddr, int wdata, char wmask){
    if(mmio_check(waddr)){
        mmio_write(waddr,wdata,wmask);
        return;
    }

    if(!pmem_check(waddr)){
        return;
    }

    uint32_t addr = (uint32_t)waddr;
    switch (wmask)
    {
    case 0b00000001: *((uint8_t* )addr) = wdata;break;
    case 0b00000011: *((uint16_t* )addr) = wdata;break;
    case 0b00001111: *((uint32_t* )addr) = wdata;break;
    default:
        printf("mem:读取使用的wmask错误 %d\n",wmask);
        assert(0);
        break;
    }
    #ifdef MTRACE_CONFIG
        mtrace_pwrite(waddr,wdata);
    #endif
    
}