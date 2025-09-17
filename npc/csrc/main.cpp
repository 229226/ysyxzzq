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
  npc.reg[num] = val;
}
void itrace(int ins){
  itrace_print(ins);
}

int main(int argc, char *argv[]) {
  moniter_init(argc,argv);

  sim_init();

  moniter_loop();

  sim_exit();
  return 0;
}
