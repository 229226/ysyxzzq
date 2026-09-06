#ifndef __FLASH_HPP_
#define __FLASH_HPP_

#include "common.hpp"

#define FLASH_ADDR_BASE 0x30000000
#define FLASH_SIZE      0x01000000

void* Flash_Get_PADDR();

#endif