#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  if(s == NULL) return 0;
  size_t length = 0;
  while (s[length] != '\0')
  {
    length++;
  }
  return length;
}

char *strcpy(char *dst, const char *src) {
  int length = 0;
  while (src[length] != '\0')
  {
    dst[length] = src[length]; 
    length++;
  }

  dst[length] = '\0';

  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  panic("strncpy Not implemented");
}

char *strcat(char *dst, const char *src) {
  int dst_length = strlen(dst);
  int src_length = 0;
  while (src[src_length] != '\0')
  {
    dst[dst_length+src_length] = src[src_length];
    src_length++;
  }
  dst[dst_length+src_length] = '\0';
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  int length = 0;
  do
  {
    if(s1[length] != s2[length]){
      return s1[length] - s2[length];
    }
    length++;
  }while ((s1[length] != '\0') && (s2[length] != '\0'));
  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  if(n == 0) return 0;
  assert(s1 != NULL);
  assert(s2 != NULL);

  int i = 0;
  while (i < n && s1[i] != '\0' && s2[i] != '\0')
  {
    if(s1[i] != s2[i]){
      return (int)s1[i] - s2[i];
    }
    i++;
  }
  
  if(i == n-1){
    return 0;
  }

  return (int)s1[i] - s2[i];
}

void *memset(void *s, int c, size_t n) {
  if(s == NULL) return NULL;
  for (size_t i = 0; i < n; i++)
  {
    ((char *)s)[i] = (unsigned char)c;
  }
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  if((dst == NULL)||src == NULL) return NULL;

  for (size_t i = 0; i < n; i++)
  {
    ((char*)dst)[i] = ((char*)src)[i];
  }
  
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {

  for (size_t i = 0; i < n; i++)
  {
    ((char *)out)[i] = ((char *)in)[i];
  }
  
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  for (size_t i = 0; i < n; i++)
  {
    if(((char *)s1)[i] != ((char *)s2)[i]){
      return ((char *)s1)[i] - ((char *)s2)[i];
    }
  }
  return 0;
}

#endif
