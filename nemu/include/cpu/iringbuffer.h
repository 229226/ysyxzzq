#ifndef IRINGBUFFER__H_
#define IRINGBUFFER__H_

#include <common.h>

typedef struct IRingBuffer
{
    int head;
    int max;
    int length;
    char *text;
}IRingBuffer;


int init_iringbuffer(IRingBuffer *irb,int length);
void iringb_add(IRingBuffer *irb ,char *data);
void iringb_print(IRingBuffer *irb);
void iringb_free(IRingBuffer *irb);
#endif