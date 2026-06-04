GCC = riscv64-linux-gnu-gcc
GCC_FLAGS = -nostartfiles -static -march=rv32e_zicsr -mabi=ilp32e
GCC_FLAGS += -Wl,-Ttext=0x20000000

OBJCOPY = riscv64-linux-gnu-objcopy
OBJCOPY_FLAGS = -O binary -j .text

OBJDUMP = riscv64-linux-gnu-objdump
OBJDUMP_FLAGS = -d

all: char-test.bin char-test.txt

char-test.elf:	char-test.c
	$(GCC) $(GCC_FLAGS) char-test.c -o char-test.elf

char-test.bin:	char-test.elf
	$(OBJCOPY) $(OBJCOPY_FLAGS) char-test.elf char-test.bin

char-test.txt:	char-test.elf
	$(OBJDUMP) $(OBJDUMP_FLAGS) char-test.elf > char-test.txt

clean:
	rm ./char-test.elf ./char-test.bin ./char-test.txt

.PHONY: all clean