#ifndef __MONITER_HPP_
#define __MONITER_HPP_

#include "common.hpp"

typedef enum{
  NPC_NORMAL,NPC_ABORT,NPC_QUIT
}Status;

typedef struct NPC
{
  uint32_t reg[32];
  uint32_t pc;
}NPC;

#define REGS_NUM 32

typedef struct Npc_Status{
  Status status;
  int ebreak_ret;
}Npc_Status;

extern Npc_Status npc_status;
extern NPC npc;

void print_regs(NPC cpu);

void moniter_init(int argc , char *argv[]);
void moniter_loop();

#endif