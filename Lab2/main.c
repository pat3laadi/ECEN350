#include <stdio.h>

// this tells C that "lab02_3d" exists somewhere else (in the .S file)
// it takes one number in, and gives back a pointer (an address)
extern long long int* lab02_3d(long long int val);

int main() {
    long long int input_val = 0x100;      // the number we're going to send in

    long long int *ptr = lab02_3d(input_val);   // call the assembly function, save the address it returns

    // print the address we got back, and the value stored at that address
    printf("Value at myvalue address (%p): 0x%llx\n", (void*)ptr, *ptr);

    return 0;   // 0 means the program finished with no errors
}
