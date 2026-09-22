#include "sim.hpp"
#include "moniter.hpp"
#include "diff_test.hpp"
#include "trace.hpp"
#include <nvboard.h>
#include "ptrace.hpp"

#include <chrono>
#include <iostream>
#include <cstdarg>
#include <cstdio>
#include <string>
#include <vector>

// ========== 性能表格 ==========
// 除人读报告外，另写一份结构化表格到 build/perf_table.csv，供 make fill_excel
// 直接搬进 doc/NPC性能评估结果.xlsx（脚本不再解析日志）。
// 记录的先后顺序 = xlsx 里列的左右顺序（C→CX，跳过仿真产不出的 F 综合频率 /
// G 综合面积），加字段请照着表头插在对应位置。
static std::vector<std::string> g_tbl_name, g_tbl_value;

// 登记一个字段。用和报告里同样的格式串，保证表格与报告的数字逐位一致。
static void table_add(const char *name, const char *fmt, ...) {
    char buf[64];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    g_tbl_name.push_back(name);
    g_tbl_value.push_back(buf);
}

// 写成两行：第一行字段名，第二行对应的值
static void table_write(const char *path) {
    FILE *fp = fopen(path, "w");
    if (fp == NULL) {
        trace_printf("警告: 打不开 %s，性能表格没写出来\n", path);
        return;
    }
    for (size_t i = 0; i < g_tbl_name.size(); i++)
        fprintf(fp, "%s%s", i ? "," : "", g_tbl_name[i].c_str());
    fputc('\n', fp);
    for (size_t i = 0; i < g_tbl_value.size(); i++)
        fprintf(fp, "%s%s", i ? "," : "", g_tbl_value[i].c_str());
    fputc('\n', fp);
    fclose(fp);
    trace_printf("ptrace:性能表格已写入 %s（%lu 个字段）\n",
                 path, (unsigned long)g_tbl_name.size());
}

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
          sim_exec_one();
          sim_exec_one();//再执行4个周期方便ptrace
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

  ptrace.set_frequency(743056000UL);

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

  // ======== 3. EXU 模块统计 ========
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

  // ======== 6. ICache 模块统计 ========
  {
    uint64_t ic_hit   = ptrace.get_icache_hit_cnt();
    uint64_t ic_miss  = ptrace.get_icache_miss_cnt();
    uint64_t ic_total = ic_hit + ic_miss;
    double   hit_rate = (ic_total > 0) ? 100.0 * ic_hit / ic_total : 0.0;

    // 统一字段宽度，保证整段冒号对齐
    static const int IC_LABEL_W = 32;

    trace_printf("\nptrace:ICache 统计 (总访问 %ld 次):\n", ic_total);
    trace_printf("  %-*s : %ld  (%.2f%%)\n", IC_LABEL_W, "Hit",  ic_hit,  hit_rate);
    trace_printf("  %-*s : %ld  (%.2f%%)\n", IC_LABEL_W, "Miss", ic_miss,
                 ic_total > 0 ? 100.0 * ic_miss / ic_total : 0.0);
    trace_printf("  %-*s : %.2f%%\n",        IC_LABEL_W, "Hit Rate", hit_rate);

    // 按取指地址所属的存储器类型细分（类型与区间都由 mem.hpp/mem.cpp 统一给出）
    trace_printf("\nptrace:ICache 按存储器类型统计 (总访问 %ld 次):\n", ic_total);
    for (int t = 0; t < MEM_TYPE_NUM; t++) {
      uint64_t m_hit   = ptrace.get_icache_mem_hit_cnt(t);
      uint64_t m_miss  = ptrace.get_icache_mem_miss_cnt(t);
      uint64_t m_total = m_hit + m_miss;

      // 将类型名与地址范围拼成一个字段，放在冒号前
      char label[64];
      snprintf(label, sizeof(label), "%s %s",
               mem_type_name((MemType)t), mem_type_range_str((MemType)t));

      trace_printf("  %-*s : 访问 %ld (%.2f%%)  命中 %ld  缺失 %ld  命中率 %.2f%%\n",
                   IC_LABEL_W, label, m_total,
                   ic_total > 0 ? 100.0 * m_total / ic_total : 0.0,
                   m_hit, m_miss,
                   m_total > 0 ? 100.0 * m_hit / m_total : 0.0);
    }

    // 访问时间与缺失代价（周期数取自 icache.v 的计时逻辑）
    double avg_hit   = ptrace.get_icache_avg_hit_time();
    double avg_miss  = ptrace.get_icache_avg_miss_time();
    double penalty   = ptrace.get_icache_avg_miss_penalty();
    double miss_rate = ic_total > 0 ? (double)ic_miss / ic_total : 0.0;
    double amat      = ptrace.get_icache_amat();

    trace_printf("\nptrace:ICache 访问时间与缺失代价:\n");
    trace_printf("  %-*s : %.2f 周期  (命中总周期 %ld)\n",
                 IC_LABEL_W, "Avg access time", avg_hit, ptrace.get_icache_hit_cycle_sum());
    trace_printf("  %-*s : %.2f 周期  (缺失总周期 %ld)\n",
                 IC_LABEL_W, "Avg miss time", avg_miss, ptrace.get_icache_miss_cycle_sum());
    trace_printf("  %-*s : %.2f 周期  (缺失耗时 - 访问时间)\n",
                 IC_LABEL_W, "Avg miss penalty", penalty);
    trace_printf("  %-*s : %.4f\n", IC_LABEL_W, "Miss rate", miss_rate);
    trace_printf("  %-*s : %.2f 周期  (= %.2f + %.4f x %.2f)\n",
                 IC_LABEL_W, "AMAT", amat, avg_hit, miss_rate, penalty);
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

  // ======== 性能表格 ========
  // 按 npc/doc/NPC性能评估结果.xlsx 的列序登记 102 个字段，从 A 列起一一对齐。
  // 其中 A(commit)/B(说明)/F(综合频率)/G(综合面积) 仿真产不出来，占四个空位，
  // 复制脚本因此可以纯按位置搬，不用管从第几列开始。
  // 取值口径与上面报告里的原式逐项对应，只是这里为了不打扰报告代码，
  // 把几个原本在 {} 块内的模块总数就地重算了一遍。
  {
    g_tbl_name.clear();
    g_tbl_value.clear();

    auto pct = [](uint64_t cyc, uint64_t total) {
      return total ? 100.0 * cyc / total : 0.0;
    };

    // ---- A,B 元信息 ----
    // commit 和说明是人工填的，这里占两个空位，好让表格从 A 列起就和 xlsx 对齐。
    table_add("commit", "%s", "");
    table_add("desc",   "%s", "");

    // ---- C,D,E 基础 ----
    table_add("sim_cycles",  "%lu", (unsigned long)total_clock);
    table_add("instr_count", "%lu", (unsigned long)instr_cnt);
    table_add("ipc",         "%.4f", ptrace.get_ipc());
    // F 综合频率 / G 综合面积 仿真产不出来，占两个空位，
    // 这样表格的列序与 xlsx 的 C..CX 一一对齐，复制脚本才能纯按位置搬。
    table_add("freq", "%s", "");
    table_add("area", "%s", "");

    // ---- H..Q IFU（xlsx 把「取指次数」提到了这段最左边） ----
    uint64_t ifu_ws  = ptrace.get_IFU_wait_start_cyc();
    uint64_t ifu_wm  = ptrace.get_IFU_wait_mem_cyc();
    uint64_t ifu_upd = ptrace.get_IFU_update_output_cnt();
    uint64_t ifu_wi  = ptrace.get_IFU_wait_IDU_cyc();
    uint64_t ifu_tot = ifu_ws + ifu_wm + ifu_upd + ifu_wi;
    table_add("ifu_fetch_count",      "%lu",  (unsigned long)ifu_upd);
    table_add("ifu_wait_start_cyc",   "%lu",  (unsigned long)ifu_ws);
    table_add("ifu_wait_start_pct",   "%.2f", pct(ifu_ws, ifu_tot));
    table_add("ifu_wait_mem_cyc",     "%lu",  (unsigned long)ifu_wm);
    table_add("ifu_wait_mem_pct",     "%.2f", pct(ifu_wm, ifu_tot));
    table_add("ifu_update_output_cyc","%lu",  (unsigned long)ifu_upd);
    table_add("ifu_update_output_pct","%.2f", pct(ifu_upd, ifu_tot));
    table_add("ifu_wait_idu_cyc",     "%lu",  (unsigned long)ifu_wi);
    table_add("ifu_wait_idu_pct",     "%.2f", pct(ifu_wi, ifu_tot));
    table_add("ifu_total_cyc",        "%lu",  (unsigned long)ifu_tot);

    // ---- R..Y IDU ----
    uint64_t idu_wi  = ptrace.get_IDU_wait_IFU_cyc();
    uint64_t idu_upd = ptrace.get_IDU_update_output_cnt();
    uint64_t idu_we  = ptrace.get_IDU_wait_EXU_cyc();
    uint64_t idu_tot = idu_wi + idu_upd + idu_we;
    table_add("idu_decode_count",      "%lu",  (unsigned long)idu_upd);
    table_add("idu_wait_ifu_cyc",      "%lu",  (unsigned long)idu_wi);
    table_add("idu_wait_ifu_pct",      "%.2f", pct(idu_wi, idu_tot));
    table_add("idu_update_output_cyc", "%lu",  (unsigned long)idu_upd);
    table_add("idu_update_output_pct", "%.2f", pct(idu_upd, idu_tot));
    table_add("idu_wait_exu_cyc",      "%lu",  (unsigned long)idu_we);
    table_add("idu_wait_exu_pct",      "%.2f", pct(idu_we, idu_tot));
    table_add("idu_total_cyc",         "%lu",  (unsigned long)idu_tot);

    // ---- Z..AG EXU ----
    uint64_t exu_wi  = ptrace.get_EXU_wait_IDU_cyc();
    uint64_t exu_upd = ptrace.get_EXU_update_output_cnt();
    uint64_t exu_wl  = ptrace.get_EXU_wait_LSU_cyc();
    uint64_t exu_tot = exu_wi + exu_upd + exu_wl;
    table_add("exu_calc_count",        "%lu",  (unsigned long)exu_upd);
    table_add("exu_wait_idu_cyc",      "%lu",  (unsigned long)exu_wi);
    table_add("exu_wait_idu_pct",      "%.2f", pct(exu_wi, exu_tot));
    table_add("exu_update_output_cyc", "%lu",  (unsigned long)exu_upd);
    table_add("exu_update_output_pct", "%.2f", pct(exu_upd, exu_tot));
    table_add("exu_wait_lsu_cyc",      "%lu",  (unsigned long)exu_wl);
    table_add("exu_wait_lsu_pct",      "%.2f", pct(exu_wl, exu_tot));
    table_add("exu_total_cyc",         "%lu",  (unsigned long)exu_tot);

    // ---- AH..AV LSU（读/写次数同样被提到了段首） ----
    uint64_t lsu_we  = ptrace.get_LSU_wait_EXU_cyc();
    uint64_t lsu_wr  = ptrace.get_LSU_wait_read_cyc();
    uint64_t lsu_ur  = ptrace.get_LSU_update_output_r_cnt();
    uint64_t lsu_ww  = ptrace.get_LSU_wait_write_cyc();
    uint64_t lsu_uw  = ptrace.get_LSU_update_output_w_cnt();
    uint64_t lsu_wb  = ptrace.get_LSU_wait_WBU_cyc();
    uint64_t lsu_tot = lsu_we + lsu_wr + lsu_ur + lsu_ww + lsu_uw + lsu_wb;
    table_add("lsu_read_count",         "%lu",  (unsigned long)lsu_ur);
    table_add("lsu_write_count",        "%lu",  (unsigned long)lsu_uw);
    table_add("lsu_wait_exu_cyc",       "%lu",  (unsigned long)lsu_we);
    table_add("lsu_wait_exu_pct",       "%.2f", pct(lsu_we, lsu_tot));
    table_add("lsu_wait_read_cyc",      "%lu",  (unsigned long)lsu_wr);
    table_add("lsu_wait_read_pct",      "%.2f", pct(lsu_wr, lsu_tot));
    table_add("lsu_update_output_r_cyc","%lu",  (unsigned long)lsu_ur);
    table_add("lsu_update_output_r_pct","%.2f", pct(lsu_ur, lsu_tot));
    table_add("lsu_wait_write_cyc",     "%lu",  (unsigned long)lsu_ww);
    table_add("lsu_wait_write_pct",     "%.2f", pct(lsu_ww, lsu_tot));
    table_add("lsu_update_output_w_cyc","%lu",  (unsigned long)lsu_uw);
    table_add("lsu_update_output_w_pct","%.2f", pct(lsu_uw, lsu_tot));
    table_add("lsu_wait_wbu_cyc",       "%lu",  (unsigned long)lsu_wb);
    table_add("lsu_wait_wbu_pct",       "%.2f", pct(lsu_wb, lsu_tot));
    table_add("lsu_total_cyc",          "%lu",  (unsigned long)lsu_tot);

    // ---- AW..BB WBU ----
    uint64_t wbu_wl  = ptrace.get_WBU_wait_LSU_cyc();
    uint64_t wbu_wr  = ptrace.get_WBU_write_reg_cnt();
    uint64_t wbu_tot = wbu_wl + wbu_wr;
    table_add("wbu_write_count",      "%lu",  (unsigned long)wbu_wr);
    table_add("wbu_wait_lsu_cyc",     "%lu",  (unsigned long)wbu_wl);
    table_add("wbu_wait_lsu_pct",     "%.2f", pct(wbu_wl, wbu_tot));
    table_add("wbu_write_reg_cyc",    "%lu",  (unsigned long)wbu_wr);
    table_add("wbu_write_reg_pct",    "%.2f", pct(wbu_wr, wbu_tot));
    table_add("wbu_total_cyc",        "%lu",  (unsigned long)wbu_tot);

    // ---- BC..BK IDU 指令类型计数 ----
    table_add("idu_U",     "%lu", (unsigned long)nU);
    table_add("idu_J",     "%lu", (unsigned long)nJ);
    table_add("idu_I",     "%lu", (unsigned long)nI);
    table_add("idu_Ical",  "%lu", (unsigned long)nIcal);
    table_add("idu_B",     "%lu", (unsigned long)nB);
    table_add("idu_Rcal",  "%lu", (unsigned long)nRcal);
    table_add("idu_LOAD",  "%lu", (unsigned long)nLoad);
    table_add("idu_STORE", "%lu", (unsigned long)nStore);
    table_add("idu_CSR",   "%lu", (unsigned long)nCSR);

    // ---- BL..CP 各类指令的完整周期 / 占比 / 平均 ----
    table_add("total_ins_cyc", "%lu", (unsigned long)total_ins_cyc);
    auto add_ins = [&](const char *p, uint64_t cyc, uint64_t cnt) {
      char nm[32];
      snprintf(nm, sizeof(nm), "%s_cyc", p); table_add(nm, "%lu",  (unsigned long)cyc);
      snprintf(nm, sizeof(nm), "%s_pct", p); table_add(nm, "%.2f", pct(cyc, total_ins_cyc));
      snprintf(nm, sizeof(nm), "%s_avg", p); table_add(nm, "%.2f", cnt ? (double)cyc / cnt : 0.0);
    };
    add_ins("u",     tU,     nU);
    add_ins("j",     tJ,     nJ);
    add_ins("i",     tI,     nI);
    add_ins("ical",  tIcal,  nIcal);
    add_ins("b",     tB,     nB);
    add_ins("rcal",  tRcal,  nRcal);
    add_ins("load",  tLoad,  nLoad);
    add_ins("store", tStore, nStore);
    add_ins("csr",   tCSR,   nCSR);
    add_ins("other", tOther, nOther);

    // ---- CQ,CR LSU 访存平均延迟 ----
    table_add("lsu_read_avg",  "%.2f", read_ops  ? (double)ptrace.get_LSU_wait_read_cyc()  / read_ops  : 0.0);
    table_add("lsu_write_avg", "%.2f", write_ops ? (double)ptrace.get_LSU_wait_write_cyc() / write_ops : 0.0);

    // ---- CS..CX cache（这 6 列以前靠手填，现在一并输出） ----
    uint64_t c_hit   = ptrace.get_icache_hit_cnt();
    uint64_t c_miss  = ptrace.get_icache_miss_cnt();
    uint64_t c_total = c_hit + c_miss;
    table_add("cache_hit",              "%lu",  (unsigned long)c_hit);
    table_add("cache_miss",             "%lu",  (unsigned long)c_miss);
    table_add("cache_hit_rate",         "%.2f", pct(c_hit, c_total));
    table_add("cache_avg_access",       "%.2f", ptrace.get_icache_avg_hit_time());
    table_add("cache_avg_miss_penalty", "%.2f", ptrace.get_icache_avg_miss_penalty());
    table_add("cache_amat",             "%.2f", ptrace.get_icache_amat());

    table_write("./build/perf_table.csv");
  }

  #ifdef ITRACE_CONFIG
    itrace_rb_pr();  // 内部已改用 trace_printf
  #endif
  return 0;
}