ENTRY(_start)

MEMORY {
    flash   (rx)    : ORIGIN = 0x30000000,  LENGTH = 16M
    mrom    (rx)    : ORIGIN = 0x20000000,  LENGTH = 4K
    sdram   (rwx)   : ORIGIN = 0xa0000000,  LENGTH = 32M
    psram   (rwx)   : ORIGIN = 0x80000000,  LENGTH = 4M
    sram    (rwx)   : ORIGIN = 0x0f000000,  LENGTH = 8K
}

SECTIONS {
    . = ORIGIN(flash);

    .start :{
        *(entry)
        *(FSBL)
        . = ALIGN(8);
    } > flash

    .SSBL :{
        _SSBL_sVMA = .;
        *(SSBL)
        . = ALIGN(8);
        _SSBL_eVMA = .;
    } > sdram AT> flash

    _SSBL_LMA = LOADADDR(.SSBL);

    .text :{
        _text_sVMA = .;
        *(.text*)
        *(.rodata*)
        . = ALIGN(8);
        _text_eVMA = .;
    } > sdram AT> flash

    _text_LMA = LOADADDR(.text);

    .data :{
        _data_sVMA = .;
        *(.data*)
        *(.sdata*)
        . = ALIGN(8);
        _data_eVMA = .;
    } > sdram AT> flash

    _data_LMA = LOADADDR(.data);

    .bss :{
        *(.bss*)
        *(.sbss*)
        *(.scommon)
        . = ALIGN(8);
    } > sdram

    _heap_start = .;
    _heap_end = ORIGIN(sdram) + LENGTH(sdram);

    _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
