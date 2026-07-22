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
    char *end = out + n - 1; // 为 '\0' 保留一个位置
    int total = 0;

    while (*fmt && p < end) {
        if (*fmt != '%') {
            *p++ = *fmt++;
            total++;
            continue;
        }

        fmt++; // 跳过 '%'
        if (*fmt == '\0') break;

        switch (*fmt) {
        case '%':
            *p++ = '%';
            total++;
            break;
        case 'c': {
            char c = (char)va_arg(ap, int);
            *p++ = c;
            total++;
            break;
        }
        case 's': {
            const char *s = va_arg(ap, const char *);
            if (s == NULL) s = "(null)";
            while (*s && p < end) {
                *p++ = *s++;
                total++;
            }
            // 计算剩余未写入的字符数
            while (*s++) total++;
            break;
        }
        case 'd': {
            int num = va_arg(ap, int);
            // 处理负数
            if (num < 0) {
                if (p < end) *p++ = '-';
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
            while (*t && p < end) {
                *p++ = *t++;
                total++;
            }
            // 计算剩余
            while (*t++) total++; 
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
            while (*t && p < end) {
                *p++ = *t++;
                total++;
            }
            while (*t++) total++;
            break;
        }
        default:
            // 不支持的格式，直接输出
            if (p < end) *p++ = *fmt;
            total++;
            break;
        }
        fmt++;
    }

    while (*fmt) {
        if (*fmt != '%') {
            total++;
            fmt++;
            continue;
        }
        fmt++; // 跳过 %
        if (*fmt == '\0') break;
        switch (*fmt) {
        case '%': case 'c':
            total++; break;
        case 's': {
            const char *s = va_arg(ap, const char *);
            if (!s) s = "(null)";
            while (*s++) total++;
            break;
        }
        case 'd': {
            int num = va_arg(ap, int);
            if (num < 0) { total++; num = -num; }
            if (num == 0) total++;
            else while (num > 0) { total++; num /= 10; }
            break;
        }
        case 'x': {
            unsigned int num = va_arg(ap, unsigned int);
            if (num == 0) total++;
            else while (num > 0) { total++; num >>= 4; }
            break;
        }
        default: total++; break;
        }
        fmt++;
    }

    *p = '\0';
    return total;
}
#endif
