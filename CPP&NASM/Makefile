hlavni=hlavni
asmFile=asm.asm
cppFile=bc.cpp

all: $(hlavni)

asm.o: $(asmFile)
	nasm $(asmFile) -g -f elf64 -Ox -F dwarf -o asm.o

clean:
	rm -rf asm.o hlavni

$(hlavni) : asm.o $(cppFile)
	g++ asm.o $(cppFile) -g -O3 -o $(hlavni) -lm -fopenmp  `pkg-config opencv --cflags --libs`
