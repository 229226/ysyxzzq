/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if(direction == DIFFTEST_TO_DUT){
    for (int i = 0; i < n; i++)
    {
      ((uint8_t *)buf)[i] = paddr_read(addr + i,1);
    }
  }
  else if(direction == DIFFTEST_TO_REF){
    for (int i = 0; i < n; i++)
    {
      paddr_write(addr + i,1,((uint8_t*)buf)[i]);
    }
  } 
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  int reg_size = sizeof(cpu.gpr[0]);
  int regs_num = sizeof(cpu.gpr)/reg_size; //不包括pc
  if(direction == DIFFTEST_TO_DUT){
    switch (reg_size)
    {
    case 4:
      for (int i = 0; i < regs_num; i++)
      {
        ((uint32_t *)dut)[i] = cpu.gpr[i];
      }
      ((uint32_t *)dut)[regs_num] = cpu.pc;
      break;
    case 8:
      for (int i = 0; i < regs_num; i++)
      {
        ((uint64_t *)dut)[i] = cpu.gpr[i];
      }
      ((uint64_t *)dut)[regs_num] = cpu.pc;
      break;
    default:
      printf("diff_test:未知reg_size\n");
      break;
    }
  }
  else if(direction == DIFFTEST_TO_REF){
    switch (reg_size)
    {
    case 4:
      for (int i = 0; i < regs_num; i++)
      {
        cpu.gpr[i] = ((uint32_t *)dut)[i];
      }
      cpu.pc = ((uint32_t *)dut)[regs_num];
      break;
    case 8:
      for (int i = 0; i < regs_num; i++)
      {
        cpu.gpr[i] = ((uint64_t *)dut)[i];
      }
      cpu.pc = ((uint64_t *)dut)[regs_num];
      break;
    default:
      printf("diff_test:未知reg_size\n");
      break;
    }
  } 
}

__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
