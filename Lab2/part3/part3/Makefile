all: Lab02-3

Lab02-3: main.o test.o Lab02_3b.o Lab02_3d.o
	gcc main.o test.o Lab02_3b.o Lab02_3d.o -o Lab02-3

main.o: main.c
	gcc -g -O0 -c main.c -o main.o

test.o: test.S
	gcc -g -O0 -c test.S -o test.o

Lab02_3b.o: Lab02_3b.S
	gcc -g -O0 -c Lab02_3b.S -o Lab02_3b.o

Lab02_3d.o: Lab02_3d.S
	gcc -g -O0 -c Lab02_3d.S -o Lab02_3d.o

clean:
	rm -f *.o Lab02-3
