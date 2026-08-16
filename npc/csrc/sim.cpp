#include "sim.hpp"
#include "moniter.hpp"
#include "diff_test.hpp"
#include "trace.hpp"
#include <nvboard.h>
#include "ptrace.hpp"

static TOP_NAME *top = NULL;
static VerilatedContext* contextp = NULL;
#ifdef FST_CONFIG
  static VerilatedFstC* tfp = NULL;
#endif

extern "C" void ebreak(){
  npc_status.ebreak_ret = npc.reg[10];
  npc_status.status = NPC_ABORT;
}
extern "C" void read_reg(int val,int num){
  ((int *)&npc)[num] = val;
}
extern "C" void ins_state(int state){
  if(state == 1){
    npc_status.ins_state = INS_FINI;
  }
  else npc_status.ins_state = INS_EXEC;
}

void nvboard_bind_all_pins(TOP_NAME* top);

void verilator_init(int argc, char *argv[]){
  contextp = new VerilatedContext;
  Verilated::commandArgs(argc, argv);

  top = new TOP_NAME;

  Verilated::traceEverOn(true);
  
  #ifdef FST_CONFIG
  tfp = new VerilatedFstC;
  top->trace(tfp,99);
  tfp->open("./build/waveform.fst");
  #endif

  #ifdef NV_CONFIG
  nvboard_bind_all_pins(top);
  nvboard_init();
  #endif
}

