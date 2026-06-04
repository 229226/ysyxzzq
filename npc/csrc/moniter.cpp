#include "prase.hpp"
#include "mem.hpp"
#include "moniter.hpp"
#include "disasm.hpp"
#include "sdb.hpp"
#include "diff_test.hpp"
#include "trace.hpp"
#include "timer.hpp"

NPC_Status npc_status;
NPC npc;

static char *file_img = NULL;

const char * short_opt = "-b";

struct option long_opts[] =
{
    {"batch"    , no_argument      , NULL, 'b'},
    {0      ,0              ,NULL   ,0  },
};

void init_prase(int argc , char *argv[]){
    int rt;
    while ((rt = getopt_long(argc,argv,short_opt,long_opts,NULL)) != -1)
    {
        switch (rt)
        {
        case 'b':set_sdb_batch();break;
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

    #ifdef TRACE_CONFIG
        trace_init();
    #endif

    init_mem(file_img);

    init_disasm();

    #ifdef DIFF_CONFIG
        diff_init();
    #endif

    //init_timer();
}

void moniter_loop(){
    sdb_mainloop();
}

int npc_exit(){
    switch (npc_status.status)
    {
    case NPC_QUIT:return 0;
    case NPC_ABORT:if(npc_status.ebreak_ret == 0) return 0;
                    else return -1;
    case NPC_ERROR:return -1;
    default:
        break;
    }
    return 0;
}