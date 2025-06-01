/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>
#include <stdbool.h>
#include <regex.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

static int index_buf = 0;
static char op[4] = {'+','-','*','/'};

static int inc_index(int n){
  if((index_buf + n)>(65536-2)){
    printf("Reach the maximum of the buf in gen-expr\n");
    return 1;
  }else{
    index_buf += n;
  }
  return 0;
}
static int choose(int n){
  return rand()%n;
}
static int gen_num(){
  uint32_t num = (uint32_t)rand();
  char str[20];
  sprintf(str,"%d",num);
  int length = strlen(str);
  strcpy(buf+index_buf,str);
  if(inc_index(length)){
    return 1;
  }
  return 0;
}
static int gen(char ch){
  buf[index_buf] = ch;
  if(inc_index(1)) return 1;
  return 0;
}
static int gen_rand_op(){
  buf[index_buf] = op[choose(4)];
  if(inc_index(1)) return 1;
  return 0;
}
static int gen_rand_expr() {
  switch (choose(6)) {
    case 0: {
      if(gen_num()) return 1; 
      break;
    }
    case 1: {
      if(gen('(')) return 1;
      if(gen_rand_expr()) return 1;
      if(gen(')')) return 1;
      break;
    }
    case 2: {
      if(gen_rand_expr()) return 1;
      if(gen(' ')) return 1;
      break;
    }
    case 3: {
      if(gen(' ')) return 1;
      if(gen_rand_expr()) return 1;
      break;
    }
    case 4:{
      if(gen('(')) return 1;
      if(gen('-')) return 1;
      if(gen_rand_expr()) return 1;
      if(gen(')')) return 1;
      break;
    }
    default:{
      if(gen_rand_expr()) return 1;
      if(gen_rand_op()) return 1;
      if(gen_rand_expr()) return 1;
      break;
    }
  }
  buf[index_buf+1] = '\0';
  return 0;
}
static int is_divied_zero(bool *y_or_n){
  regex_t regex;
  int ret;
  
  ret = regcomp(&regex,".*/[ ()]*[0]+[^0-9]*",REG_EXTENDED);
  if (ret) {
    printf("无法编译正则表达式\n");
    return 1;
  }
  ret = regexec(&regex,buf,0,NULL,0);
  if (!ret){
    *y_or_n = true;
  }else{
    *y_or_n = false;
  }
  regfree(&regex);
  return 0;
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    index_buf = 0;
    if(gen_rand_expr()){
      continue;
    }
    
    bool y_or_n;
    if(is_divied_zero(&y_or_n)){
      return 1;
    }else{
      if(y_or_n){
        continue;
      }
    }
    
    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
}
