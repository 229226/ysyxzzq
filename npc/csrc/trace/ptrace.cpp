#include "ptrace.hpp"

PTRACE ptrace;

// ========== DPI-C 导出函数（供 Verilog 调用） ==========
extern "C" {

// 基础
void INS_EXE(int ins, int ready) {
    ptrace.ins_exe(ins, ready);
}

// IFU
void IFU_wait_start()   { ptrace.IFU_wait_start_inc(); }
void IFU_wait_mem()     { ptrace.IFU_wait_mem_inc(); }
void IFU_update_output(){ ptrace.IFU_update_output_inc(); }
void IFU_wait_IDU()     { ptrace.IFU_wait_IDU_inc(); }

// IDU 指令类型
void IDU_U()    { ptrace.IDU_U_inc(); }
void IDU_J()    { ptrace.IDU_J_inc(); }
void IDU_I()    { ptrace.IDU_I_inc(); }
void IDU_Ical() { ptrace.IDU_Ical_inc(); }
void IDU_B()    { ptrace.IDU_B_inc(); }
void IDU_Rcal() { ptrace.IDU_Rcal_inc(); }
void IDU_LOAD() { ptrace.IDU_LOAD_inc(); }
void IDU_STORE(){ ptrace.IDU_STORE_inc(); }
void IDU_CSR()  { ptrace.IDU_CSR_inc(); }

// IDU 状态
void IDU_wait_IFU()       { ptrace.IDU_wait_IFU_inc(); }
void IDU_update_output()  { ptrace.IDU_update_output_inc(); }
void IDU_wait_EXU()       { ptrace.IDU_wait_EXU_inc(); }

// EXU
void EXU_wait_IDU()       { ptrace.EXU_wait_IDU_inc(); }
void EXU_update_output()  { ptrace.EXU_update_output_inc(); }
void EXU_wait_LSU()       { ptrace.EXU_wait_LSU_inc(); }

// WBU
void WBU_wait_LSU()       { ptrace.WBU_wait_LSU_inc(); }
void WBU_write_reg()      { ptrace.WBU_write_reg_inc(); }

// LSU
void LSU_wait_EXU()          { ptrace.LSU_wait_EXU_inc(); }
void LSU_wait_read()         { ptrace.LSU_wait_read_inc(); }
void LSU_update_output_r()   { ptrace.LSU_update_output_r_inc(); }
void LSU_wait_write()        { ptrace.LSU_wait_write_inc(); }
void LSU_update_output_w()   { ptrace.LSU_update_output_w_inc(); }
void LSU_wait_WBU()          { ptrace.LSU_wait_WBU_inc(); }

// ICache
void icache_access(int mem_type, int is_hit) { ptrace.icache_access_inc(mem_type, is_hit); }

} // extern "C"

// ========== PTRACE 实现 ==========

PTRACE::PTRACE() {
    clock = 0;
    instr = 0;
    freq = 0;
    curr_cyc = 0;
    last_idu_ready = 0;

    total_U_cyc = 0;
    total_J_cyc = 0;
    total_I_cyc = 0;
    total_Ical_cyc = 0;
    total_B_cyc = 0;
    total_Rcal_cyc = 0;
    total_LOAD_cyc = 0;
    total_STORE_cyc = 0;
    total_CSR_cyc = 0;
    total_OTHER_cyc = 0;

    IFU_wait_start_cyc = 0;
    IFU_wait_mem_cyc = 0;
    IFU_update_output_cnt = 0;
    IFU_wait_IDU_cyc = 0;

    IDU_U = 0;
    IDU_J = 0;
    IDU_I = 0;
    IDU_Ical = 0;
    IDU_B = 0;
    IDU_Rcal = 0;
    IDU_LOAD = 0;
    IDU_STORE = 0;
    IDU_CSR = 0;
    IDU_wait_IFU_cyc = 0;
    IDU_update_output_cnt = 0;
    IDU_wait_EXU_cyc = 0;

    EXU_wait_IDU_cyc = 0;
    EXU_update_output_cnt = 0;
    EXU_wait_LSU_cyc = 0;

    WBU_wait_LSU_cyc = 0;
    WBU_write_reg_cnt = 0;

    LSU_wait_EXU_cyc = 0;
    LSU_wait_read_cyc = 0;
    LSU_update_output_r_cnt = 0;
    LSU_wait_write_cyc = 0;
    LSU_update_output_w_cnt = 0;
    LSU_wait_WBU_cyc = 0;

    icache_hit_cnt = 0;
    icache_miss_cnt = 0;
    for (int i = 0; i < ICACHE_MEM_TYPE_NUM; i++) {
        icache_mem_hit_cnt[i] = 0;
        icache_mem_miss_cnt[i] = 0;
    }
}

PTRACE::~PTRACE() {}

// 基础方法
void PTRACE::clock_inc() { clock++; }
void PTRACE::instr_inc() { instr++; }

float PTRACE::get_ipc() const {
    return (clock == 0) ? 0.0f : static_cast<float>(instr) / static_cast<float>(clock);
}

float PTRACE::get_ips() const {
    if (clock == 0 || freq == 0) return 0.0f;
    return static_cast<float>(instr) * static_cast<float>(freq) / static_cast<float>(clock);
}

