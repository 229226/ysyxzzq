#include "prase.hpp"
#include "mem.hpp"
#include "moniter.hpp"
#include "disasm.hpp"
#include "sdb.hpp"
#include "diff_test.hpp"
#include "trace.hpp"

Npc_Status npc_status;
NPC npc;

static char *file_img = NULL;

const char * short_opt = "-";

struct option long_opts[] =
{
    {0      ,0              ,NULL   ,0  },
};

void init_prase(int argc , char *argv[]){
    int rt;
    while ((rt = getopt_long(argc,argv,short_opt,long_opts,NULL)) != -1)
    {
        switch (rt)
        {
        case 1:
            file_img = optarg;
            break;
        default:
            break;
        }
    }
}

const char* regs_name[32] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void print_regs(NPC cpu){
    printf("pc:0x%x\n",cpu.pc);
    for (int i = 0; i < 32 ; i++)
    {
        printf("%-3s:0x%x\n",regs_name[i],cpu.reg[i]);
    }
}

void moniter_init(int argc , char *argv[]){
    init_prase(argc,argv);

    trace_init();

    init_mem(file_img);

    init_disasm();

    diff_init();
}

void moniter_loop(){
    sdb_mainloop();
}