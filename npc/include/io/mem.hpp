#ifndef __MEM_HPP_
#define __MEM_HPP_

#include "common.hpp"
#include "pmem.hpp"

#define paddr_t uint32_t

void init_mem(char *file_img);

/* init_mem() 实际读入的镜像字节数，供 difftest 同步时确定拷贝长度 */
extern int g_img_size;

/* ========== 地址所属的存储器类型 ==========
 * RTL 侧不再做地址译码：icache / LSU 的 DPI 只上报原始物理地址，统一在这里判断，
 * 避免同一份地址表在多个模块里各写一遍。
 * 区间参考 abstract-machine/scripts/ysyxsoclinker.ld 与 ysyxSoC/src/SoC.scala。
 */
typedef enum {
    MEM_TYPE_FLASH = 0,
    MEM_TYPE_MROM,
    MEM_TYPE_SDRAM,
    MEM_TYPE_PSRAM,
    MEM_TYPE_SRAM,
    MEM_TYPE_UART,
    MEM_TYPE_SPI,
    MEM_TYPE_CLINT,
    MEM_TYPE_OTHER,
    MEM_TYPE_NUM
} MemType;

MemType     mem_type_of(uint32_t addr);
const char *mem_type_name(MemType type);
const char *mem_type_range_str(MemType type);

#endif