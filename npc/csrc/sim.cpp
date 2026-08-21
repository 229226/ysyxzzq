#include "sim.hpp"
#include "moniter.hpp"
#include "diff_test.hpp"
#include "trace.hpp"
#include <nvboard.h>
#include "ptrace.hpp"

#include <chrono>
#include <iostream>

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
  auto start_time = std::chrono::steady_clock::now();

  for (uint64_t i = turns; i > 0; i--)
  {
    sim_exec_one();
    if(npc_status.status != NPC_NORMAL) {
      if(npc_status.status == NPC_ABORT){
        if(npc_status.ebreak_ret == 0){
          sim_exec_one();
          sim_exec_one();
          sim_exec_one();//再执行3个周期方便ptrace
          trace_printf("npc:HIT GOOD TRAP\n");
          break;
        }else{
          trace_printf("npc:HIT BAD TRAP\n");
          break;
        }
      }else if(npc_status.status == NPC_ERROR){
        trace_printf("npc:执行遇到错误\n");
        break;
      }else{
        trace_printf("npc:未知暂停，状态码:%d\n",npc_status.status);
        break;
      }
    }
  }
  
  auto end_time = std::chrono::steady_clock::now();
  auto total_ms = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();

  long long minutes = total_ms / 60000;
  long long remaining_ms = total_ms % 60000;
  long long seconds = remaining_ms / 1000;
  long long millis = remaining_ms % 1000;

  trace_printf("\n[sim_exec] 总执行时间: %lld 分钟, %lld 秒, %lld 毫秒 (总计 %lld ms)\n",
         minutes, seconds, millis, (long long)total_ms);

  ptrace.set_frequency(727908000UL);

  // ======== 基础统计 ========
  uint64_t total_clock = ptrace.get_clock() - 19; // 减去复位周期
  uint64_t instr_cnt   = ptrace.get_instr();

  trace_printf("\nptrace:执行花费了%ld个时钟周期（扣除复位）\n", total_clock);
  trace_printf("ptrace:执行了%ld条指令\n", instr_cnt);
  trace_printf("ptrace:IPC为%.4f\n", ptrace.get_ipc());
  trace_printf("ptrace:IPS (指令/秒) : %.2f\n", ptrace.get_ips());

  // ======== CPI 分解 ========
  uint64_t ifu_wait_mem = ptrace.get_IFU_wait_mem_cyc();
  uint64_t lsu_wait_read = ptrace.get_LSU_wait_read_cyc();
  uint64_t lsu_wait_write = ptrace.get_LSU_wait_write_cyc();
  uint64_t total_mem_wait = ifu_wait_mem + lsu_wait_read + lsu_wait_write;

  double cpi_total = (double)ptrace.get_clock() / instr_cnt;
  double cpi_mem   = (double)total_mem_wait / instr_cnt;
  double cpi_core  = cpi_total - cpi_mem;

  trace_printf("\nptrace:CPI分解 (总CPI = %.4f):\n", cpi_total);
  trace_printf("  CPI_core (非访存)          = %.4f\n", cpi_core);
  trace_printf("  CPI_mem (访存等待总计)      = %.4f\n", cpi_mem);

  // ======== 1. IFU 模块统计 ========
  {
    uint64_t wait_start = ptrace.get_IFU_wait_start_cyc();
    uint64_t wait_mem   = ptrace.get_IFU_wait_mem_cyc();
    uint64_t upd_out    = ptrace.get_IFU_update_output_cnt();
    uint64_t wait_idu   = ptrace.get_IFU_wait_IDU_cyc();
    uint64_t total_ifu  = wait_start + wait_mem + upd_out + wait_idu;
    double   ifu_ratio  = (total_clock > 0) ? 100.0 * total_ifu / total_clock : 0.0;

    trace_printf("\nptrace:IFU 模块统计 (总工作周期 %ld, 占总时钟 %.2f%%):\n", total_ifu, ifu_ratio);
    auto print_ifu = [&](const char* name, uint64_t cycles) {
      double pct = (total_ifu > 0) ? 100.0 * cycles / total_ifu : 0.0;
      trace_printf("  %-25s : %ld  (%.2f%%)\n", name, cycles, pct);
    };
    print_ifu("IFU_wait_start", wait_start);
    print_ifu("IFU_wait_mem",   wait_mem);
    print_ifu("IFU_update_output", upd_out);
    print_ifu("IFU_wait_IDU",   wait_idu);
  }

  // ======== 2. IDU 模块统计 ========
  {
    uint64_t wait_ifu = ptrace.get_IDU_wait_IFU_cyc();
    uint64_t upd_out  = ptrace.get_IDU_update_output_cnt();
    uint64_t wait_exu = ptrace.get_IDU_wait_EXU_cyc();
    uint64_t total_idu = wait_ifu + upd_out + wait_exu;
    double   idu_ratio = (total_clock > 0) ? 100.0 * total_idu / total_clock : 0.0;

    trace_printf("\nptrace:IDU 模块统计 (总工作周期 %ld, 占总时钟 %.2f%%):\n", total_idu, idu_ratio);
    auto print_idu = [&](const char* name, uint64_t cycles) {
      double pct = (total_idu > 0) ? 100.0 * cycles / total_idu : 0.0;
      trace_printf("  %-25s : %ld  (%.2f%%)\n", name, cycles, pct);
    };
    print_idu("IDU_wait_IFU", wait_ifu);
    print_idu("IDU_update_output", upd_out);
    print_idu("IDU_wait_EXU", wait_exu);
  }

  // ======== 3. EXU 模块统计（已修正为 wait_LSU） ========
  {
    uint64_t wait_idu = ptrace.get_EXU_wait_IDU_cyc();
    uint64_t upd_out  = ptrace.get_EXU_update_output_cnt();
    uint64_t wait_lsu = ptrace.get_EXU_wait_LSU_cyc();
    uint64_t total_exu = wait_idu + upd_out + wait_lsu;
    double   exu_ratio = (total_clock > 0) ? 100.0 * total_exu / total_clock : 0.0;

    trace_printf("\nptrace:EXU 模块统计 (总工作周期 %ld, 占总时钟 %.2f%%):\n", total_exu, exu_ratio);
    auto print_exu = [&](const char* name, uint64_t cycles) {
      double pct = (total_exu > 0) ? 100.0 * cycles / total_exu : 0.0;
      trace_printf("  %-25s : %ld  (%.2f%%)\n", name, cycles, pct);
    };
    print_exu("EXU_wait_IDU", wait_idu);
    print_exu("EXU_update_output", upd_out);
    print_exu("EXU_wait_LSU", wait_lsu);
  }

  // ======== 4. LSU 模块统计 ========
  {
    uint64_t wait_exu = ptrace.get_LSU_wait_EXU_cyc();
    uint64_t wait_read = ptrace.get_LSU_wait_read_cyc();
    uint64_t upd_r    = ptrace.get_LSU_update_output_r_cnt();
    uint64_t wait_write= ptrace.get_LSU_wait_write_cyc();
    uint64_t upd_w    = ptrace.get_LSU_update_output_w_cnt();
    uint64_t wait_wbu = ptrace.get_LSU_wait_WBU_cyc();
    uint64_t total_lsu = wait_exu + wait_read + upd_r + wait_write + upd_w + wait_wbu;
    double   lsu_ratio = (total_clock > 0) ? 100.0 * total_lsu / total_clock : 0.0;

    trace_printf("\nptrace:LSU 模块统计 (总工作周期 %ld, 占总时钟 %.2f%%):\n", total_lsu, lsu_ratio);
    auto print_lsu = [&](const char* name, uint64_t cycles) {
      double pct = (total_lsu > 0) ? 100.0 * cycles / total_lsu : 0.0;
      trace_printf("  %-25s : %ld  (%.2f%%)\n", name, cycles, pct);
    };
    print_lsu("LSU_wait_EXU", wait_exu);
    print_lsu("LSU_wait_read", wait_read);
    print_lsu("LSU_update_output_r", upd_r);
    print_lsu("LSU_wait_write", wait_write);
    print_lsu("LSU_update_output_w", upd_w);
    print_lsu("LSU_wait_WBU", wait_wbu);
  }

  // ======== 5. WBU 模块统计 ========
  {
    uint64_t wait_lsu = ptrace.get_WBU_wait_LSU_cyc();
    uint64_t write_reg = ptrace.get_WBU_write_reg_cnt();
    uint64_t total_wbu = wait_lsu + write_reg;
    double   wbu_ratio = (total_clock > 0) ? 100.0 * total_wbu / total_clock : 0.0;

    trace_printf("\nptrace:WBU 模块统计 (总工作周期 %ld, 占总时钟 %.2f%%):\n", total_wbu, wbu_ratio);
    auto print_wbu = [&](const char* name, uint64_t cycles) {
      double pct = (total_wbu > 0) ? 100.0 * cycles / total_wbu : 0.0;
      trace_printf("  %-25s : %ld  (%.2f%%)\n", name, cycles, pct);
    };
    print_wbu("WBU_wait_LSU", wait_lsu);
    print_wbu("WBU_write_reg", write_reg);
  }

  // ======== IDU 指令类型统计 ========
  uint64_t idu_total = ptrace.get_IDU_U() + ptrace.get_IDU_J() + ptrace.get_IDU_I() + 
                       ptrace.get_IDU_Ical() + ptrace.get_IDU_B() + ptrace.get_IDU_Rcal() +
                       ptrace.get_IDU_LOAD() + ptrace.get_IDU_STORE() + ptrace.get_IDU_CSR();

  trace_printf("\nptrace:IDU指令类型统计 (总计:%ld):\n", idu_total);
  if (idu_total == 0) {
      trace_printf("  (无指令解码)\n");
  } else {
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "U-type(lui/auipc)", ptrace.get_IDU_U(), 100.0 * ptrace.get_IDU_U() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "J-type(jal)", ptrace.get_IDU_J(), 100.0 * ptrace.get_IDU_J() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "I-type(jalr/ecall/ebreak)", ptrace.get_IDU_I(), 100.0 * ptrace.get_IDU_I() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "I-ALU(addi etc)", ptrace.get_IDU_Ical(), 100.0 * ptrace.get_IDU_Ical() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "Branch(B-type)", ptrace.get_IDU_B(), 100.0 * ptrace.get_IDU_B() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "R-ALU", ptrace.get_IDU_Rcal(), 100.0 * ptrace.get_IDU_Rcal() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "Load", ptrace.get_IDU_LOAD(), 100.0 * ptrace.get_IDU_LOAD() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "Store", ptrace.get_IDU_STORE(), 100.0 * ptrace.get_IDU_STORE() / idu_total);
      trace_printf("  %-30s : %ld  (%.2f%%)\n", "CSR", ptrace.get_IDU_CSR(), 100.0 * ptrace.get_IDU_CSR() / idu_total);
  }

  // ======== 指令周期统计（按类型平均周期） ========
  uint64_t tU = ptrace.get_total_U_cyc();
  uint64_t tJ = ptrace.get_total_J_cyc();
  uint64_t tI = ptrace.get_total_I_cyc();
  uint64_t tIcal = ptrace.get_total_Ical_cyc();
  uint64_t tB = ptrace.get_total_B_cyc();
  uint64_t tRcal = ptrace.get_total_Rcal_cyc();
  uint64_t tLoad = ptrace.get_total_LOAD_cyc();
  uint64_t tStore = ptrace.get_total_STORE_cyc();
  uint64_t tCSR = ptrace.get_total_CSR_cyc();
  uint64_t tOther = ptrace.get_total_OTHER_cyc();
  uint64_t total_ins_cyc = tU + tJ + tI + tIcal + tB + tRcal + tLoad + tStore + tCSR + tOther;

  uint64_t nU = ptrace.get_IDU_U();
  uint64_t nJ = ptrace.get_IDU_J();
  uint64_t nI = ptrace.get_IDU_I();
  uint64_t nIcal = ptrace.get_IDU_Ical();
  uint64_t nB = ptrace.get_IDU_B();
  uint64_t nRcal = ptrace.get_IDU_Rcal();
  uint64_t nLoad = ptrace.get_IDU_LOAD();
  uint64_t nStore = ptrace.get_IDU_STORE();
  uint64_t nCSR = ptrace.get_IDU_CSR();
  uint64_t nOther = instr_cnt - (nU + nJ + nI + nIcal + nB + nRcal + nLoad + nStore + nCSR);

  trace_printf("\nptrace:指令完整周期统计 (周期数  占比  平均周期/指令):\n");
  if (total_ins_cyc == 0) {
    trace_printf("  (无数据)\n");
  } else {
    trace_printf("%-30s : %ld  (100.00%%)  总指令数: %ld\n", "  Total", total_ins_cyc, instr_cnt);
    auto print_line = [&](const char* name, uint64_t cycles, uint64_t count) {
      double avg = (count > 0) ? (double)cycles / count : 0.0;
      trace_printf("%-30s : %ld  (%.2f%%)  平均: %.2f\n", name, cycles, 100.0 * cycles / total_ins_cyc, avg);
    };
    print_line("  U-type (lui/auipc)", tU, nU);
    print_line("  J-type (jal)", tJ, nJ);
    print_line("  I-type (jalr/ecall/ebreak)", tI, nI);
    print_line("  I-ALU (addi etc)", tIcal, nIcal);
    print_line("  Branch (B-type)", tB, nB);
    print_line("  R-ALU", tRcal, nRcal);
    print_line("  Load", tLoad, nLoad);
    print_line("  Store", tStore, nStore);
    print_line("  CSR", tCSR, nCSR);
    print_line("  Other", tOther, nOther);
  }

  // ======== LSU 访存平均延迟（详细） ========
  trace_printf("\nptrace:LSU访存延迟统计:\n");
  uint64_t read_ops = ptrace.get_LSU_update_output_r_cnt();
  uint64_t write_ops = ptrace.get_LSU_update_output_w_cnt();
  if (read_ops > 0) {
      double avg_read = (double)ptrace.get_LSU_wait_read_cyc() / read_ops;
      trace_printf("  %-30s : 次数 %ld, 总等待周期 %ld, 平均 %.2f 周期/次\n", 
             "Read", read_ops, ptrace.get_LSU_wait_read_cyc(), avg_read);
  } else {
      trace_printf("  %-30s : 无\n", "Read");
  }
  if (write_ops > 0) {
      double avg_write = (double)ptrace.get_LSU_wait_write_cyc() / write_ops;
      trace_printf("  %-30s : 次数 %ld, 总等待周期 %ld, 平均 %.2f 周期/次\n",
             "Write", write_ops, ptrace.get_LSU_wait_write_cyc(), avg_write);
  } else {
      trace_printf("  %-30s : 无\n", "Write");
  }

  #ifdef ITRACE_CONFIG
    itrace_rb_pr();  // 内部已改用 trace_printf
  #endif
  return 0;
}