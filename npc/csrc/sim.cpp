#include "sim.hpp"
#include "moniter.hpp"
#include "diff_test.hpp"
#include "trace.hpp"

#define TOP_NAME Vysyx_25080209_npc

static TOP_NAME *top = new TOP_NAME;
static VerilatedContext* contextp = NULL;
static VerilatedFstC* tfp = NULL;

void sim_init(){
    Verilated::traceEverOn(true);
    contextp = new VerilatedContext;
    tfp = new VerilatedFstC;
    top->trace(tfp,99);
    tfp->open("./build/waveform.fst");

    top->rst = 1;
    top->clk = 0;
    step_and_dump();
    top->clk = 1;
    step_and_dump();
    top->rst = 0;
    top->clk = 0;
    step_and_dump();
}

void sim_exit(){
  step_and_dump();
  tfp->close();
}

void sim_clk(){
  top->clk = 1;
  step_and_dump();
  top->clk = 0;
  step_and_dump();
}

void step_and_dump(){
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

int sim_exec_half(){
    top->clk = 0;
    step_and_dump();
    return 0;
}

int sim_exec_one(){
    sim_clk();
    #ifdef DIFF_CONFIG
      diff_step();
    #endif
    return 0;
}

int sim_exec(int turns){
  for (uint64_t i = turns; i > 0; i--)
  {
    sim_exec_one();
      if(npc_status.status == NPC_ABORT) {
        if(npc_status.ebreak_ret == 0)
        {
          printf("npc:HIT GOOD TRAP\n");
          break;
        }else{
          printf("npc:HIT BAD TRAP\n");
          break;
        }
    }
  }

  #ifdef ITRACE_CONFIG
    itrace_rb_pr();
  #endif
  return 0;
}