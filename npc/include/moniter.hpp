#ifndef __MONITER_HPP_
#define __MONITER_HPP_

#include "common.hpp"

typedef enum{
  NPC_NORMAL,NPC_ERROR,NPC_QUIT,NPC_ABORT
}Status;
typedef enum{
  INS_EXEC,INS_FINI
}INS_state;

typedef struct NPC
{
  uint32_t reg[32];
  uint32_t pc;
}NPC;

#define REGS_NUM 32

typedef struct NPC_Status{
  Status status;
  INS_state ins_state;
  int ebreak_ret;
}NPC_Status;

extern NPC_Status npc_status;
extern NPC npc;

void print_reg(NPC cpu, int num);
void print_regs(NPC cpu);

void moniter_init(int argc , char *argv[]);
void moniter_loop();

int npc_exit();
#endif