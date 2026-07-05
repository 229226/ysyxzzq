#include "common.hpp"
#include "moniter.hpp"
#include "mem.hpp"
#include "sim.hpp"
#include "trace.hpp"

int main(int argc, char *argv[]) {
  //SoC
  Verilated::commandArgs(argc, argv);

  moniter_init(argc,argv);

  sim_init();

  moniter_loop();

  sim_exit();
  
  return npc_exit();
}
