#include <elf.h>
#include <common.h>
#include <cpu/cpu.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>

#define FUNC_MAX 4096
#define FNMAE_MAX 128

static  uint32_t func_addr[FUNC_MAX];
static  int func_len[FUNC_MAX];
static  char func_name[FUNC_MAX][FNMAE_MAX];
static  int func_num = 0;
static  int func_depth = 0;

int ftrace_addf(char *name,uint32_t addr,int len);
int ftrace_findf(uint32_t addr);
int ftrace_findr(uint32_t addr_ret);
void ftrace_print(uint32_t pc,int findex,int f_r);
void ftrace_pcall(uint32_t pc,uint32_t faddr);
void ftrace_pret(uint32_t pc);

void init_ftrace(const char *log_file){
    int fd;
    struct stat st;
    void *map;

    if((fd = open(log_file,O_RDONLY)) < 0){
        Log("打开elf文件失败");
        goto common_out;
    }
    
    if(fstat(fd,&st)<0){
        Log("读取elf文件状态失败");
        goto file_out;
    }
    
    map = mmap(NULL,st.st_size,PROT_READ,MAP_PRIVATE,fd,0);
    if(map == MAP_FAILED){
        Log("elf内存映射失败");
        goto file_out;
    }

    unsigned char* e_ident = (unsigned char*)map;

    if (e_ident[EI_MAG0] != ELFMAG0 ||
        e_ident[EI_MAG1] != ELFMAG1 ||
        e_ident[EI_MAG2] != ELFMAG2 ||
        e_ident[EI_MAG3] != ELFMAG3){
            Log("文件不是elf文件");
            goto mmap_out;
        }     

    int symtab_num = 0;
    char *strtab = NULL;
    if(e_ident[EI_CLASS] == ELFCLASS32){
        Log("ELF为32位格式");
        Elf32_Ehdr *elf_head = (Elf32_Ehdr *)map;
        Elf32_Shdr *shdr = (Elf32_Shdr *)(map + elf_head->e_shoff);
        Elf32_Sym *symtab = NULL;
        for (int i = 0; i < elf_head->e_shnum; i++) {
            if(shdr[i].sh_type == SHT_SYMTAB){
                //获取符号表的位置与个数
                symtab = (Elf32_Sym*)(map + shdr[i].sh_offset);
                symtab_num = shdr[i].sh_size/sizeof(Elf32_Sym);
                Log("ELF找到%d个符号",symtab_num);

                strtab = (char *)(map + shdr[i+1].sh_offset);
                break;
            }
        }
        if((symtab!=NULL)&&(strtab!=NULL)){
            for(int i = 0;i < symtab_num; i++){
                if(ELF32_ST_TYPE(symtab[i].st_info) == STT_FUNC){
                    if(ftrace_addf(strtab + symtab[i].st_name,symtab[i].st_value,symtab[i].st_size) < 0)
                    goto mmap_out;
                }
            }
        }else{
            Log("无法找到符号表与字符表");
            goto mmap_out;
        }
    }else if(e_ident[EI_CLASS] == ELFCLASS64){
        Log("ELF为64位格式");
        Elf64_Ehdr *elf_head = (Elf64_Ehdr *)map;
        Elf64_Shdr *shdr = (Elf64_Shdr *)(map + elf_head->e_shoff);
        Elf64_Sym *symtab = NULL;
        for (int i = 0; i < elf_head->e_shnum; i++) {
            if(shdr[i].sh_type == SHT_SYMTAB){
                //获取符号表的位置与个数
                symtab = (Elf64_Sym*)((char*)map + shdr[i].sh_offset);
                symtab_num = shdr[i].sh_size/sizeof(Elf64_Sym);
                Log("ELF找到%d个符号",symtab_num);

                strtab = (char *)(map + shdr[i+1].sh_offset);
            }
        }
        if((symtab!=NULL)&&(strtab!=NULL)){
            for(int i = 0;i < symtab_num; i++){
                if(ELF32_ST_TYPE(symtab[i].st_info) == STT_FUNC){
                    if(ftrace_addf(strtab + symtab[i].st_name,symtab[i].st_value,symtab[i].st_size) < 0)
                    goto mmap_out;
                }
            }
        }else{
            Log("无法找到符号表与字符表");
            goto mmap_out;
        }
    }else {
        Log("无法识别Elf文件为64/32");
        goto mmap_out;
    }

    munmap(map,st.st_size);
    close(fd);   
    return;

    mmap_out:
    munmap(map,st.st_size);
    file_out:
    close(fd);
    common_out:
    nemu_state.state = NEMU_ABORT;        
    return;
}

int ftrace_addf(char *name,uint32_t addr,int len){
    if(func_num >= FUNC_MAX){
        Log("ftrace:函数缓存区空间不足");
        return -1;
    }
    if(strlen(name) > (FNMAE_MAX - 1)){
        Log("ftrace:函数名长度过长");
        return -1;
    }
    func_addr[func_num] = addr;
    func_len[func_num] = len;
    strcpy((char *)&func_name[func_num],name);
    func_num++;
    Log("添加函数名为%s,函数地址为0x%x,函数长度为%d",name,addr,len);
    return 0;
}

void ftrace_pcall(uint32_t pc,uint32_t faddr){
    int fun_index = ftrace_findf(faddr);
    ftrace_print(pc,fun_index,1);
}
void ftrace_pret(uint32_t pc){
    int ret_index = ftrace_findr(pc);
    ftrace_print(pc,ret_index,0);
}

void ftrace_print(uint32_t pc,int findex,int f_r){
        if(findex >= 0){
        log_write("ftrace:0x%08x: ",pc);
        for (int i = 0; i < func_depth; i++)
        {
            log_write("  ");
        }
        if(f_r){
            log_write("call [%s@0x%x]\n",(char *)&func_name[findex],func_addr[findex]);
            func_depth++;
        }else{
            log_write("ret [%s]\n",(char *)&func_name[findex]);
            func_depth--;
        }   
    }
}

int ftrace_findf(uint32_t addr){
    for (int i = 0; i < func_num; i++)
    {
        if(addr == func_addr[i])
        return i;
    }
    return -1;
}

int ftrace_findr(uint32_t addr_ret){
    for (int i = 0; i < func_num; i++)
    {
        int offset = addr_ret - func_addr[i];
        if((offset > 0) && (offset <= func_len[i]))
        return i;
    }
    return -1;
}