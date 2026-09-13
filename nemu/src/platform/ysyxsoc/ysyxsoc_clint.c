#include <platform/ysyxsoc/ysyxsoc_clint.h>

// CLINT（核内中断控制器）。当前只有 mtime：
//   偏移 0 读 mtime[31:0]，偏移 4 读 mtime[63:32]
// 与 ysyx_25080209_CLINT_AXI4.v 一致，RTL 里 mtime 是每个时钟周期加一。
// NEMU 没有周期的概念，这里用已执行的 guest 指令数代替，保证单调递增且可复现。
extern uint64_t g_nr_guest_inst;

#define CLINT_MTIME_LO  0
#define CLINT_MTIME_HI  4

static word_t clint_read(paddr_t offset, int len){
    uint64_t mtime = g_nr_guest_inst;

    switch (offset)
    {
    case CLINT_MTIME_LO: return (word_t)mtime;
    case CLINT_MTIME_HI: return (word_t)(mtime >> 32);
    default:break;
    }
    return 0;
}

// RTL 侧没有写逻辑，mtimecmp 之类的寄存器也未实现，这里同样忽略写入
static void clint_write(paddr_t offset, int len, word_t data){
}

void ysyxsoc_clint_init(){
    YSYXSOC_MMIO ysyx_clint = {
    .addr = ADDR_CLINT,
    .lenth = LEN_CLINT,
    .mem = NULL,
    .access = RAW,
    .read = clint_read,
    .write = clint_write
    };

    ysyxsoc_add(ysyx_clint);
}
