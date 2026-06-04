AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
CFLAGS    += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include
LDSCRIPTS += $(AM_HOME)/scripts/ysyxsoclinker.ld
LDFLAGS   += --defsym=_mrom_start=0x20000000 --defsym=_entry_offset=0x00000000
LDFLAGS   += --defsym=_sram_start=0x0f000000
LDFLAGS   += --gc-sections -e _start

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = The insert-arg rule in Makefile will insert mainargs here.
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=\""$(MAINARGS_PLACEHOLDER)"\"

insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg 
	$(MAKE) -C $(NPC_HOME) run  ARGS=$(NPCFLAGS) IMG=$(IMAGE).bin

sim: insert-arg
	$(MAKE) -C $(NPC_HOME) sim 	ARGS=$(NPCFLAGS) IMG=$(IMAGE).bin

gdb: insert-arg
	$(MAKE) -C $(NPC_HOME) gdb  ARGS=$(NPCFLAGS) IMG=$(IMAGE).bin

valgrind: insert-arg
	$(MAKE) -C $(NPC_HOME) valgrind  ARGS=$(NPCFLAGS) IMG=$(IMAGE).bin

.PHONY: insert-arg