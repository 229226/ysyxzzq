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

#include <common.h>
#include <monitor/sdb.h>

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();
int test_expr(){
  FILE *file = fopen("/home/zzq/ysyx-workbench/nemu/tools/gen-expr/input","r");
  if(file == NULL){
    printf("Can't open the file input\n");
    assert(0);
    return 1;
  }

  char buffer[70000];
  uint32_t result;
  char e[65536];
  bool success = true;
  uint32_t ret;

  int count = 1;
  int falsecount = 0;

  while(fgets(buffer,70000,file) != NULL){
    success = true;
    sscanf(buffer,"%u %[^\n]",&result,e);
    ret = expr(e,&success);
    //printf("%3d: ",count);
    if (!success){
      printf("%5d:  Fail to calculate the expression by expr()\n",count);
      falsecount++;
    }else{
      if(result == ret){
        //printf(" true  ");
      }else{
        printf("%5d: false %u %u\n",count,result,ret);
        falsecount++;
      }
      //printf("%u %u\n" ,result,ret);
    }
    count++;
  }
  printf("Total: %d False: %d\n",count-1,falsecount);

  fclose(file);
  return 0;
}


int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif

  /* Start engine. */
  engine_start();

  test_expr();

  return is_exit_status_bad();
}
