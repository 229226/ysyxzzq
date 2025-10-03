#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define print_model(w_byte,w_s,w_d,w_x,w_0) \
  int len_out = 0;\
  int len_fmt = 0;\
  va_list args;\
  va_start(args, fmt);\
  while (fmt[len_fmt] != '\0')\
  {\
    if(fmt[len_fmt] != '%'){\
      w_byte\
      len_out++;\
      len_fmt++;\
    }else{\
      char *str = NULL;\
      int str_len = 0;\
      int num_int = 0;\
      char str_num[12];\
      switch (fmt[len_fmt+1])\
      {\
      case 's':\
        str = va_arg(args,char *);\
        str_len = strlen(str);\
        w_s\
        len_out += str_len;\
        len_fmt += 2;\
        break;\
      case 'd':\
        num_int = va_arg(args,int);\
        str_len = int2string(num_int,str_num);\
        w_d\
        len_out += str_len;\
        len_fmt += 2;\
        break;\
      case 'x':\
        num_int = va_arg(args,int);\
        str_len = strlen(str_num);\
        w_x\
        len_out += str_len;\
        len_fmt += 2;\
        break;\
      default:\
        return -1;\
        break;\
      }\
    }\
  }\
  w_0\
  va_end(args);\
  return len_out;\


int int2string(int num_int,char *str);

int printf(const char *fmt, ...) {
  print_model(
    putch(fmt[len_fmt]);
    ,
    for (int i = 0; i < str_len; i++)
    {
      putch(str[i]);
    }
    ,
    for (int i = 0; i < str_len; i++)
    {
      putch(str_num[i]);
    }
    ,
    for (int i = 0; i < str_len; i++)
    {
      putch(str_num[i]);
    }
    ,
  )
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  print_model(
    out[len_out] = fmt[len_fmt];
    ,
    strcpy(out+len_out,str);
    ,
    strcpy(out+len_out,str_num);
    ,

    ,
    out[len_out] = '\0';
  )
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int int2string(int num_int,char *str){
  int str_len = 0; 
  int my_num_int;

  int is_neg = 0;

  if (num_int == 0x80000000)
  {
    strcpy(str,"-2147483648");
    return 11;
  }else if(num_int < 0){
    my_num_int = -num_int;
    is_neg = 1;
  }else if (num_int == 0)
  {
    str[str_len] = '0';
    str_len++;
    str[str_len] = '\0';
    return str_len;
  }else{
    my_num_int = num_int;
  }
  
  while (my_num_int > 0)
  {
    str[str_len] = '0' + (my_num_int % 10);
    str_len++;
    my_num_int /= 10;
  }

  if(is_neg){
    str[str_len] = '-';
    str_len++;
  }

  int start = 0;
  int end = str_len-1;
  char tmp;
  while(start<end){
    tmp = str[end];
    str[end] = str[start];
    str[start] = tmp;
    start++;
    end--;
  }

  str[str_len] = '\0';

  return str_len;
}
int hex2string(int num_int,char *str){
  return 0;
}
#endif
