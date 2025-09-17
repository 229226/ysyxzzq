#ifndef __DISASM_HPP_
#define __DISASM_HPP_

#include "common.hpp"

void init_disasm();
int disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
#endif