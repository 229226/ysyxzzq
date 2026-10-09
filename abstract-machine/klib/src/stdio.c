#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
int printf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    va_list ap_len;
    va_copy(ap_len, ap);
    int len = vsnprintf(NULL, 0, fmt, ap_len);
    va_end(ap_len);

    char buf[len + 1];

    vsnprintf(buf, len + 1, fmt, ap);
    va_end(ap);

    for (int i = 0; i < len; ++i) {
        putch(buf[i]);
    }

    return len;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  return vsnprintf(out, (size_t)-1, fmt, ap);
}

int sprintf(char *out, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int ret = vsprintf(out, fmt, ap);
    va_end(ap);
    return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int ret = vsnprintf(out, n, fmt, ap);
    va_end(ap);
    return ret;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
    if (n == 0) {
        char dummy;
        return vsnprintf(&dummy, 1, fmt, ap);
    }

    char *p = out;
    size_t rem = n - 1; // 为 '\0' 保留一个位置；rem 不用指针减法，避免 n=(size_t)-1 时回绕
    int total = 0;

    while (*fmt) {
        if (*fmt != '%') {
            if (rem) { *p++ = *fmt; rem--; }
            total++;
            fmt++;
            continue;
        }

        fmt++; // 跳过 '%'
        if (*fmt == '\0') break;

        switch (*fmt) {
        case '%':
            if (rem) { *p++ = '%'; rem--; }
            total++;
            break;
        case 'c': {
            char c = (char)va_arg(ap, int);
            if (rem) { *p++ = c; rem--; }
            total++;
            break;
        }
        case 's': {
            const char *s = va_arg(ap, const char *);
            if (s == NULL) s = "(null)";
            while (*s) {
                if (rem) { *p++ = *s; rem--; }
                total++;
                s++;
            }
            break;
        }
        case 'd': {
            int num = va_arg(ap, int);
            // 处理负数
            if (num < 0) {
                if (rem) { *p++ = '-'; rem--; }
                num = -num;
                total++;
            }

            char tmp[12];
            char *t = tmp + sizeof(tmp) - 1;
            *t = '\0';
            if (num == 0) {
                *--t = '0';
            } else {
                while (num > 0) {
                    *--t = '0' + (num % 10);
                    num /= 10;
                }
            }
            // 写入输出缓冲区
            while (*t) {
                if (rem) { *p++ = *t; rem--; }
                total++;
                t++;
            }
            break;
        }
        case 'x': {
            unsigned int num = va_arg(ap, unsigned int);
            char tmp[9];
            char *t = tmp + sizeof(tmp) - 1;
            *t = '\0';
            if (num == 0) {
                *--t = '0';
            } else {
                while (num > 0) {
                    int digit = num & 0xF;
                    *--t = (digit < 10) ? ('0' + digit) : ('a' + digit - 10);
                    num >>= 4;
                }
            }
            while (*t) {
                if (rem) { *p++ = *t; rem--; }
                total++;
                t++;
            }
            break;
        }
        default:
            // 不支持的格式，直接输出
            if (rem) { *p++ = *fmt; rem--; }
            total++;
            break;
        }
        fmt++;
    }

    *p = '\0';
    return total;
}
#endif
