#include <klib.h>
#include <stddef.h>
#include <stdint.h>

__attribute__((section("SSBL"))) void *SSBL_memcpy(void *restrict dst, const void *restrict src, size_t n)
{
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;

    /* 小数据量时直接展开处理，避免函数调用和复杂分支 */
    if (n < 16) {
        if (n >= 8) {
            *(uint64_t *)d = *(const uint64_t *)s;
            d += 8; s += 8; n -= 8;
        }
        if (n >= 4) {
            *(uint32_t *)d = *(const uint32_t *)s;
            d += 4; s += 4; n -= 4;
        }
        if (n >= 2) {
            *(uint16_t *)d = *(const uint16_t *)s;
            d += 2; s += 2; n -= 2;
        }
        if (n) *d = *s;
        return dst;
    }

    /* 将目标地址对齐到机器字边界，提高后续拷贝效率 */
    if ((uintptr_t)d & (sizeof(size_t) - 1)) {
        size_t align = sizeof(size_t) - ((uintptr_t)d & (sizeof(size_t) - 1));
        n -= align;
        do { *d++ = *s++; } while (--align);
    }

    /* 根据源地址是否对齐选择不同的快速路径 */
    if (((uintptr_t)s & (sizeof(size_t) - 1)) == 0) {
        /* 源和目标都对齐：以机器字为单位拷贝，并循环展开4次 */
        size_t *wd = (size_t *)d;
        const size_t *ws = (const size_t *)s;
        size_t words = n / sizeof(size_t);
        n %= sizeof(size_t);

        while (words >= 4) {
            wd[0] = ws[0];
            wd[1] = ws[1];
            wd[2] = ws[2];
            wd[3] = ws[3];
            wd += 4;
            ws += 4;
            words -= 4;
        }
        while (words--)
            *wd++ = *ws++;

        d = (unsigned char *)wd;
        s = (const unsigned char *)ws;
    } else {
        /* 源未对齐但目标对齐：使用两次对齐读取 + 移位拼接的方法 */
        size_t *wd = (size_t *)d;
        const size_t *ws = (const size_t *)((uintptr_t)s & ~(sizeof(size_t) - 1));
        size_t misalign = ((uintptr_t)s & (sizeof(size_t) - 1)) * 8;   /* 偏移位数 */
        size_t t1 = *ws++;         /* 第一个对齐块 */
        size_t words = n / sizeof(size_t);
        n %= sizeof(size_t);

        while (words--) {
            size_t t2 = *ws++;
            *wd++ = (t1 >> misalign) | (t2 << (sizeof(size_t) * 8 - misalign));
            t1 = t2;
        }
        /* 更新字节指针，继续处理剩余字节 */
        d = (unsigned char *)wd;
        s = (const unsigned char *)((uintptr_t)ws - sizeof(size_t) + (misalign / 8));
    }

    /* 处理末尾不足一个机器字的零散字节，同样展开减少分支 */
    if (n >= 4) {
        *(uint32_t *)d = *(const uint32_t *)s;
        d += 4; s += 4; n -= 4;
    }
    if (n >= 2) {
        *(uint16_t *)d = *(const uint16_t *)s;
        d += 2; s += 2; n -= 2;
    }
    if (n) *d = *s;

    return dst;
}

__attribute__((section("FSBL"))) void *FSBL_memcpy(void *restrict dst, const void *restrict src, size_t n)
{
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;

    /* 小数据量时直接展开处理，避免函数调用和复杂分支 */
    if (n < 16) {
        if (n >= 8) {
            *(uint64_t *)d = *(const uint64_t *)s;
            d += 8; s += 8; n -= 8;
        }
        if (n >= 4) {
            *(uint32_t *)d = *(const uint32_t *)s;
            d += 4; s += 4; n -= 4;
        }
        if (n >= 2) {
            *(uint16_t *)d = *(const uint16_t *)s;
            d += 2; s += 2; n -= 2;
        }
        if (n) *d = *s;
        return dst;
    }

    /* 将目标地址对齐到机器字边界，提高后续拷贝效率 */
    if ((uintptr_t)d & (sizeof(size_t) - 1)) {
        size_t align = sizeof(size_t) - ((uintptr_t)d & (sizeof(size_t) - 1));
        n -= align;
        do { *d++ = *s++; } while (--align);
    }

    /* 根据源地址是否对齐选择不同的快速路径 */
    if (((uintptr_t)s & (sizeof(size_t) - 1)) == 0) {
        /* 源和目标都对齐：以机器字为单位拷贝，并循环展开4次 */
        size_t *wd = (size_t *)d;
        const size_t *ws = (const size_t *)s;
        size_t words = n / sizeof(size_t);
        n %= sizeof(size_t);

        while (words >= 4) {
            wd[0] = ws[0];
            wd[1] = ws[1];
            wd[2] = ws[2];
            wd[3] = ws[3];
            wd += 4;
            ws += 4;
            words -= 4;
        }
        while (words--)
            *wd++ = *ws++;

        d = (unsigned char *)wd;
        s = (const unsigned char *)ws;
    } else {
        /* 源未对齐但目标对齐：使用两次对齐读取 + 移位拼接的方法 */
        size_t *wd = (size_t *)d;
        const size_t *ws = (const size_t *)((uintptr_t)s & ~(sizeof(size_t) - 1));
        size_t misalign = ((uintptr_t)s & (sizeof(size_t) - 1)) * 8;   /* 偏移位数 */
        size_t t1 = *ws++;         /* 第一个对齐块 */
        size_t words = n / sizeof(size_t);
        n %= sizeof(size_t);

        while (words--) {
            size_t t2 = *ws++;
            *wd++ = (t1 >> misalign) | (t2 << (sizeof(size_t) * 8 - misalign));
            t1 = t2;
        }
        /* 更新字节指针，继续处理剩余字节 */
        d = (unsigned char *)wd;
        s = (const unsigned char *)((uintptr_t)ws - sizeof(size_t) + (misalign / 8));
    }

    /* 处理末尾不足一个机器字的零散字节，同样展开减少分支 */
    if (n >= 4) {
        *(uint32_t *)d = *(const uint32_t *)s;
        d += 4; s += 4; n -= 4;
    }
    if (n >= 2) {
        *(uint16_t *)d = *(const uint16_t *)s;
        d += 2; s += 2; n -= 2;
    }
    if (n) *d = *s;

    return dst;
}

extern char _text_LMA,_text_sVMA,_text_eVMA;
extern char _data_LMA,_data_sVMA,_data_eVMA;
//用于RT-Thread
extern char _data_extra_LMA,_data_extra_sVMA,_data_extra_eVMA;

__attribute__((section("SSBL"))) void _SSBL(){
    SSBL_memcpy(&_text_sVMA,&_text_LMA,&_text_eVMA - &_text_sVMA);
    SSBL_memcpy(&_data_sVMA,&_data_LMA,&_data_eVMA - &_data_sVMA);
    //用于RT-Thread
    SSBL_memcpy(&_data_extra_sVMA,&_data_extra_LMA,&_data_extra_eVMA - &_data_extra_sVMA);
}

extern char _SSBL_LMA,_SSBL_sVMA,_SSBL_eVMA;

__attribute__((section("FSBL"))) void _FSBL(){
    FSBL_memcpy(&_SSBL_sVMA,&_SSBL_LMA,&_SSBL_eVMA - &_SSBL_sVMA);
}