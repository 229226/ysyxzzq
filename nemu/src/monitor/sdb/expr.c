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
#include <memory/paddr.h>
/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum
{
  TK_NOTYPE = 256,

  /* TODO: Add more token types */
  TK_REG,
  TK_NUMB_HEX,
  TK_NUMB_DEC,

  TK_AND,
  TK_EQ,
  TK_NEQ,
  TK_PLUS,
  TK_SUB,
  TK_MUL,
  TK_DIV,
  TK_DERE,
  TK_NEG,
  TK_LBRA,
  TK_RBRA,
};

static struct rule
{
  const char *regex;
  int token_type;
} rules[] = {

    /* TODO: Add more rules.
     * Pay attention to the precedence level of different rules.
     */
    {" +", TK_NOTYPE},            // spaces
    {"\\$[0-9a-zA-Z]+", TK_REG},          // reg_name
    {"0[xX][0-9]+", TK_NUMB_HEX}, // hexadecimal numbers
    {"[0-9]+", TK_NUMB_DEC},      // decimal numbers

    {"&&", TK_AND},   // logical and
    {"==", TK_EQ},    // equal
    {"!=", TK_NEQ},   // not equal
    {"\\+", TK_PLUS}, // plus
    {"-", TK_SUB},    // subtract
    {"\\*", TK_MUL},  // multiply or dereference
    {"/", TK_DIV},    // divide
    {"\\(", TK_LBRA}, // left bracket
    {"\\)", TK_RBRA}, // right bracket
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex()
{
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i++)
  {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0)
    {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token
{
  int type;
  char str[32];
} Token;

#define MAX_TOKENS 65536
static Token tokens[MAX_TOKENS] __attribute__((used)) = {};
static int nr_token __attribute__((used)) = 0;

static void inc_nr_token(bool *success)
{
  if (nr_token == MAX_TOKENS)
  {
    printf("Reach The max of tokens\n");
    return;
  }
  else
  {
    nr_token++;
    return;
  }
}
static bool make_token(char *e, bool *success)
{
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0')
  {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i++)
    {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0)
      {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
        //     i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type)
        {
        case TK_NOTYPE:
          break;

        case TK_REG:
        case TK_NUMB_HEX:
        case TK_NUMB_DEC:
        {
          if (substr_len < 32)
          {
            tokens[nr_token].type = rules[i].token_type;
            strncpy(tokens[nr_token].str, substr_start, substr_len);
            tokens[nr_token].str[substr_len] = '\0';
            inc_nr_token(success);
            if (!(*success))
              return false;
          }
          else
          {
            printf("The string can't longer than 31byte.\n");
            return false;
          }
          break;
        }

        case TK_AND:
        case TK_EQ:
        case TK_NEQ:
        case TK_PLUS:
        case TK_SUB:
        case TK_MUL:
        case TK_DIV:
        case TK_RBRA:
        case TK_LBRA:
        {
          tokens[nr_token].type = rules[i].token_type;
          inc_nr_token(success);
          if (!(*success))
            return false;
          break;
        }
        default:
          break;
        }
        break;
      }
    }
    if (i == NR_REGEX)
    {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }
  nr_token--;
  return true;
}

static bool check_parentheses(int p, int q)
{
  int par_unmatched = 0;
  if (tokens[p].type != TK_LBRA)
    return false;

  for (int i = p; i <= q; i++)
  {
    if (tokens[i].type == TK_LBRA)
    {
      par_unmatched++;
    }
    else if (tokens[i].type == TK_RBRA)
    {
      par_unmatched--;
      if (par_unmatched == 0)
      {
        if (i == q)
          return true;
        else
          return false;
      }
    }
    else
    {
      continue;
    }
  }
  return false;
}

static int find_top(int p, int q, bool *success)
{
  int top = -1;
  int par_unmatched = 0;
  for (int i = p; i <= q; i++)
  {
    if (tokens[i].type == TK_LBRA)
    {
      par_unmatched++;
      continue;
    }
    else if (tokens[i].type == TK_RBRA)
    {
      par_unmatched--;
      continue;
    }
    else if ((par_unmatched == 0) && (tokens[i].type > TK_NUMB_DEC))
    {
      if (top == -1)
      {
        top = i;
      }
      else if (tokens[i].type <= tokens[top].type)
      {
        top = i;
      }
    }
  }
  if (top != -1)
  {
    return top;
  }
  else
  {
    printf("Failed to find the top\n from p = %d,TK = %d,str = %s\n to q = %d,TK = %d,str = %s\n"
      ,p,tokens[p].type,tokens[p].str,q,tokens[q].type,tokens[q].str);
    *success = false;
    return -1;
  }
}

static uint32_t eval_expr(int p, int q, bool *success)
{
  if (p > q)
  {
    *success = false;
    return 0;
  }
  else if (p == q)
  {
    switch (tokens[p].type)
    {
    case TK_REG:{
      return isa_reg_str2val(tokens[p].str,success);
    }
    case TK_NUMB_HEX:
    {
      uint32_t num;
      if(sscanf(tokens[p].str,"%x",&num)==1){
        return num;
      }else{
        printf("Failed to transform the hex numbers to uint32_t\n");
        *success = false;
        return 0;
      }
    }
    case TK_NUMB_DEC:
    {
      uint32_t num;
      if(sscanf(tokens[p].str,"%d",&num)==1){
        return num;
      }else{
        printf("Failed to transform the decimal numbers to uint32_t\n");
        *success = false;
        return 0;
      }
    }
    default:
    {
      *success = false;
      return 0;
    }
    }
  }
  else if (check_parentheses(p, q) == true)
  {
    uint32_t ret = eval_expr(p + 1, q - 1, success);
    if (!(*success))
    {
      return 0;
    }
    else
      return ret;
  }
  else
  {
    int top = find_top(p, q, success);
    if (!(*success))
      return 0;
    if (top == p)
    {
      uint32_t val = eval_expr(top+1,q,success);
      if (!(*success))
      return 0;
      switch (tokens[top].type)
      {
      case TK_RBRA:
        return (uint32_t)paddr_read(val,4);
      case TK_NEG:
        return (uint32_t)-val;
      default:
        break;
      }
    }
    
    uint32_t val1 = eval_expr(p, top - 1, success);
    if (!(*success))
      return 0;
    uint32_t val2 = eval_expr(top + 1, q, success);
    if (!(*success))
      return 0;

    switch (tokens[top].type)
    {
    case TK_AND:
    {
      return (val1 && val2);
    }
    case TK_EQ:
    {
      return (val1 == val2);
    }
    case TK_NEQ:
    {
      return (val1 != val2);
    }
    case TK_PLUS:
    {
      return val1 + val2;
    }
    case TK_SUB:
    {
      return val1 - val2;
    }
    case TK_MUL:
    {
      return val1 * val2;
    }
    case TK_DIV:
    {
      if (val2 == 0)
      {
        printf("The divisor can't be zero\n");
        *success = false;
        return 0;
      }
      else
      {
        return (uint32_t)(val1 / val2);
      }
    }
    default:
    {
      *success = false;
      return 0;
    }
    }
  }
  return 0;
}
static void make_pretoken(bool *success){
  int i;
  for (i = 0; i < nr_token; i ++) {
    if (tokens[i].type == TK_MUL && (i == 0 || ((tokens[i - 1].type>TK_NUMB_DEC)&&(tokens[i-1].type != TK_RBRA))) ) {
      tokens[i].type = TK_DERE;
    }
    if (tokens[i].type == TK_SUB && (i == 0 || ((tokens[i - 1].type>TK_NUMB_DEC)&&(tokens[i-1].type != TK_RBRA))) ) {
      tokens[i].type = TK_NEG;
    }
  }
}
word_t expr(char *e, bool *success)
{
  make_token(e, success);
  if (!(*success))
    return 0;

  make_pretoken(success);

  /* TODO: Insert codes to evaluate the expression. */
  word_t ret = eval_expr(0, nr_token, success);
  if (*success)
    return ret;
  else
    return 0;
}
