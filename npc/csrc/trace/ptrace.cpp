#include "ptrace.hpp"

PTRACE ptrace;

// 外部 DPI-C 函数实现（由 Verilog 调用）
extern "C" {
    
void IFU_wait_start() {
    ptrace.IFU_wait_start_inc();
}
void IFU_wait_mem() {
    ptrace.IFU_wait_mem_inc();
}
void IFU_fetch() {
    ptrace.IFU_fetch_inc();
    ptrace.instr_inc();
}
void IFU_wait_IDU() {
    ptrace.IFU_wait_IDU_inc();
}

void LSU_read() {
    ptrace.LSU_read_inc();
}

void LSU_write() {
    ptrace.LSU_write_inc();
}

// ---- 新增 LSU 周期计数 DPI-C 函数 ----
void LSU_read_cyc() {
    ptrace.LSU_read_cyc_inc();
}

void LSU_write_cyc() {
    ptrace.LSU_write_cyc_inc();
}

void IDU_U() {
    ptrace.IDU_U_inc();
}

void IDU_J() {
    ptrace.IDU_J_inc();
}

void IDU_I() {
    ptrace.IDU_I_inc();
}

void IDU_Ical() {
    ptrace.IDU_Ical_inc();
}

void IDU_B() {
    ptrace.IDU_B_inc();
}

void IDU_Rcal() {
    ptrace.IDU_Rcal_inc();
}

void IDU_LOAD() {
    ptrace.IDU_LOAD_inc();
}

void IDU_STORE() {
    ptrace.IDU_STORE_inc();
}

void IDU_CSR() {
    ptrace.IDU_CSR_inc();
}

// 周期计数 DPI-C 函数
void IDU_U_cyc() {
    ptrace.IDU_U_cyc_inc();
}
void IDU_J_cyc() {
    ptrace.IDU_J_cyc_inc();
}
void IDU_I_cyc() {
    ptrace.IDU_I_cyc_inc();
}
void IDU_Ical_cyc() {
    ptrace.IDU_Ical_cyc_inc();
}
void IDU_B_cyc() {
    ptrace.IDU_B_cyc_inc();
}
void IDU_Rcal_cyc() {
    ptrace.IDU_Rcal_cyc_inc();
}
void IDU_LOAD_cyc() {
    ptrace.IDU_LOAD_cyc_inc();
}
void IDU_STORE_cyc() {
    ptrace.IDU_STORE_cyc_inc();
}
void IDU_CSR_cyc() {
    ptrace.IDU_CSR_cyc_inc();
}

void EXU_fini() {
    ptrace.EXU_fini_inc();
}

} // extern "C"

// PTRACE 构造函数
PTRACE::PTRACE()
{
    clock       = 0;
    instr       = 0;
    freq  = 0;

    IFU_fetch   = 0;

    IDU_U       = 0;
    IDU_J       = 0;
    IDU_I       = 0;
    IDU_Ical    = 0;
    IDU_B       = 0;
    IDU_Rcal    = 0;
    IDU_LOAD    = 0;
    IDU_STORE   = 0;
    IDU_CSR     = 0;
    // 初始化周期计数器
    IDU_U_cyc     = 0;
    IDU_J_cyc     = 0;
    IDU_I_cyc     = 0;
    IDU_Ical_cyc  = 0;
    IDU_B_cyc     = 0;
    IDU_Rcal_cyc  = 0;
    IDU_LOAD_cyc  = 0;
    IDU_STORE_cyc = 0;
    IDU_CSR_cyc   = 0;

    EXU_fini    = 0;

    LSU_read    = 0;
    LSU_write   = 0;
    LSU_read_cyc  = 0;   // 新增初始化
    LSU_write_cyc = 0;
}

PTRACE::~PTRACE()
{
}

// 递增实现（数量）
void PTRACE::clock_inc() {
    clock++;
}

void PTRACE::instr_inc() {
    instr++;
}

float PTRACE::get_ipc() {
    if (clock == 0) return 0.0f;
    return static_cast<float>(instr) / static_cast<float>(clock);
}

void PTRACE::set_frequency(uint64_t f) {
    freq = f;
}

float PTRACE::get_ips() const {
    if (clock == 0 || freq == 0) return 0.0f;
    // IPS = 指令数 / 时间（秒） = instr / (clock / freq) = instr * freq / clock
    return static_cast<float>(instr) * static_cast<float>(freq) / static_cast<float>(clock);
}

void PTRACE::IFU_wait_start_inc() {
    IFU_wait_start_cyc++;
}
void PTRACE::IFU_wait_mem_inc() {
    IFU_wait_mem_cyc++;
}
void PTRACE::IFU_fetch_inc() {
    IFU_fetch++;
}
void PTRACE::IFU_wait_IDU_inc() {
    IFU_wait_IDU_cyc++;
}

void PTRACE::IDU_U_inc() {
    IDU_U++;
}

void PTRACE::IDU_J_inc() {
    IDU_J++;
}

void PTRACE::IDU_I_inc() {
    IDU_I++;
}

void PTRACE::IDU_Ical_inc() {
    IDU_Ical++;
}

void PTRACE::IDU_B_inc() {
    IDU_B++;
}

void PTRACE::IDU_Rcal_inc() {
    IDU_Rcal++;
}

void PTRACE::IDU_LOAD_inc() {
    IDU_LOAD++;
}

void PTRACE::IDU_STORE_inc() {
    IDU_STORE++;
}

void PTRACE::IDU_CSR_inc() {
    IDU_CSR++;
}

void PTRACE::EXU_fini_inc() {
    EXU_fini++;
}

void PTRACE::LSU_read_inc() {
    LSU_read++;
}

void PTRACE::LSU_write_inc() {
    LSU_write++;
}

// 递增实现（周期）
void PTRACE::LSU_read_cyc_inc() {
    LSU_read_cyc++;
}
void PTRACE::LSU_write_cyc_inc() {
    LSU_write_cyc++;
}
void PTRACE::IDU_U_cyc_inc() {
    IDU_U_cyc++;
}
void PTRACE::IDU_J_cyc_inc() {
    IDU_J_cyc++;
}
void PTRACE::IDU_I_cyc_inc() {
    IDU_I_cyc++;
}
void PTRACE::IDU_Ical_cyc_inc() {
    IDU_Ical_cyc++;
}
void PTRACE::IDU_B_cyc_inc() {
    IDU_B_cyc++;
}
void PTRACE::IDU_Rcal_cyc_inc() {
    IDU_Rcal_cyc++;
}
void PTRACE::IDU_LOAD_cyc_inc() {
    IDU_LOAD_cyc++;
}
void PTRACE::IDU_STORE_cyc_inc() {
    IDU_STORE_cyc++;
}
void PTRACE::IDU_CSR_cyc_inc() {
    IDU_CSR_cyc++;
}