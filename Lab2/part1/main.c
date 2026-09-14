#include <stdio.h>

extern int test(int a, int b);

int main(void)
{
    int result = test(3, 5);
    printf("Result of test(3, 5) = %d\n", result);
    return 0;
}
