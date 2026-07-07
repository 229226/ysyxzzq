ENTRY(_start)

MEMORY {
    mrom    (rx)    : ORIGIN = 0x20000000,  LENGTH = 4K
    flash   (rx)    : ORIGIN = 0x30000000,  LENGTH = 16M
    sram    (rwx)   : ORIGIN = 0x0f000000,  LENGTH = 8K
    psram   (rwx)   : ORIGIN = 0x80000000,  LENGTH = 4M
}

SECTIONS {
    . = ORIGIN(flash);

    .start :{
        *(entry)
        *(bootloader)
    } > flash

    .text :{
        _sladdr = .;
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > sram AT> flash

    _loadaddr = LOADADDR(.text);

    .data :{
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
        _eladdr = .;
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
