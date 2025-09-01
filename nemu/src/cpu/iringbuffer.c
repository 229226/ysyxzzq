#include<cpu/iringbuffer.h>

int init_iringbuffer(IRingBuffer *irb,int length){
    irb->head=0;
    irb->max=0;
    irb->length=length;
    irb->text = malloc(128*length*sizeof(char));
    if(irb->text == NULL){
        Log("Failed to malloc for iringbuffer!");
        return -1;
    }
    return 0;
}
void iringb_add(IRingBuffer *irb ,char *data){
    if(irb->head == (irb->length-1)){
        strcpy(irb->text + (128*sizeof(char)*(irb->head)),data);
        irb->head = 0;
        irb->max = 1;
    }else{
        strcpy(irb->text + (128*sizeof(char)*(irb->head)),data);
        irb->head ++;
    }
}
void iringb_print(IRingBuffer *irb){
    if(irb->max == 1) {
        for (int i = irb->head; i < irb->length; i++)
        {
            printf("%s\n",irb->text + (128*sizeof(char)*i));
        }
    }
    for (int i = 0; i < irb->head; i++)
    {
        printf("%s\n",irb->text + (128*sizeof(char)*i));
    }
}
void iringb_free(IRingBuffer *irb){
    free(irb->text);
}