void PTRACE::ins_exe(int ins, int ready) {
    curr_cyc++;

    if (ready == 1 && last_idu_ready == 0) {
        uint32_t opcode = ins & 0x7f;
        uint32_t func3  = (ins >> 12) & 0x7;
        switch (opcode) {
            case 0b0110111: // LUI
            case 0b0010111: // AUIPC
                total_U_cyc += curr_cyc; break;
            case 0b1101111: // JAL
                total_J_cyc += curr_cyc; break;
            case 0b1100111: // JALR
                total_I_cyc += curr_cyc; break;
            case 0b1100011: // Branch
                total_B_cyc += curr_cyc; break;
            case 0b0000011: // Load
                total_LOAD_cyc += curr_cyc; break;
            case 0b0100011: // Store
                total_STORE_cyc += curr_cyc; break;
            case 0b0010011: // ALU I-type
                total_Ical_cyc += curr_cyc; break;
            case 0b0110011: // ALU R-type
                total_Rcal_cyc += curr_cyc; break;
            case 0b1110011: // CSR / ecall / ebreak
                if (func3 == 0)
                    total_I_cyc += curr_cyc;
                else
                    total_CSR_cyc += curr_cyc;
                break;
            default:
                total_OTHER_cyc += curr_cyc; break;
        }
        curr_cyc = 0;
        instr_inc();
    }
    last_idu_ready = ready;
}

// ---- 递增实现 ----
void PTRACE::IFU_wait_start_inc() { IFU_wait_start_cyc++; }
void PTRACE::IFU_wait_mem_inc()   { IFU_wait_mem_cyc++; }
void PTRACE::IFU_update_output_inc() { IFU_update_output_cnt++; }
void PTRACE::IFU_wait_IDU_inc()   { IFU_wait_IDU_cyc++; }

void PTRACE::IDU_U_inc()          { IDU_U++; }
void PTRACE::IDU_J_inc()          { IDU_J++; }
void PTRACE::IDU_I_inc()          { IDU_I++; }
void PTRACE::IDU_Ical_inc()       { IDU_Ical++; }
void PTRACE::IDU_B_inc()          { IDU_B++; }
void PTRACE::IDU_Rcal_inc()       { IDU_Rcal++; }
void PTRACE::IDU_LOAD_inc()       { IDU_LOAD++; }
void PTRACE::IDU_STORE_inc()      { IDU_STORE++; }
void PTRACE::IDU_CSR_inc()        { IDU_CSR++; }
void PTRACE::IDU_wait_IFU_inc()   { IDU_wait_IFU_cyc++; }
void PTRACE::IDU_update_output_inc() { IDU_update_output_cnt++; }
void PTRACE::IDU_wait_EXU_inc()   { IDU_wait_EXU_cyc++; }

void PTRACE::EXU_wait_IDU_inc()   { EXU_wait_IDU_cyc++; }
void PTRACE::EXU_update_output_inc() { EXU_update_output_cnt++; }
void PTRACE::EXU_wait_LSU_inc()   { EXU_wait_LSU_cyc++; }

void PTRACE::WBU_wait_LSU_inc()   { WBU_wait_LSU_cyc++; }
void PTRACE::WBU_write_reg_inc()  { WBU_write_reg_cnt++; }

void PTRACE::LSU_wait_EXU_inc()         { LSU_wait_EXU_cyc++; }
void PTRACE::LSU_wait_read_inc()        { LSU_wait_read_cyc++; }
void PTRACE::LSU_update_output_r_inc()  { LSU_update_output_r_cnt++; }
void PTRACE::LSU_wait_write_inc()       { LSU_wait_write_cyc++; }
void PTRACE::LSU_update_output_w_inc()  { LSU_update_output_w_cnt++; }
void PTRACE::LSU_wait_WBU_inc()         { LSU_wait_WBU_cyc++; }

void PTRACE::icache_access_inc(int mem_type, int is_hit) {
    if (mem_type < 0 || mem_type >= ICACHE_MEM_TYPE_NUM)
        mem_type = ICACHE_MEM_OTHER;

    if (is_hit) {
        icache_hit_cnt++;
        icache_mem_hit_cnt[mem_type]++;
    } else {
        icache_miss_cnt++;
        icache_mem_miss_cnt[mem_type]++;
    }
}

uint64_t PTRACE::get_icache_mem_hit_cnt(int type) const {
    if (type < 0 || type >= ICACHE_MEM_TYPE_NUM) return 0;
    return icache_mem_hit_cnt[type];
}

uint64_t PTRACE::get_icache_mem_miss_cnt(int type) const {
    if (type < 0 || type >= ICACHE_MEM_TYPE_NUM) return 0;
    return icache_mem_miss_cnt[type];
}

const char* PTRACE::icache_mem_type_name(int type) {
    switch (type) {
        case ICACHE_MEM_FLASH: return "flash";
        case ICACHE_MEM_MROM:  return "mrom";
        case ICACHE_MEM_SDRAM: return "sdram";
        case ICACHE_MEM_PSRAM: return "psram";
        case ICACHE_MEM_SRAM:  return "sram";
        default:               return "other";
    }
}