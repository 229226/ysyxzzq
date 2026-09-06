#include "pmem.hpp"
#include "moniter.hpp"
#include "trace.hpp"

static uint8_t pmem[PMEM_SIZE];

void* PMEM_Get_PADDR(){
    return (void*)pmem;
}

int pmem_check(uint32_t addr){
    if(addr >= RESETADDR && addr <= (RESETADDR + PMEM_SIZE - 1)){
        return 1;
    }
    npc_status.status = NPC_ERROR;
    printf("pmem_check:地址在pmem之外 addr = 0x%08x\n",addr);
    return 0;
}

int pmem_read(int raddr){
    if(!pmem_check(raddr)){
        return 0;
    }

    uint32_t addr = (uint32_t)raddr;
    int data = *(int32_t *)((uint64_t)pmem+(addr&((PMEM_SIZE-1)&0xfffffffC)));

    #ifdef MTRACE_CONFIG
        mtrace_read(addr,data,4);
    #endif
    return data;
}
void pmem_write(int waddr, int wdata, char wmask){
    uint32_t addr = (uint32_t)waddr;
    uint32_t data = (uint32_t)wdata;
    uint8_t strb = (uint8_t)wmask & 0x0f;

    if(strb == 0){
        return;
    }

    for(int i = 0; i < 4; i++){
        if(!(strb & (1 << i))){
            continue;
        }

        uint32_t offset = (addr&((PMEM_SIZE-1)&0xfffffffC)) + i;
        uint8_t byte_data = (data >> (i * 8)) & 0xff;

        pmem[offset] = byte_data;
    }

#ifdef MTRACE_CONFIG
    mtrace_write(addr, data, 4);
#endif
}