#ifndef __PTRACE_HPP_
#define __PTRACE_HPP_

#include <cstdint>

#include "mem.hpp"   // MemType / MEM_TYPE_NUM / mem_type_of()

class PTRACE {
private:
    uint64_t clock;
    uint64_t instr;
    uint64_t freq;

    // 用于 INS_EXE 跟踪当前指令
    uint64_t curr_cyc;
    uint64_t last_idu_ready;

    // 各类指令总周期（由INS_EXE累加）
    uint64_t total_U_cyc;
    uint64_t total_J_cyc;
    uint64_t total_I_cyc;
    uint64_t total_Ical_cyc;
    uint64_t total_B_cyc;
    uint64_t total_Rcal_cyc;
    uint64_t total_LOAD_cyc;
    uint64_t total_STORE_cyc;
    uint64_t total_CSR_cyc;
    uint64_t total_OTHER_cyc;

    // IFU 统计
    uint64_t IFU_wait_start_cyc;
    uint64_t IFU_wait_mem_cyc;
    uint64_t IFU_update_output_cnt;
    uint64_t IFU_wait_IDU_cyc;

    // IDU 统计
    uint64_t IDU_U;
    uint64_t IDU_J;
    uint64_t IDU_I;
    uint64_t IDU_Ical;
    uint64_t IDU_B;
    uint64_t IDU_Rcal;
    uint64_t IDU_LOAD;
    uint64_t IDU_STORE;
    uint64_t IDU_CSR;
    uint64_t IDU_wait_IFU_cyc;
    uint64_t IDU_update_output_cnt;
    uint64_t IDU_wait_EXU_cyc;

    // EXU 统计
    uint64_t EXU_wait_IDU_cyc;
    uint64_t EXU_update_output_cnt;
    uint64_t EXU_wait_LSU_cyc;

    // WBU 统计
    uint64_t WBU_wait_LSU_cyc;
    uint64_t WBU_write_reg_cnt;

    // LSU 统计
    uint64_t LSU_wait_EXU_cyc;
    uint64_t LSU_wait_read_cyc;
    uint64_t LSU_update_output_r_cnt;
    uint64_t LSU_wait_write_cyc;
    uint64_t LSU_update_output_w_cnt;
    uint64_t LSU_wait_WBU_cyc;

    // ICache 统计
    uint64_t icache_hit_cnt;
    uint64_t icache_miss_cnt;
    // 按存储器类型分开的 ICache 统计（类型由 mem_type_of() 给出）
    uint64_t icache_mem_hit_cnt[MEM_TYPE_NUM];
    uint64_t icache_mem_miss_cnt[MEM_TYPE_NUM];
    // 命中/缺失各自花掉的周期总数，用来算平均访问时间和平均缺失代价
    uint64_t icache_hit_cycle_sum;
    uint64_t icache_miss_cycle_sum;

public:
    PTRACE();
    ~PTRACE();

    // 基础 getter
    uint64_t get_clock() const { return clock; }
    uint64_t get_instr() const { return instr; }
    void set_frequency(uint64_t f) { freq = f; }
    float get_ipc() const;
    float get_ips() const;

    // INS_EXE 处理
    void ins_exe(int ins, int ready);

    // 递增方法（由 DPI-C 调用）
    void clock_inc();
    void instr_inc();

    // IFU
    void IFU_wait_start_inc();
    void IFU_wait_mem_inc();
    void IFU_update_output_inc();
    void IFU_wait_IDU_inc();

    // IDU 类型计数
    void IDU_U_inc();
    void IDU_J_inc();
    void IDU_I_inc();
    void IDU_Ical_inc();
    void IDU_B_inc();
    void IDU_Rcal_inc();
    void IDU_LOAD_inc();
    void IDU_STORE_inc();
    void IDU_CSR_inc();
    void IDU_wait_IFU_inc();
    void IDU_update_output_inc();
    void IDU_wait_EXU_inc();

    // EXU
    void EXU_wait_IDU_inc();
    void EXU_update_output_inc();
    void EXU_wait_LSU_inc();

    // WBU
    void WBU_wait_LSU_inc();
    void WBU_write_reg_inc();

    // LSU
    void LSU_wait_EXU_inc();
    void LSU_wait_read_inc();
    void LSU_update_output_r_inc();
    void LSU_wait_write_inc();
    void LSU_update_output_w_inc();
    void LSU_wait_WBU_inc();

    // ICache
    // addr 是取指地址，存储器类型在这里调 mem_type_of() 判断
    void icache_access_inc(uint32_t addr, int is_hit);
    void icache_hit_cycle_inc(int cycles);
    void icache_miss_cycle_inc(int cycles);

