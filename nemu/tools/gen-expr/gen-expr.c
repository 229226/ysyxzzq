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
static char *op[15] = {"||","&&","|","^","&","==","!=",">",">="
  ,"<","<=","+","-","*","/"};

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
  char str[21];
  sprintf(str,"%du",num);
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
  char *op_pointer = op[choose(15)];
  int op_length = strlen(op_pointer);
  strcpy(buf+index_buf,op_pointer);
  if(inc_index(op_length)){
  }else{
    strcpy(buf+index_buf,"(unsigned int)");
    int length = strlen("(unsigned int)");
    if(inc_index(length)) return 1;
  }
  return 0;
}
static int gen_rand_expr(int depth) {
  if (depth == 1)
  {
    if(gen_num()) return 1;
  }else{
  //return 1表示程序运行出错，0表示正常
  switch (choose(6)) {
    case 0: {
      if(gen_num()) return 1; 
      break;
    }
    case 1: {
      if(gen('(')) return 1;
      if(gen_rand_expr(depth-1)) return 1;
      if(gen(')')) return 1;
      break;
    }
    case 2: {
      if(gen_rand_expr(depth-1)) return 1;
      if(gen(' ')) return 1;
      break;
    }
    case 3: {
      if(gen(' ')) return 1;
      if(gen_rand_expr(depth-1)) return 1;
      break;
    }
    case 4:{
      if(gen('-')) return 1;
      if(gen('(')) return 1;
      if(gen_rand_expr(depth-1)) return 1;
      if(gen(')')) return 1;
      break;
    }
    default:{
      if(gen_rand_expr(depth-1)) return 1;
      if(gen_rand_op()) return 1;
      if(gen_rand_expr(depth-1)) return 1;
      break;
    }
  }
}
  buf[index_buf+1] = '\0';
  return 0;
}
static void replace_u(char *data,int length){
  for(int i = 0;i<length;i++){
    if((data[i]>='a')&&(data[i]<='z')){
      if (data[i]=='n')
      {
        data[i-2]=' ';
      }
      if (data[i]=='t')
      {
        data[i+1]=' ';
      }
      data[i]=' ';
    }    
  }
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int count = 0;
  while(count < loop){
    index_buf = 0;
    if(gen_rand_expr(100)){
      continue;
    }
    
    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    //启用-Werror=div-by-zero来过滤有除0行为的表达式
    int ret = system("gcc -Werror=div-by-zero /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    //使用popen执行了指令并返回一个*FILE
    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    //再使用fscanf读取*FILE的内容
    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    replace_u(buf,strlen(buf));

    printf("%u %s\n", result, buf);
    count++;
  }
}
