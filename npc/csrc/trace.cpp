#include "trace.hpp"
#include "disasm.hpp"
#include "moniter.hpp"

#define ITRACE_BUFLEN 128
#define ITRACE_RBLEN 20

char itrace_str[ITRACE_BUFLEN];
static char itrace_rb[ITRACE_RBLEN][ITRACE_BUFLEN];
static int rb_p = 0;

FILE *trace_file;

void trace_init(){
    trace_file = fopen("./build/npc_log","w");
    assert(trace_file);
}

void itrace_rb_add(char *str){
    if(rb_p >= 20){
        rb_p = 0;
        sprintf(itrace_rb[rb_p],"%s",str);
        rb_p++;
    }else{
        sprintf(itrace_rb[rb_p],"%s",str);
        rb_p++;
    }
}

void itrace_rb_pr(){
    for (int i = 0; i < ITRACE_RBLEN; i++)
    {
        printf("%s\n",itrace_rb[i]);
    }
}

void itrace_print(int ins){
    sprintf(itrace_str,"pc:0x%08x ins:0x%08x ",npc.pc,ins);
    if(disassemble(itrace_str + strlen(itrace_str),ITRACE_BUFLEN - strlen(itrace_str),npc.pc,(uint8_t *)&ins,4) == -1) {
        printf("itrace: 反编译失败\n");
        return;}
    itrace_rb_add(itrace_str);
    fprintf(trace_file,"%s\n",itrace_str);
    fflush(trace_file);
    return;
}

void mtrace_pread(uint32_t addr,uint32_t data){
    fprintf(trace_file,"mtrace:read addr=0x%08x data=0x%08x\n",addr,data);
    fflush(trace_file);
}
void mtrace_pwrite(uint32_t addr,uint32_t data){
    fprintf(trace_file,"mtrace:write addr=0x%08x data=0x%08x\n",addr,data);
    fflush(trace_file);
}