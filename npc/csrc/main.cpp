#include <verilated.h>
#include <verilated_fst_c.h>
#include <Vysyx_25080209_npc.h>

#include <stdint.h>
#include <assert.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
//DPI-C
#include "svdpi.h"
#include<Vysyx_25080209_npc__Dpi.h>

typedef enum{
  NORMAL = 0,
  EBREAK = 1
}Status;

Status npc_status = NORMAL;

int ebreak(){
  npc_status = EBREAK;
  return 0;
}

static TOP_NAME *top = new TOP_NAME;
VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;

static uint32_t pc_start = 0x80000000;

void Step_and_dump(TOP_NAME *top){
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

void Sim_Init(TOP_NAME *top){
  Verilated::traceEverOn(true);
  contextp = new VerilatedContext;
  tfp = new VerilatedFstC;
  top->trace(tfp,99);
  tfp->open("./build/waveform.fst");
}

void Sim_exit(TOP_NAME *top){
  Step_and_dump(top);
  tfp->close();
}

void Sim_clk(TOP_NAME *top){
  top->clk = 0;
  Step_and_dump(top);
  top->clk = 1;
  Step_and_dump(top);
}

void* Mmap_init(){
  char* filepath = "./program";
  remove(filepath);

  int fd = open(filepath,O_RDWR|O_CREAT,0644);
  assert(fd != -1);

  int rt = ftruncate(fd,1000);
  assert(rt != -1);

  void* mmap_mem = mmap((void *)pc_start, 1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  assert(mmap_mem != MAP_FAILED);

  close(fd);

  return mmap_mem;
}

void Mmap_write(uint32_t pc,uint32_t data){
  *(uint32_t *)pc = data;
}

uint32_t Mmap_read(uint32_t pc){
  return *(uint32_t *)pc;
}

int main() {
  Sim_Init(top);

  Mmap_init();

  Mmap_write(0x80000000,0b00000000000100000000000010010011u);//addi x1 x0 0
  Mmap_write(0x80000004,0b00000000000100000000000001110011u);//ebreak

  top->rst = 1;
  Sim_clk(top);
  top->rst = 0;

  while(1){
    top->ins_in = Mmap_read(top->pc);
    Sim_clk(top);
    if(npc_status == EBREAK) break;
  }

  Sim_exit(top);
  return 0;
}
