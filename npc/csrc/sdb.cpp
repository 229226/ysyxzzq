#include "sdb.hpp"
#include <readline/readline.h>
#include <readline/history.h>
#include "sim.hpp"
#include "moniter.hpp"

uint32_t str2num(char *strnum,int type){
    char *endptr;
    errno = 0;
    unsigned long num = strtoul(strnum,&endptr,type);
    if(errno == ERANGE){
        printf("数字过长\n");
    }else if(*endptr != '\0'){
        printf("数字中有非法字符\n");
    }else{
        return (uint32_t)num;
    }
    return 0;   
}

static int cmd_help(char *argv);
static int cmd_c(char *argv){
    sim_exec(-1);
    return 0;
}
static int cmd_q(char *argv);
static int cmd_si(char *argv);
static int cmd_sh(char *argv){
    sim_exec_half();
    return 0;
}
static int cmd_x(char *argv);
static int cmd_pr(char *argv);

static struct
{
    const char *name;
    const char *discription;
    int (*handle)(char *);
}cmd_table[] = {
    {"help","帮助",cmd_help},
    {"c","运行",cmd_c},
    {"q","退出",cmd_q},
    {"si","单步执行 si + dec",cmd_si},
    {"sh","执行半个周期",cmd_sh},
    {"x","内存扫描 x + dex + 0x..",cmd_x},
    {"pr","打印寄存器",cmd_pr},
};

const int cmd_num = sizeof(cmd_table)/sizeof(cmd_table[0]);

static void cmd_phelp(int num){
    if(num > 0 && num <= cmd_num)
        printf("%-8s%s\n",cmd_table[num-1].name,cmd_table[num-1].discription);
    else 
        printf("打印help需要正确的index\n");
}

static int cmd_help(char *argv){
    for(int i = 1; i <= cmd_num; i++){
        cmd_phelp(i);
    }
    return 0;
}
static int cmd_q(char *argv){
    npc_status.status = NPC_QUIT;
    return -1;
}
static int cmd_si(char *argv){
    char *strnum = strtok(NULL," ");
    uint32_t num = 1;
    if(strnum != NULL){
        num = str2num(strnum,10);
    }
    
    sim_exec(num);
    return 0;
}
static int cmd_x(char *argv){
    char *strnum = strtok(NULL," ");
    char *strhex = strtok(NULL," ");
    
    if(strnum != NULL && strhex != NULL){
        uint32_t length = str2num(strnum,10);
        uint32_t addr = str2num(strhex,16);

        printf("%x %x\n",length,addr);

        for (int i = 0; i < length; i++)
        {
            uint32_t i_addr = addr + 4*i;
            printf("0x%08x:   0x%08x\n",i_addr,mem_read(i_addr));
        }
    }else{
        cmd_phelp(4);
    }

    return 0;
}
static int cmd_pr(char *argv){
    print_regs(npc);
    return 0;
}

int cmd_handle(char *argv){
    char *token;
    token = strtok(argv," ");
    if(token != NULL){
        for (int i = 0 ; i < cmd_num; i++)
        {   
            if(strcmp(token,cmd_table[i].name) == 0){
                return cmd_table[i].handle(argv);
            }
        }
        printf("无效指令\n");
    }else{
        printf("请输入指令\n");
    }
    return 0;
}

void sdb_mainloop(){
    while(1){
        char *input = NULL;
        if(input != NULL){
            free(input);
        }
        input = readline("NPCsdb:");
        add_history(input);
        if(cmd_handle(input) != 0){
            break;
        }
    }
    return;
}