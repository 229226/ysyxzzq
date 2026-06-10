#include "sim.hpp"
#include "moniter.hpp"
#include "diff_test.hpp"
#include "trace.hpp"

static TOP_NAME *top = new TOP_NAME;
static VerilatedContext* contextp = NULL;
#ifdef FST_CONFIG
  static VerilatedFstC* tfp = NULL;
#endif

static int clock_num = 0;

void sim_init(){
    Verilated::traceEverOn(true);
    contextp = new VerilatedContext;

    #ifdef FST_CONFIG
    tfp = new VerilatedFstC;
    top->trace(tfp,99);
    tfp->open("./build/waveform.fst");
    #endif

    top->reset = 1;
    sim_clock();
    sim_clock();
    sim_clock();
    sim_clock();
    sim_clock();
    sim_clock();
    sim_clock();
    sim_clock();
    sim_clock();
    sim_clock();

    top->reset = 0;
}

void sim_exit(){
  step_and_dump();

  #ifdef FST_CONFIG
  tfp->close();
  #endif
}

void sim_clock(){
  top->clock = 1;
  step_and_dump();
  top->clock = 0;
  step_and_dump();
}

void step_and_dump(){
  top->eval();
  contextp->timeInc(1);

  #ifdef FST_CONFIG
  tfp->dump(contextp->time());
  #endif
}

int sim_exec_half(){
    top->clock = 0;
    step_and_dump();
    return 0;
}

int sim_exec_one(){
    sim_clock();
    
    #ifdef DIFF_CONFIG
      if(npc_status.ins_state == INS_FINI)
      diff_step();
    #endif

    clock_num++;
    return 0;
}

int sim_exec(int turns){
  for (uint64_t i = turns; i > 0; i--)
  {
    sim_exec_one();
    if(npc_status.status != NPC_NORMAL) {
      if(npc_status.status == NPC_ABORT){
        if(npc_status.ebreak_ret == 0){
          printf("npc:HIT GOOD TRAP\n");
          break;
        }else{
          printf("npc:HIT BAD TRAP\n");
          break;
        }
      }else if(npc_status.status == NPC_ERROR){
        printf("npc:执行遇到错误\n");
        break;
      }else{
        printf("npc:未知暂停，状态码:%d\n",npc_status.status);
        break;
      }
    }
  }
  
  printf("npc:执行花费了%d个时钟周期\n",clock_num);

  #ifdef ITRACE_CONFIG
    itrace_rb_pr();
  #endif
  return 0;
}