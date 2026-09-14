all: Lab02-1

Lab02-1: main.o test.o
	gcc main.o test.o -o Lab02-1

main.o: main.c
	gcc -g -O0 -c main.c -o main.o

test.o: test.S
	gcc -g -O0 -c test.S -o test.o

clean:
	rm -f *.o Lab02-1
