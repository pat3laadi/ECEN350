ARRAY_SIZE = 50000
EXPECTED_CHECKSUM = 41667916675000

A = [0] * ARRAY_SIZE
B = [0] * ARRAY_SIZE
C = [0] * ARRAY_SIZE


def main():
    for i in range(ARRAY_SIZE):
        A[i] = i
        B[i] = ARRAY_SIZE - i
        C[i] = 0

    for i in range(ARRAY_SIZE):
        s = 0
        for j in range(A[i] + 1):
            s += B[j]
        C[i] = s

    checksum = sum(C)

    print(f"Computed checksum: {checksum}")

    if checksum != EXPECTED_CHECKSUM:
        print(f"ERROR: checksum mismatch! Expected {EXPECTED_CHECKSUM} but got {checksum}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