    // Getter 方法（供 sim.cpp 打印）
    uint64_t get_IFU_wait_start_cyc() const { return IFU_wait_start_cyc; }
    uint64_t get_IFU_wait_mem_cyc()  const { return IFU_wait_mem_cyc; }
    uint64_t get_IFU_update_output_cnt() const { return IFU_update_output_cnt; }
    uint64_t get_IFU_wait_IDU_cyc()  const { return IFU_wait_IDU_cyc; }

    uint64_t get_IDU_U()      const { return IDU_U; }
    uint64_t get_IDU_J()      const { return IDU_J; }
    uint64_t get_IDU_I()      const { return IDU_I; }
    uint64_t get_IDU_Ical()   const { return IDU_Ical; }
    uint64_t get_IDU_B()      const { return IDU_B; }
    uint64_t get_IDU_Rcal()   const { return IDU_Rcal; }
    uint64_t get_IDU_LOAD()   const { return IDU_LOAD; }
    uint64_t get_IDU_STORE()  const { return IDU_STORE; }
    uint64_t get_IDU_CSR()    const { return IDU_CSR; }
    uint64_t get_IDU_wait_IFU_cyc() const { return IDU_wait_IFU_cyc; }
    uint64_t get_IDU_update_output_cnt() const { return IDU_update_output_cnt; }
    uint64_t get_IDU_wait_EXU_cyc() const { return IDU_wait_EXU_cyc; }

    uint64_t get_EXU_wait_IDU_cyc() const { return EXU_wait_IDU_cyc; }
    uint64_t get_EXU_update_output_cnt() const { return EXU_update_output_cnt; }
    uint64_t get_EXU_wait_LSU_cyc() const { return EXU_wait_LSU_cyc; }

    uint64_t get_WBU_wait_LSU_cyc() const { return WBU_wait_LSU_cyc; }
    uint64_t get_WBU_write_reg_cnt() const { return WBU_write_reg_cnt; }

    uint64_t get_LSU_wait_EXU_cyc() const { return LSU_wait_EXU_cyc; }
    uint64_t get_LSU_wait_read_cyc() const { return LSU_wait_read_cyc; }
    uint64_t get_LSU_update_output_r_cnt() const { return LSU_update_output_r_cnt; }
    uint64_t get_LSU_wait_write_cyc() const { return LSU_wait_write_cyc; }
    uint64_t get_LSU_update_output_w_cnt() const { return LSU_update_output_w_cnt; }
    uint64_t get_LSU_wait_WBU_cyc() const { return LSU_wait_WBU_cyc; }

    // ICache getter
    uint64_t get_icache_hit_cnt()  const { return icache_hit_cnt; }
    uint64_t get_icache_miss_cnt() const { return icache_miss_cnt; }
    // type 取值见 mem.hpp 的 MemType；越界返回 0
    uint64_t get_icache_mem_hit_cnt(int type) const;
    uint64_t get_icache_mem_miss_cnt(int type) const;

    // ICache 访问时间与缺失代价
    uint64_t get_icache_hit_cycle_sum()  const { return icache_hit_cycle_sum; }
    uint64_t get_icache_miss_cycle_sum() const { return icache_miss_cycle_sum; }
    // 平均取指时间（命中时的平均周期数），也就是常说的访问时间
    double get_icache_avg_hit_time() const;
    // 缺失时的平均周期数
    double get_icache_avg_miss_time() const;
    // 平均缺失代价 = 缺失时的平均周期 - 平均访问时间
    double get_icache_avg_miss_penalty() const;
    // AMAT = 平均访问时间 + 缺失率 × 平均缺失代价
    double get_icache_amat() const;

    // 指令周期统计
    uint64_t get_total_U_cyc()     const { return total_U_cyc; }
    uint64_t get_total_J_cyc()     const { return total_J_cyc; }
    uint64_t get_total_I_cyc()     const { return total_I_cyc; }
    uint64_t get_total_Ical_cyc()  const { return total_Ical_cyc; }
    uint64_t get_total_B_cyc()     const { return total_B_cyc; }
    uint64_t get_total_Rcal_cyc()  const { return total_Rcal_cyc; }
    uint64_t get_total_LOAD_cyc()  const { return total_LOAD_cyc; }
    uint64_t get_total_STORE_cyc() const { return total_STORE_cyc; }
    uint64_t get_total_CSR_cyc()   const { return total_CSR_cyc; }
    uint64_t get_total_OTHER_cyc() const { return total_OTHER_cyc; }
};

extern PTRACE ptrace;

#endif