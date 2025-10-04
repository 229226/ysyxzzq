#include "timer.hpp"
#include "sys/time.h"

static uint64_t start_time = 0;
struct timeval tv;

void init_timer(){
    gettimeofday(&tv, NULL);
    start_time = tv.tv_sec*(1000000ULL) + tv.tv_usec;
}
uint64_t gettime(){
    gettimeofday(&tv, NULL);
    return (tv.tv_sec*(1000000ULL) + tv.tv_usec)-start_time;
}