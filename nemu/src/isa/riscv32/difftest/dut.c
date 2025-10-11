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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for(int i = 0; i < (sizeof(cpu.gpr)/sizeof(cpu.gpr[0])) ; i++){
    if(cpu.gpr[i] != ref_r->gpr[i]){
      printf("差分测试检测出错误 cpu.gpr[%d] != ref.gpr[%d]\n",i,i);
      printf("cpu.gpr[%d]=%08x\n",i,(uint32_t)cpu.gpr[i]);
      printf("ref.gpr[%d]=%08x\n",i,(uint32_t)ref_r->gpr[i]);
      return false;
    }
  }
  if(cpu.pc != ref_r->pc){
    printf("差分测试检测出错误 cpu.pc != ref.pc\n");
    printf("cpu.pc=%08x\n",cpu.pc);
    printf("ref.pc=%08x\n",ref_r->pc);
    return false;
  }
  return true;
}

void isa_difftest_attach() {
}
