hlavni=hlavni
asmFile=bc.c
cppFile=bc.cpp

all: $(hlavni)

asm.o: $(asmFile)
	cc $(asmFile) -c -std=c99 -g -o  asm.o

$(hlavni) : asm.o $(cppFile)
	g++ asm.o $(cppFile) -g -o $(hlavni) -lm -fopenmp  `pkg-config opencv --cflags --libs`

clean:
	rm -rf asm.o hlavni
