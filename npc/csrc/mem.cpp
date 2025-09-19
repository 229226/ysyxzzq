#include "mem.hpp"
#include "moniter.hpp"
#include "trace.hpp"

int mem_size = 0x1000000;

void init_mem(char *file_img){
    if(file_img == NULL){
        printf("npc:没有给出img文件\n");
        assert(0);
    }

    int fd_img = open(file_img,O_RDONLY,0644);
    assert(fd_img != -1);

    struct stat stat_img;
    assert(stat(file_img,&stat_img) == 0);
    int img_size = stat_img.st_size;

    int mem_fd = open("./build/mem", O_CREAT|O_RDWR,0644);
    assert(mem_fd != -1);

    int ret_ft = ftruncate(mem_fd,mem_size);
    assert(ret_ft != -1);
    
    void* mmap_ret = mmap((void *)RESETADDR,mem_size, PROT_READ|PROT_WRITE,MAP_SHARED,mem_fd, 0);
    assert(mmap_ret != MAP_FAILED);

    memset((void *)RESETADDR, 0, mem_size);

    ssize_t ret = read(fd_img,(void *)RESETADDR,img_size);
    assert(ret != -1);

    close(fd_img);
    close(mem_fd);
}

uint32_t mem_read(uint32_t pc){
    return *((uint32_t *)pc);
}

void mem_write(uint32_t pc,uint32_t data){
    *(uint32_t *)pc = data;
}

int pmem_check(uint32_t addr){
    if(addr >= RESETADDR && addr <= (RESETADDR + mem_size - 1)){
        return 1;
    }
    printf("地址在mem之外 addr = 0x%08x\n",addr);
    return 0;
}

extern "C" int pmem_read(int raddr){
    if(!pmem_check(raddr)){
        //npc_status.status = NPC_ABORT;
        return 0;
    }
    uint32_t addr = (uint32_t)raddr;
    int data = *(int *)addr;
    mtrace_pread(addr,data);
    return data;
}
extern "C" void pmem_write(int waddr, int wdata, char wmask){
    if(!pmem_check(waddr)){
        //
        return;
    }
    uint32_t addr = (uint32_t)waddr;
    switch (wmask)
    {
    case 0b00000001: *((uint8_t* )addr) = wdata;break;
    case 0b00000011: *((uint16_t* )addr) = wdata;break;
    case 0b00001111: *((uint32_t* )addr) = wdata;break;
    default:
        printf("mem:读取使用的wmask错误");
        assert(0);
        break;
    }
    mtrace_pwrite(waddr,wdata);
}