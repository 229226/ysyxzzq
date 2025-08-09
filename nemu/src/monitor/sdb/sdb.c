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

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <monitor/sdb.h>
#include <utils.h>
#include <memory/paddr.h>

#include <errno.h>
#include <limits.h>

bool parse_unsigned_long(const char *str, unsigned long *out) {
  char *endptr;
  errno = 0;
  unsigned long num = strtoul(str, &endptr, 0);

  // 检查转换是否失败（无有效数字）
  if (str == endptr) {
      printf("Error: No digits found!\n");
      return false;
  }

  // 检查是否有无效字符（如 "123a"）
  if (*endptr != '\0') {
      printf("Error: Extra characters after number: '%s'\n", endptr);
      return false;
  }

  // 检查是否超出 unsigned long 范围（ULONG_MAX）
  if (errno == ERANGE || num == ULONG_MAX) {
      printf("Error: Number exceeds ULONG_MAX (%lu)!\n", ULONG_MAX);
      return false;
  }

  *out = num;
  return true;
}

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char *rl_gets()
{
  static char *line_read = NULL;

  if (line_read)
  {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read)
  {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args)
{
  cpu_exec(-1);
  return 0;
}
static int cmd_q(char *args)
{
  //nemu_state.state = NEMU_QUIT;
  return -1;
}
static int cmd_help(char *args);
static int cmd_si(char *args);
static int cmd_info(char *args);
static int cmd_x(char *args);
static int cmd_w(char *args);
static int cmd_p(char *args);
static int cmd_d(char *args);

static struct
{
  const char *name;
  const char *description;
  int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit NEMU", cmd_q},
    {"si", "Execute N instructions,the default of N is 1", cmd_si},
    {"info", "Dispaly the value of regs or the information of watches by args r/w", cmd_info},
    {"x", "Scan N*4byte memory",cmd_x},
    /* TODO: Add more commands */
    {"w", "Add watchpoint",cmd_w},
    {"p", "Calculate the expresion what you input",cmd_p},
    {"d", "Delete the watchpoint of the number N",cmd_d}
};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args)
{
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL)
  {
    /* no argument given */
    for (i = 0; i < NR_CMD; i++)
    {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else
  {
    for (i = 0; i < NR_CMD; i++)
    {
      if (strcmp(arg, cmd_table[i].name) == 0)
      {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

static int cmd_si(char *args)
{
  char *arg = strtok(NULL, " ");
  uint64_t num = 0;

  if(arg != NULL){
      parse_unsigned_long(arg,&num);
  }else{
    num = 1;
  }

  if (num != 0){
    cpu_exec(num);
  }else{
    printf("Wrong args input of \"si\"\n");
  }

  return 0;
}

static int cmd_info(char *args){
  char *arg = strtok(NULL, " ");

  if(arg == NULL){
    printf("Need a arg(r/w) for info\n");
  }
  else if(strcmp(arg,"r") == 0){
    isa_reg_display();
  }
  else if(strcmp(arg,"w") == 0){
    print_wp();
  }
  else{
    printf("Wrong arg of the command info\n");
  }

  return 0;
}

static int cmd_x(char *args){
  char *args_end = args + strlen(args);
  char *arg = strtok(NULL, " ");
  char *expr_str = args + strlen(arg)+1;
  if(expr_str >= args_end){
    printf("Don't have enough args\n");
    return 1;
  }

  uint64_t num = 0;
  bool matched = parse_unsigned_long(arg,&num);

  if(matched){
    if(num == 0){
      printf("The number should be greater than zero\n");
    }else{
      bool success = true;
      uint32_t exp_rs = expr(expr_str,&success);
      if(success){
        for(uint32_t i = 0;i<num;i++){
          paddr_t addr = exp_rs + 4*i;
          printf("0x%x 0x%08x\n",addr,paddr_read(addr,4));
        }
      }else{
        printf("Wrong expression or address\n");
      }
    }
  }

  return 0;
}

static int cmd_w(char *args){
  if(new_wp(args)){
    return 0;
  }else{
    return 1;
  }
}

static int cmd_p(char *args){
  bool success;
  uint32_t ret = expr(args,&success);
  if(success){
    printf("%s =\n%u\n",args,ret);
    return 0;
  }else{
    printf("Failed to caculate the expression\n");
    return 1;
  }
}

static int cmd_d(char *args){
  char *arg = strtok(NULL, " "); 
  int N;
  sscanf(arg,"%d",&N);
  if(free_wp(N)){
    return 0;
  }else{
    return 1;
  }
}

void sdb_set_batch_mode()
{
  is_batch_mode = true;
}

void sdb_mainloop()
{
  if (is_batch_mode)
  {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL;)
  {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL)
    {
      continue;
    }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end)
    {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i++)
    {
      if (strcmp(cmd, cmd_table[i].name) == 0)
      {
        if (cmd_table[i].handler(args) < 0)
        {
          return;
        }
        break;
      }
    }

    if (i == NR_CMD)
    {
      printf("Unknown command '%s'\n", cmd);
    }
  }
}

void init_sdb()
{
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
