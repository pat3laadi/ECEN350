#include <stdio.h>

// tells C that "Lab02_3b" exists somewhere else (in Lab02_3b.S)
// it takes no arguments and returns nothing (it just modifies msg1 in place)
extern void Lab02_3b(void);

// tells C that "lab02_3d" exists somewhere else (in Lab02_3d.S)
// it takes one number in, and gives back a pointer (an address)
extern long long int* lab02_3d(long long int val);

int main() {
    // call Lab02_3b, which loads a byte from msg1, adds 0x20 to it,
    // and stores it back into msg1
    Lab02_3b();

    long long int input_val = 0x100;      // the number we're going to send in

    long long int *ptr = lab02_3d(input_val);   // call the assembly function, save the address it returns

    // print the address we got back, and the value stored at that address
    printf("Value at myvalue address (%p): 0x%llx\n", (void*)ptr, *ptr);

    return 0;   // 0 means the program finished with no errors
}
