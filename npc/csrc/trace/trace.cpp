#include "trace.hpp"
#include "disasm.hpp"
#include "moniter.hpp"
#include <stdarg.h>
#include "ptrace.hpp"
#include <cstdio>

#define ITRACE_BUFLEN 128
#define ITRACE_RBLEN 20

char itrace_str[ITRACE_BUFLEN];
static char itrace_rb[ITRACE_RBLEN][ITRACE_BUFLEN];
static int rb_p = 0;
static int rb_full = 0;

FILE *trace_file;

extern "C" void itrace(int ins){
  if(npc_status.ins_state == INS_FINI){
  #ifdef ITRACE_CONFIG
    itrace_print(ins);
  #endif      
  }
}

void trace_init(){
    trace_file = fopen("./build/npc.log","w");
    assert(trace_file);
}

// 修正：分别使用独立的 va_list 副本
void trace_printf(const char *format, ...) {
    va_list args, args_copy;
    va_start(args, format);
    va_copy(args_copy, args);   // 立即拷贝一份用于文件输出

    // 输出到终端
    vprintf(format, args);
    va_end(args);   // 关闭终端用的 args

    // 输出到日志文件
    if (trace_file) {
        vfprintf(trace_file, format, args_copy);
        fflush(trace_file);
    }
    va_end(args_copy);
}

void trace_write(const char *format,...){
    va_list args;
    va_start(args, format);          
    vfprintf(trace_file, format, args); 
    fflush(trace_file);
    va_end(args);
}

void itrace_rb_add(char *str){
    if(rb_p >= 20){
        rb_full = 1;
        rb_p = 0;
        sprintf(itrace_rb[rb_p],"%s",str);
        rb_p++;
    }else{
        sprintf(itrace_rb[rb_p],"%s",str);
        rb_p++;
    }
}

void itrace_rb_pr(){
    if(rb_full){
        for (int i = rb_p; i < rb_p + 20; i++){
            trace_printf("%s\n", itrace_rb[(i % 20)]);
        }
    } else {
        for (int i = 0; i < rb_p; i++){
            trace_printf("%s\n", itrace_rb[i]);
        }   
    }
}

void itrace_print(int ins){
    if(ins == 0) return;
    
    sprintf(itrace_str,"pc:0x%08x ins:0x%08x ",npc.pc,ins);
    if(disassemble(itrace_str + strlen(itrace_str),ITRACE_BUFLEN - strlen(itrace_str),npc.pc,(uint8_t *)&ins,4) == -1) {
        trace_printf("itrace: 反编译失败 pc:0x%08x ins:0x%08x\n",npc.pc,ins);
        return;
    }
    itrace_rb_add(itrace_str);
    trace_write("%s\n",itrace_str);
    return;
}

void mtrace_read(uint32_t addr,uint32_t data,int data_wid){
    trace_write("mtrace:read addr=0x%08x data=0x%0*x\n",addr,2*data_wid,data);
}
void mtrace_write(uint32_t addr,uint32_t data,int data_wid){
    trace_write("mtrace:write addr=0x%08x data=0x%0*x\n",addr,2*data_wid,data);
}