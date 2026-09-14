#include <stdio.h>

extern long long int test();
extern void Lab02_3b(void);
extern long long int* lab02_3d(long long int val);

int main(void)
{
    test();

    Lab02_3b();

    long long int input_val = 0x100;
    long long int *ptr = lab02_3d(input_val);
    printf("Value at myvalue address (%p): 0x%llx\n", (void*)ptr, *ptr);

    return 0;
}
