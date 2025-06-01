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

#include <monitor/sdb.h>

#define NR_WP 32
#define WT_WT_MAX 256

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  char what[WT_WT_MAX];
  uint32_t last_val;
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
static WP* pnew_wp(char *wt){
  assert(wt != NULL);
  if(free_ == NULL){
    printf("Don't have enough space to creat a new watchpoint\n");
    return NULL;
  }else{
    WP *tmp = free_;
    free_ = free_->next;
    tmp->next = head;
    head = tmp;
    if(strlen(wt) > (WT_WT_MAX-1)){
      printf("Reach the maximum of what in watchpoint\n");
    }else{
      strcpy(tmp->what,wt);
    }
    return tmp;
  }
}
bool free_wp(int N){
  if(head->NO == N){
    WP* tmp = head;
    head = head->next;
    tmp->next = free_;
    free_ = tmp;
    return true;
  }else{
    WP* tmp_pre = head;
    WP* tmp;
    while (tmp_pre->next != NULL)
    {
      if(tmp_pre->next->NO == N){
        tmp = tmp_pre->next;
        tmp_pre->next = tmp->next;
        tmp->next = free_;
        free_ = tmp;
        return true;
      }else{
        tmp_pre = tmp_pre->next;
      }
    }
    printf("Can't find the watchpoint in array\n");
    return false;
  }
}
// static bool pfree_wp(WP *wp){
//   WP* tmp;
//   if(wp == head){
//     tmp = head;
//     head = head->next;
//     tmp->next = free_;
//     free_ = tmp;
//     return true;
//   }else{
//     tmp = head;
//     while (tmp->next != NULL)
//     {
//       if(tmp->next == wp){
//         tmp->next = wp->next;
//         wp->next = free_;
//         free_ = wp;
//         return true;
//       }else{
//         tmp = tmp->next;
//       }
//     }
//     printf("Can't find the watchpoint in array\n");
//     return false;
//   }
// }
void print_wp(){
  printf("%-10s%s\n","Num","What");
  WP *tmp = head;
  while (tmp != NULL)
  {
    printf("%-10d%s\n",tmp->NO,tmp->what);
    tmp = tmp->next;
  }
}
bool new_wp(char *wt){
  assert(wt != NULL);
  WP *new_wp = pnew_wp(wt);
  if(new_wp == NULL){
    return false;
  }else{
    return true;
  }
}
bool is_wp_diff(){
  WP *tmp = head;
  bool success;
  uint32_t result;
  bool changed = false;
  while (tmp != NULL)
  {
    result = expr(tmp->what,&success);
    if(!success){
      printf("Failed to refresh the value of watchpoint %d",tmp->NO);
    }else{
      if(result != tmp->last_val){
        if(changed == false){
          printf("%-10s%-16s%-16s%s\n","Num","Lastvalue","New value","What");
        }
        printf("%-10d%-16u%-16u%s\n",tmp->NO,tmp->last_val,result,tmp->what);
        changed = true;
        tmp->last_val = result;
      }
    }
    tmp = tmp->next;
  }
  return changed;
}