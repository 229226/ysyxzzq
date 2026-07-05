#include "disasm.hpp"
#include "capstone/capstone.h"
#include <dlfcn.h>

typedef size_t (*cs_disasm_dl)(csh handle, const uint8_t *code,
    size_t code_size, uint64_t address, size_t count, cs_insn **insn);
cs_disasm_dl my_cs_disasm;
typedef void (*cs_free_dl)(cs_insn *insn, size_t count);
cs_free_dl my_cs_free;

static csh handle;

void init_disasm(){
  void *dl_handle;
  dl_handle = dlopen("/home/zzq/ysyx-workbench/nemu/tools/capstone/repo/libcapstone.so.5", RTLD_LAZY);
  assert(dl_handle);

  typedef cs_err (*cs_open_dl)(cs_arch arch, cs_mode mode, csh *handle);
  cs_open_dl my_cs_open = (cs_open_dl)dlsym(dl_handle, "cs_open");
  assert(my_cs_open);

  my_cs_disasm = (cs_disasm_dl)dlsym(dl_handle, "cs_disasm");
  assert(my_cs_disasm);

  my_cs_free = (cs_free_dl) dlsym(dl_handle, "cs_free");
  assert(my_cs_free);

	int ret = my_cs_open(CS_ARCH_RISCV, CS_MODE_RISCV32, &handle);
  assert(ret == CS_ERR_OK);
}

int disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte) {
	cs_insn *insn;
	size_t count = my_cs_disasm(handle, code, nbyte, pc, 0, &insn);
  if(count == 0) return -1;
  int ret = snprintf(str, size, "%s", insn->mnemonic);
  if (insn->op_str[0] != '\0') {
    snprintf(str + ret, size - ret, "\t%s", insn->op_str);
  }
  my_cs_free(insn, count);
  
  return 0;
}