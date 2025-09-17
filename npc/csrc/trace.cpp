#include "trace.hpp"
#include "disasm.hpp"
#include "moniter.hpp"

char itrace_str[128];
const int itstr_length = 128;

FILE *trace_file;

void trace_init(){
    trace_file = fopen("./build/npc_log","w");
    assert(trace_file);
}

void itrace_print(int ins){
    if(disassemble(itrace_str,itstr_length,npc.pc,(uint8_t *)&ins,4) == -1) return;
    fprintf(trace_file,"pc:0x%08x ins:0x%08x ",npc.pc,ins);
    fprintf(trace_file,"%s\n",itrace_str);
    printf("pc:0x%08x ins:0x%08x ",npc.pc,ins);
    printf("%s\n",itrace_str);
    return;
}