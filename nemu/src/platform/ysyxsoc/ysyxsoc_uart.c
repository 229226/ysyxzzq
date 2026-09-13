#include <platform/ysyxsoc/ysyxsoc_uart.h>

// UART16550，数据总线 8 位，寄存器用 3 位地址（偏移 0~7）。
// 偏移   DLAB(LCR bit7)=0        DLAB=1
//   0    RBR(读) / THR(写)       DLL
//   1    IER                     DLM
//   2    IIR(读) / FCR(写)
//   3    LCR
//   4    MCR
//   5    LSR
//   6    MSR
//   7    SCR
#define UART_REG_RBR    0
#define UART_REG_THR    0
#define UART_REG_DLL    0
#define UART_REG_IER    1
#define UART_REG_DLM    1
#define UART_REG_IIR    2
#define UART_REG_FCR    2
#define UART_REG_LCR    3
#define UART_REG_MCR    4
#define UART_REG_LSR    5
#define UART_REG_MSR    6
#define UART_REG_SCR    7

// LCR
#define UART_LCR_DLAB   0x80

// LSR
#define UART_LSR_DR     0x01  // 接收数据就绪
#define UART_LSR_TFE    0x20  // 发送 FIFO 为空
#define UART_LSR_TE     0x40  // 发送器为空

// IIR: bit0 = 1 表示当前没有中断挂起
#define UART_IIR_NOINT  0x01

static uint8_t uart_dll = 0, uart_dlm = 0;
static uint8_t uart_ier = 0, uart_fcr = 0, uart_lcr = 0, uart_mcr = 0, uart_scr = 0;

static bool uart_dlab(){
    return (uart_lcr & UART_LCR_DLAB) != 0;
}

static word_t uart_read(paddr_t offset, int len){
    switch (offset)
    {
    // 接收暂未接入，DR 恒为 0，软件不会读到 RBR
    case UART_REG_RBR: return uart_dlab() ? uart_dll : 0;
    case UART_REG_IER: return uart_dlab() ? uart_dlm : uart_ier;
    case UART_REG_IIR: return UART_IIR_NOINT;
    case UART_REG_LCR: return uart_lcr;
    case UART_REG_MCR: return uart_mcr;
    // 发送 FIFO 和发送器恒为空，putch 的轮询因此不会阻塞
    case UART_REG_LSR: return UART_LSR_TFE | UART_LSR_TE;
    case UART_REG_MSR: return 0;
    case UART_REG_SCR: return uart_scr;
    default:break;
    }
    return 0;
}

static void uart_write(paddr_t offset, int len, word_t data){
    uint8_t byte = data & 0xff;

    switch (offset)
    {
    case UART_REG_THR:
        if(uart_dlab()) uart_dll = byte;
        else { putc(byte, stdout); fflush(stdout); }
        return;
    case UART_REG_IER:
        if(uart_dlab()) uart_dlm = byte;
        else uart_ier = byte;
        return;
    case UART_REG_FCR: uart_fcr = byte; return;
    case UART_REG_LCR: uart_lcr = byte; return;
    case UART_REG_MCR: uart_mcr = byte; return;
    case UART_REG_SCR: uart_scr = byte; return;
    default:break;  // LSR/MSR 只读
    }
}

void ysyxsoc_uart_init(){
    YSYXSOC_MMIO ysyx_uart = {
    .addr = ADDR_UART,
    .lenth = LEN_UART,
    .mem = NULL,
    .access = RAW,
    .read = uart_read,
    .write = uart_write
    };

    ysyxsoc_add(ysyx_uart);
}
