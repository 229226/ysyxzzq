#include <utils.h>
#include <utils/pctrace.h>

// PC 轨迹文件，记录 guest 执行过的 PC 序列。
// 顺序执行（pc == 上一条 + 4）的指令会并成一段，每段只落一条记录：
//   start_pc(u32) + count(u32)，小端序。
// 这样一段连续代码只占 8 字节，而不是每条指令一行。
#define PCTRACE_FILE "./build/pctrace.bin"

static FILE *pctrace_fp = NULL;
static bool pctrace_opened = false;
static vaddr_t pctrace_run_start = 0;  // 当前段的起始 PC
static vaddr_t pctrace_last_pc = 0;    // 当前段最后一条指令的 PC
static uint32_t pctrace_run_len = 0;   // 当前段已累计的指令数

static void pctrace_flush(){
    if(pctrace_run_len == 0) return;
    uint32_t rec[2] = { (uint32_t)pctrace_run_start, pctrace_run_len };
    fwrite(rec, sizeof(uint32_t), 2, pctrace_fp);
    pctrace_run_len = 0;
}

// 文件在第一条指令到来时才创建，避免没跑程序也留下一个空文件
static void pctrace_open(){
    if(pctrace_opened) return;
    pctrace_opened = true;

    pctrace_fp = fopen(PCTRACE_FILE, "wb");
    if(pctrace_fp == NULL){
        Log("pctrace: 无法打开 %s，PC 轨迹已禁用", PCTRACE_FILE);
    }
}

void pctrace_record(vaddr_t pc){
    if(pctrace_fp == NULL){
        pctrace_open();
        if(pctrace_fp == NULL) return;
    }

    if(pctrace_run_len > 0 && pc == pctrace_last_pc + 4){
        pctrace_last_pc = pc;
        pctrace_run_len++;
        return;
    }

    pctrace_flush();
    pctrace_run_start = pc;
    pctrace_last_pc = pc;
    pctrace_run_len = 1;
}

void pctrace_close(){
    if(pctrace_fp == NULL) return;

    pctrace_flush();
    fclose(pctrace_fp);
    pctrace_fp = NULL;
    Log("pctrace: PC 轨迹已写入 %s", PCTRACE_FILE);
}
