#include <stdio.h>
#include <stdlib.h>

#define ARRAY_SIZE 50000
#define EXPECTED_CHECKSUM 41667916675000LL

static int A[ARRAY_SIZE];
static int B[ARRAY_SIZE];
static int C[ARRAY_SIZE];

int main(void) {
    int i, j;
    long long checksum = 0;

    for (i = 0; i < ARRAY_SIZE; i++) {
        A[i] = i;
        B[i] = ARRAY_SIZE - i;
        C[i] = 0;
    }

    for (i = 0; i < ARRAY_SIZE; i++) {
        long long sum = 0;
        for (j = 0; j <= A[i]; j++) {
            sum += B[j];
        }
        C[i] = (int)sum;
    }

    for (i = 0; i < ARRAY_SIZE; i++) {
        checksum += C[i];
    }

    printf("Computed checksum: %lld\n", checksum);

    if (checksum != EXPECTED_CHECKSUM) {
        fprintf(stderr,
                "ERROR: checksum mismatch! Expected %lld but got %lld\n",
                EXPECTED_CHECKSUM, checksum);
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
