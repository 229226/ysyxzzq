#include "diff_test.hpp"
#include "mem.hpp"
#include "dlfcn.h"
#include "moniter.hpp"

typedef void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction);
ref_difftest_memcpy my_difftest_memcpy;
typedef void (*ref_difftest_regcpy)(void *dut, bool direction);
ref_difftest_regcpy my_difftest_regcpy;
typedef void (*ref_difftest_exec)(uint64_t n);
ref_difftest_exec my_difftest_exec;
typedef void (*ref_difftest_raise_intr)(uint64_t NO);
ref_difftest_raise_intr my_difftest_raise_intr;
typedef void (*ref_difftest_init)(int port);
ref_difftest_init my_difftest_init;

void diff_init(){
    void *dl_handle;
    dl_handle = dlopen("/home/zzq/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so", RTLD_LAZY);
    assert(dl_handle);

    my_difftest_memcpy = (ref_difftest_memcpy)dlsym(dl_handle,"difftest_memcpy");
    assert(my_difftest_memcpy);

    my_difftest_regcpy = (ref_difftest_regcpy)dlsym(dl_handle,"difftest_regcpy");
    assert(my_difftest_regcpy);

    my_difftest_exec = (ref_difftest_exec)dlsym(dl_handle,"difftest_exec");
    assert(my_difftest_exec);

    my_difftest_raise_intr = (ref_difftest_raise_intr)dlsym(dl_handle,"difftest_raise_intr");
    assert(my_difftest_raise_intr);

    my_difftest_init = (ref_difftest_init)dlsym(dl_handle,"difftest_init");
    assert(my_difftest_init);

    my_difftest_init(0);

    my_difftest_memcpy(RESETADDR,(void *)RESETADDR,mem_size,DIFFTEST_TO_REF);

    NPC tmp = {0};
    tmp.pc = RESETADDR;
    my_difftest_regcpy(&tmp,DIFFTEST_TO_REF);
    return;
}

int diff_checkregs(NPC ref){
    for (int i = 0; i < REGS_NUM; i++)
    {
        if(ref.reg[i] != npc.reg[i]) return 0;
    }
    if(ref.pc != npc.pc) return 0;
    return 1;
}

void checkregs(NPC ref){
    if(!diff_checkregs(ref)){
        npc_status.status = NPC_ABORT;
        npc_status.ebreak_ret = -1;
        printf("diff_test:状态不一致，终止！\n");
        printf("REF寄存器为:\n");
        print_regs(ref);
        printf("NPC寄存器为:\n");
        print_regs(npc);
    }
}

void diff_step(){
    NPC ref;

    my_difftest_exec(1);
    my_difftest_regcpy(&ref,DIFFTEST_TO_DUT);
    checkregs(ref);
}