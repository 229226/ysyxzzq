#ifndef __PTRACE_HPP_
#define __PTRACE_HPP_

#include "common.hpp"

typedef class PTRACE
{
private:
    uint64_t clock;          // 总时钟周期
    uint64_t instr;          // 完成指令数
    uint64_t freq;
    
    uint64_t IFU_wait_start_cyc;
    uint64_t IFU_fetch;
    uint64_t IFU_wait_mem_cyc;
    uint64_t IFU_wait_IDU_cyc;

    // IDU 指令类型计数
    uint64_t IDU_U;          // lui / auipc
    uint64_t IDU_J;          // jal
    uint64_t IDU_I;          // jalr / ecall / ebreak (I-type control)
    uint64_t IDU_Ical;       // ALU I-type (addi, etc.)
    uint64_t IDU_B;          // branch
    uint64_t IDU_Rcal;       // ALU R-type
    uint64_t IDU_LOAD;       // load
    uint64_t IDU_STORE;      // store
    uint64_t IDU_CSR;        // CSR 操作

    // IDU 各类指令的周期计数（累加每条指令在 IDU 阶段的周期数）
    uint64_t IDU_U_cyc;
    uint64_t IDU_J_cyc;
    uint64_t IDU_I_cyc;
    uint64_t IDU_Ical_cyc;
    uint64_t IDU_B_cyc;
    uint64_t IDU_Rcal_cyc;
    uint64_t IDU_LOAD_cyc;
    uint64_t IDU_STORE_cyc;
    uint64_t IDU_CSR_cyc;

    // EXU 完成计算次数
    uint64_t EXU_fini;

    // LSU 访存计数（指令数）
    uint64_t LSU_read;
    uint64_t LSU_write;

    // LSU 访存周期计数（累计等待周期）
    uint64_t LSU_read_cyc;
    uint64_t LSU_write_cyc;

public:
    PTRACE();
    ~PTRACE();

    // Getter 方法（便于外部查询）
    uint64_t get_clock()      const { return clock; }
    uint64_t get_instr()      const { return instr; }
    void set_frequency(uint64_t f);
    float get_ips() const;
    
    uint64_t get_IFU_wait_start_cyc() const { return IFU_wait_start_cyc; }
    uint64_t get_IFU_wait_mem_cyc()  const { return IFU_wait_mem_cyc; }
    uint64_t get_IFU_fetch()  const { return IFU_fetch; }
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

    uint64_t get_EXU_fini()   const { return EXU_fini; }

    uint64_t get_LSU_read()   const { return LSU_read; }
    uint64_t get_LSU_write()  const { return LSU_write; }
    uint64_t get_LSU_read_cyc()  const { return LSU_read_cyc; }
    uint64_t get_LSU_write_cyc() const { return LSU_write_cyc; }

    // 周期统计的 getter
    uint64_t get_IDU_U_cyc()     const { return IDU_U_cyc; }
    uint64_t get_IDU_J_cyc()     const { return IDU_J_cyc; }
    uint64_t get_IDU_I_cyc()     const { return IDU_I_cyc; }
    uint64_t get_IDU_Ical_cyc()  const { return IDU_Ical_cyc; }
    uint64_t get_IDU_B_cyc()     const { return IDU_B_cyc; }
    uint64_t get_IDU_Rcal_cyc()  const { return IDU_Rcal_cyc; }
    uint64_t get_IDU_LOAD_cyc()  const { return IDU_LOAD_cyc; }
    uint64_t get_IDU_STORE_cyc() const { return IDU_STORE_cyc; }
    uint64_t get_IDU_CSR_cyc()   const { return IDU_CSR_cyc; }

    // 递增方法（数量）
    void clock_inc();
    void instr_inc();

    void IFU_wait_start_inc();
    void IFU_wait_mem_inc();
    void IFU_fetch_inc();
    void IFU_wait_IDU_inc();

    void IDU_U_inc();
    void IDU_J_inc();
    void IDU_I_inc();
    void IDU_Ical_inc();
    void IDU_B_inc();
    void IDU_Rcal_inc();
    void IDU_LOAD_inc();
    void IDU_STORE_inc();
    void IDU_CSR_inc();

    void EXU_fini_inc();

    void LSU_read_inc();
    void LSU_write_inc();

    // 递增方法（周期）
    void LSU_read_cyc_inc();
    void LSU_write_cyc_inc();
    void IDU_U_cyc_inc();
    void IDU_J_cyc_inc();
    void IDU_I_cyc_inc();
    void IDU_Ical_cyc_inc();
    void IDU_B_cyc_inc();
    void IDU_Rcal_cyc_inc();
    void IDU_LOAD_cyc_inc();
    void IDU_STORE_cyc_inc();
    void IDU_CSR_cyc_inc();

    // 计算 IPC
    float get_ipc();
} PTRACE;

extern PTRACE ptrace;

#endif