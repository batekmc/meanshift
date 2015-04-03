# Makefile pro segmentcai obrazu metodou MeanShift, pomoci nVidia CUDA,s vyuzitim globalni pameti
main=Main.cpp
header=cuda.h
cuda=GlobalM.cu
comp=nvcc

mainBin=Main.o
cudaBin=Cuda.o

all : MSonCUDA

MSonCUDA : $(mainBin) Cuda.o
	$(comp) -o MSonCUDA $(mainBin) $(cudaBin) `pkg-config opencv --cflags --libs`

Main.o : $(main) $(header)
	$(comp) -c -o $(mainBin) $(main) 

Cuda.o : $(cuda) $(header)
	$(comp) -c -o $(cudaBin) $(cuda)

clean : 
	rm -f $(mainBin) $(cudaBin) MSonCUDA
	
