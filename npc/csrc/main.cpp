#include "common.hpp"
#include "moniter.hpp"
#include "mem.hpp"
#include "sim.hpp"
#include "trace.hpp"

void ebreak(){
  npc_status.ebreak_ret = npc.reg[10];
  npc_status.status = NPC_ABORT;
}
void read_reg(int val,int num){
  ((int *)&npc)[num] = val;
}
void itrace(int ins){
  #ifdef ITRACE_CONFIG
    itrace_print(ins);
  #endif
}
void ins_state(int state){
  if(state == 1)npc_status.ins_state = INS_FINI;
  else npc_status.ins_state = INS_EXEC;
}

int main(int argc, char *argv[]) {
  //SoC
  Verilated::commandArgs(argc, argv);

  moniter_init(argc,argv);

  sim_init();

  moniter_loop();

  sim_exit();
  
  return npc_exit();
}
