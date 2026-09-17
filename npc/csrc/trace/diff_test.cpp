#include "diff_test.hpp"
#include "mem.hpp"
#include "flash.hpp"
#include "pmem.hpp"
#include "dlfcn.h"
#include "moniter.hpp"

typedef void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction);
ref_difftest_memcpy my_difftest_memcpy;
typedef void (*ref_difftest_regcpy)(void *dut, bool direction);
ref_difftest_regcpy my_difftest_regcpy;
typedef void (*ref_difftest_exec)(uint64_t n);
ref_difftest_exec my_difftest_exec;
typedef void (*ref_difftest_raise_intr)(uint64_t NO);
ref_difftest_raise_intr my_difftest_raise_intr;
typedef void (*ref_difftest_init)(int port);
ref_difftest_init my_difftest_init;

// ========== LSU 访存上报（DPI-C，来自 ysyx_25080209_LSU.v） ==========
// 真实外设的寄存器在 DUT 和 REF 里读数/时序不可能一致，指令条数会合法地跑偏，
// 这类指令的架构结果本来就没有可比性：
//   UART : putch 轮询 LSR 的 THRE，DUT 要等真实周期、NEMU 直接返回就绪；
//   CLINT: ref 的 ysyxsoc_clint 走的是 NEMU 自己的计数器，rdtime/mtimecmp
//          不可能与 SoC 里的 CLINT 逐拍对齐。
// LSU 在指令执行期间打上这个标记，diff_step() 只跳过受影响的这一条。
// 地址到存储器类型的判断统一走 mem_type_of()（csrc/io/mem.cpp）。
static bool lsu_touched_dev = false;

extern "C" void lsu_access(int is_mem, int addr) {
    if(!is_mem) return;

    MemType type = mem_type_of((uint32_t)addr);
    if(type == MEM_TYPE_UART || type == MEM_TYPE_CLINT) lsu_touched_dev = true;
}

void diff_init(){
    void *dl_handle;
    dl_handle = dlopen("/home/zzq/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so", RTLD_LAZY);
    assert(dl_handle);

    my_difftest_memcpy = (ref_difftest_memcpy)dlsym(dl_handle,"difftest_memcpy");
    assert(my_difftest_memcpy);

    my_difftest_regcpy = (ref_difftest_regcpy)dlsym(dl_handle,"difftest_regcpy");
    assert(my_difftest_regcpy);

    my_difftest_exec = (ref_difftest_exec)dlsym(dl_handle,"difftest_exec");
    assert(my_difftest_exec);

    my_difftest_raise_intr = (ref_difftest_raise_intr)dlsym(dl_handle,"difftest_raise_intr");
    assert(my_difftest_raise_intr);

    my_difftest_init = (ref_difftest_init)dlsym(dl_handle,"difftest_init");
    assert(my_difftest_init);

    my_difftest_init(0);

#ifdef YSYXSOC_CONFIG
    /*
     * ysyxSoC 环境下 DUT 从 flash(0x30000000) 启动，取指经 SoC 的 SPI flash 外设
     * (ysyxSoC/perip/flash/flash.v) -> DPI flash_read() 落到本进程的 flash[]，
     * 所以 flash[] 就是 DUT 真实的 flash 内容，把它推给 ref 即可。
     * ref 的 difftest_init() 只做 init_mem()+init_isa()，不调用 load_img()，
     * 同步之前 ref 的 flash 是全 0。
     * flash.v 只支持 03h 读命令，DUT 不会改 flash，开机同步一次就够。
     * 注意：FLASH_ADDR_BASE 必须与 NEMU 的 CONFIG_MBASE 一致(0x30000000)，
     *       tmp.pc 必须与 IFU 的 BOOT_PC 一致(由 npc/Makefile 的 BOOT_PC 写入)。
     */
    assert(g_img_size > 0 && (size_t)g_img_size <= FLASH_SIZE);
    my_difftest_memcpy(FLASH_ADDR_BASE,Flash_Get_PADDR(),(size_t)g_img_size,DIFFTEST_TO_REF);

    NPC tmp = {0};
    tmp.pc = FLASH_ADDR_BASE;
    my_difftest_regcpy(&tmp,DIFFTEST_TO_REF);
#else
    /*
     * NPC_CONFIG：源应当是 pmem 数组本身，而不是主机地址 0x80000000 这个野指针
     * （pmem[] 是 .bss 里的静态数组，没有任何 mmap 把它映射到 0x80000000）。
     * 长度同样用实际镜像大小，NEMU 侧的可用窗口远小于 NPC 的 PMEM_SIZE。
     */
    assert(g_img_size > 0 && (size_t)g_img_size <= PMEM_SIZE);
    my_difftest_memcpy(RESETADDR,PMEM_Get_PADDR(),(size_t)g_img_size,DIFFTEST_TO_REF);

    NPC tmp = {0};
    tmp.pc = RESETADDR;
    my_difftest_regcpy(&tmp,DIFFTEST_TO_REF);
#endif
    return;
}

int diff_checkregs(NPC ref){
    int diff = 0;

    for (int i = 0; i < REGS_NUM; i++)
    {
        if(ref.reg[i] != npc.reg[i]){
            printf("diff_test: ref: ");
            print_reg(ref,i);
            printf("diff_test: npc: ");
            print_reg(npc,i);
            diff = 1;
        } 
    }
    if(ref.pc != npc.pc) {
        diff = 1;
    }
    return diff;
}

void checkregs(NPC ref){
    if(diff_checkregs(ref)){
        npc_status.status = NPC_ABORT;
        npc_status.ebreak_ret = -1;
        printf("diff_test:状态不一致，终止！\n");
        printf("REF寄存器为:\n");
        print_regs(ref);
        printf("NPC寄存器为:\n");
        print_regs(npc);
    }
}

void diff_step(){
    if(lsu_touched_dev){
        // 刚退休的这条指令访问了 UART / CLINT：它的架构结果依赖外设时序，两边
        // 本来就可能不同，比对没有意义。不推进 REF，直接把 NPC 的架构状态灌过去，
        // 让它从这里重新与 DUT 对齐（与 NEMU dut.c 里 is_skip_ref 的做法一致）。
        lsu_touched_dev = false;
        my_difftest_regcpy(&npc,DIFFTEST_TO_REF);
        return;
    }

    NPC ref;

    my_difftest_exec(1);
    my_difftest_regcpy(&ref,DIFFTEST_TO_DUT);
    checkregs(ref);
}