void sim_init(){
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
  
  #ifdef NV_CONFIG
  nvboard_update();
  #endif

  ptrace.clock_inc();
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
  
  ptrace.set_frequency(592753000UL);

  printf("\nptrace:执行花费了%ld个时钟周期\n", ptrace.get_clock());
  printf("ptrace:执行了%ld条指令\n", ptrace.get_instr());
  printf("ptrace:IPC为%.4f\n", ptrace.get_ipc());
  printf("ptrace:IPS (指令/秒) : %.2f\n", ptrace.get_ips());

  uint64_t ifu_wait_mem = ptrace.get_IFU_wait_mem_cyc();
  uint64_t lsu_read_wait = ptrace.get_LSU_read_cyc();
  uint64_t lsu_write_wait = ptrace.get_LSU_write_cyc();
  uint64_t total_mem_wait = ifu_wait_mem + lsu_read_wait + lsu_write_wait;

  double cpi_total = (double)ptrace.get_clock() / ptrace.get_instr();
  double cpi_mem   = (double)total_mem_wait / ptrace.get_instr();
  double cpi_core  = cpi_total - cpi_mem;

  printf("\nptrace:CPI分解 (总CPI = %.4f):\n", cpi_total);
  printf("  CPI_core (非访存)          = %.4f\n", cpi_core);
  printf("  CPI_mem (访存等待总计)      = %.4f\n", cpi_mem);

  printf("\nptrace:IFU取指次数:%ld\n", ptrace.get_IFU_fetch());

  printf("\nptrace:EXU计算次数:%ld\n", ptrace.get_EXU_fini());

  printf("\nptrace:LSU读次数:%ld\n", ptrace.get_LSU_read());
  printf("ptrace:LSU写次数:%ld\n", ptrace.get_LSU_write());

  uint64_t total_clock = ptrace.get_clock();
  uint64_t wait_start = ptrace.get_IFU_wait_start_cyc();
  uint64_t wait_mem   = ptrace.get_IFU_wait_mem_cyc();
  uint64_t fetch      = ptrace.get_IFU_fetch();
  uint64_t wait_idu   = ptrace.get_IFU_wait_IDU_cyc();
  uint64_t other      = total_clock - wait_start - wait_mem - fetch - wait_idu;

  printf("\nptrace:IFU 状态周期统计 (总时钟 %ld):\n", total_clock);
  printf("  IFU_wait_start : %ld  (%.2f%%)\n", wait_start, 100.0 * wait_start / total_clock);
  printf("  IFU_wait_mem   : %ld  (%.2f%%)\n", wait_mem,   100.0 * wait_mem   / total_clock);
  printf("  IFU_fetch      : %ld  (%.2f%%)\n", fetch,   100.0 * fetch   / total_clock);
  printf("  IFU_wait_IDU   : %ld  (%.2f%%)\n", wait_idu,   100.0 * wait_idu   / total_clock);
  printf("  其他           : %ld  (%.2f%%)\n", other,      100.0 * other      / total_clock);

  uint64_t idu_total = ptrace.get_IDU_U() + ptrace.get_IDU_J() + ptrace.get_IDU_I() + 
                       ptrace.get_IDU_Ical() + ptrace.get_IDU_B() + ptrace.get_IDU_Rcal() +
                       ptrace.get_IDU_LOAD() + ptrace.get_IDU_STORE() + ptrace.get_IDU_CSR();

  printf("\nptrace:IDU指令类型统计 (总计:%ld):\n", idu_total);
  if (idu_total == 0) {
      printf("  (无指令解码)\n");
  } else {
      printf("  %-30s : %ld  (%.2f%%)\n", "U-type(lui/auipc)", ptrace.get_IDU_U(), 100.0 * ptrace.get_IDU_U() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "J-type(jal)", ptrace.get_IDU_J(), 100.0 * ptrace.get_IDU_J() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "I-type(jalr/ecall/ebreak)", ptrace.get_IDU_I(), 100.0 * ptrace.get_IDU_I() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "I-ALU(addi etc)", ptrace.get_IDU_Ical(), 100.0 * ptrace.get_IDU_Ical() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "Branch(B-type)", ptrace.get_IDU_B(), 100.0 * ptrace.get_IDU_B() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "R-ALU", ptrace.get_IDU_Rcal(), 100.0 * ptrace.get_IDU_Rcal() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "Load", ptrace.get_IDU_LOAD(), 100.0 * ptrace.get_IDU_LOAD() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "Store", ptrace.get_IDU_STORE(), 100.0 * ptrace.get_IDU_STORE() / idu_total);
      printf("  %-30s : %ld  (%.2f%%)\n", "CSR", ptrace.get_IDU_CSR(), 100.0 * ptrace.get_IDU_CSR() / idu_total);
  }

  printf("\nptrace:IDU各类指令平均周期数 (总周期数/指令数):\n");
  auto print_avg = [&](const char* name, uint64_t count, uint64_t cyc) {
      if (count > 0) {
          double avg = (double)cyc / count;
          printf("  %-30s : 指令数 %ld, 总周期 %ld, 平均 %.2f 周期/指令\n", name, count, cyc, avg);
      } else {
          printf("  %-30s : 无指令\n", name);
      }
  };
  print_avg("U-type(lui/auipc)", ptrace.get_IDU_U(), ptrace.get_IDU_U_cyc());
  print_avg("J-type(jal)", ptrace.get_IDU_J(), ptrace.get_IDU_J_cyc());
  print_avg("I-type(jalr/ecall/ebreak)", ptrace.get_IDU_I(), ptrace.get_IDU_I_cyc());
  print_avg("I-ALU(addi etc)", ptrace.get_IDU_Ical(), ptrace.get_IDU_Ical_cyc());
  print_avg("Branch(B-type)", ptrace.get_IDU_B(), ptrace.get_IDU_B_cyc());
  print_avg("R-ALU", ptrace.get_IDU_Rcal(), ptrace.get_IDU_Rcal_cyc());
  print_avg("Load", ptrace.get_IDU_LOAD(), ptrace.get_IDU_LOAD_cyc());
  print_avg("Store", ptrace.get_IDU_STORE(), ptrace.get_IDU_STORE_cyc());
  print_avg("CSR", ptrace.get_IDU_CSR(), ptrace.get_IDU_CSR_cyc());
  
  printf("\nptrace:LSU访存延迟统计:\n");
  uint64_t lsu_read_cnt = ptrace.get_LSU_read();
  uint64_t lsu_write_cnt = ptrace.get_LSU_write();
  if (lsu_read_cnt > 0) {
      double avg_read = (double)ptrace.get_LSU_read_cyc() / lsu_read_cnt;
      printf("  %-30s : 次数 %ld, 总周期 %ld, 平均 %.2f 周期/次\n", 
             "Read", lsu_read_cnt, ptrace.get_LSU_read_cyc(), avg_read);
  } else {
      printf("  %-30s : 无\n", "Read");
  }
  if (lsu_write_cnt > 0) {
      double avg_write = (double)ptrace.get_LSU_write_cyc() / lsu_write_cnt;
      printf("  %-30s : 次数 %ld, 总周期 %ld, 平均 %.2f 周期/次\n",
             "Write", lsu_write_cnt, ptrace.get_LSU_write_cyc(), avg_write);
  } else {
      printf("  %-30s : 无\n", "Write");
  }
  
  #ifdef ITRACE_CONFIG
    itrace_rb_pr();
  #endif
  return 0;
}