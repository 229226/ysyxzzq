ENTRY(_start)

MEMORY {
  mrom (rx)   : ORIGIN = 0x20000000, LENGTH = 4K
  flash (rx)  : ORIGIN = 0x30000000, LENGTH = 256M
  sram (rwx)  : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(flash);

  .text :{
    *(entry)
    *(.text*)
    *(.rodata*)
    . = ALIGN(4);
  } > flash

  _data_loadaddr = LOADADDR(.data);

  .data :{
    _sdata = .;
    *(.data*)
    *(.sdata*)
    . = ALIGN(4);
    _edata = .;
  } > sram AT> flash

  .bss :{
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    . = ALIGN(4);
  } > sram

  _heap_start = .;
  _heap_end = _stack_pointer - 0x1000;

  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
