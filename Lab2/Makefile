# running "make" with no target does the same as "make all"
all: Lab02-3

# build the final program by gluing together all the .o files
Lab02-3: main.o Lab02_3b.o Lab02_3d.o
	gcc main.o Lab02_3b.o Lab02_3d.o -o Lab02-3

# turn main.c into an .o file
main.o: main.c
	gcc -g -O0 -c main.c -o main.o

# turn the assembly files into .o files so they can be linked in
Lab02_3b.o: Lab02_3b.S
	gcc -g -O0 -c Lab02_3b.S -o Lab02_3b.o

Lab02_3d.o: Lab02_3d.S
	gcc -g -O0 -c Lab02_3d.S -o Lab02_3d.o

# delete all the built files, so you can start fresh
clean:
	rm -f *.o Lab02-3
