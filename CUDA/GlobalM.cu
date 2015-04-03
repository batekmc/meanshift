#include <stdio.h>
#include "cuda.h"

__device__ __constant__ int maxIteraci = 500;
__device__ __constant__ float minPosun = 0.001f;
__device__ __constant__ Hodnoty hodnotyD;

/**
 * CUDA kernel function, ktera dela meanShift segmentaci
 * @param *img ukazatel na zpracovavany obrazek
 * @param *res ukazatel na vysldek
 *
 */
__global__ void doMeanShift(const unsigned char *img, unsigned char *res ) {

	int xP = blockIdx.x*blockDim.x + threadIdx.x;
	int yP = blockIdx.y*blockDim.y + threadIdx.y;

	if(xP >= hodnotyD.x || yP >= hodnotyD.y)
		return;
	float windowSum = 0.0f;
	float xyzSum[3];
    for(int i =0; i < 3 ; i++)
    	xyzSum[i] = 0.0f;
    float sum = 0.0f;
    float posun = 0.0f;
    int iterace = 0;
    //xxd = (x - xi)/h etc.
    float xxd = 0.0f, yyd = 0.0f, zzd = 0.0f;
    unsigned char childColor = 0;
    float x = xP;
    float y = yP;
    float rootColor = img[xP*hodnotyD.y + yP];
    int iA, iB, jA, jB;
    float rozdil;


    while(true){

    	//okno
    	iA = ( x - hodnotyD.radius - 1);
    	iB = ( x + hodnotyD.radius + 1);
    	jA = ( y - hodnotyD.radius - 1);
    	jB = ( y + hodnotyD.radius + 1);

        //okraje obrazu
        if( iA < 0 ) iA = 0;
        if( jA < 0 ) jA = 0;
        if( iB >= hodnotyD.x ) iB = hodnotyD.x;
        if( jB >= hodnotyD.y ) jB = hodnotyD.y;

        for( int i = iA ; i < iB ; i++ )
        {
            for( int j = jA ; j < jB ; j ++)
            {
                sum = 0.0f;
                //kruh
                if( (i - x) * (i - x) + (j - y ) * (j - y) <= hodnotyD.radiusE2 )
                {
                    childColor = img[ i * hodnotyD.y + j];
                    rozdil =  rootColor - childColor;
 
                        xxd = (x - i) / (float)hodnotyD.radius;
                        yyd = (y - j) / (float)hodnotyD.radius;
                        zzd = rozdil / (float)hodnotyD.colorDiff;

                        sum = xxd*xxd + yyd*yyd + zzd*zzd;

                        //kernel(Epanechnikov)
                        if( sum >= 1.0f )
                            sum = 0.0f;
                        else
                            sum = 0.75f * ( 1.0f - sum * sum );

                        windowSum += sum;

                        xyzSum[0] += sum*i;
                        xyzSum[1] += sum*j;
                        xyzSum[2] += sum*childColor;
                    

                }//kruh

            }//for
        }//for

        xyzSum[0] /= windowSum;
        xyzSum[1] /= windowSum;
        xyzSum[2] /= windowSum;
        posun = sqrt((xyzSum[0] - x) * (xyzSum[0] - x) + (xyzSum[1] - y) * (xyzSum[1] - y) + (xyzSum[2] - rootColor) * (xyzSum[2] - rootColor));
        iterace++;

        if( iterace >= maxIteraci || posun < minPosun ){
        	res[xP*hodnotyD.y + yP] = xyzSum[2];
        	break;
        }

        x = xyzSum[0];
        y = xyzSum[1];
        rootColor = xyzSum[2];

        xyzSum[0] = xyzSum[1] = xyzSum[2] = windowSum = 0.0f;

     }//wile
}

void checkCUDAError(const char *msg)
{
    cudaError_t err = cudaGetLastError();
    if( cudaSuccess != err)
    {
        fprintf(stderr, "Cuda error: %s: %s.\n", msg,
                                  cudaGetErrorString( err) );
        exit(EXIT_FAILURE);
    }
}

/**
 * fce kopiruje data na kartu, kopiruje vysledek do pameti, vraci cas provedeni kernelu v milsec.
 */
float mainCu( unsigned char *img, unsigned char *result, Hodnoty *hodnoty ) {

	//mereni casu
	cudaEvent_t start,stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	size_t Size =  hodnoty->x*hodnoty->y;

	//ukazatele na device mem.
	unsigned char * img_d, *result_d;
	//Hodnoty *val_d;
	dim3 threadsPerBlock(16, 16);
	int xBlock = (hodnoty->x / threadsPerBlock.x);
	if( hodnoty->x % threadsPerBlock.x ) xBlock++;
	int yBlock = (hodnoty->y / threadsPerBlock.y);
	if( hodnoty->y % threadsPerBlock.y ) yBlock++;
	dim3 numBlocks( xBlock , yBlock );

	cudaEventRecord(start, 0);

	//alokace
	cudaMalloc((void **) &img_d, sizeof(unsigned char)*Size);
	cudaMalloc((void **) &result_d, sizeof(unsigned char)*Size);
	//cudaMalloc((void **) &val_d, sizeof(Hodnoty));

	checkCUDAError("cudaMalloc to device");

	//nakopiruju do dev
	cudaMemcpy(img_d, img, ( Size*sizeof(unsigned char) ), cudaMemcpyHostToDevice);
	cudaMemcpy(result_d, result, ( Size*sizeof(unsigned char) ), cudaMemcpyHostToDevice);
	//Hodnoty h = *hodnoty;
	//const. mem.
	cudaMemcpyToSymbol(hodnotyD, hodnoty, ( sizeof(Hodnoty) ), 0,cudaMemcpyHostToDevice);
	checkCUDAError("cudaMemcpy to device");

	doMeanShift<<<numBlocks, threadsPerBlock>>>(img_d, result_d);
	checkCUDAError("doMeanShift(kernel call)");

	// block until the device has completed
	cudaThreadSynchronize();

	checkCUDAError("cudaThreadSynchronize");

	//po skonceni konci mereni casu
	cudaEventSynchronize(stop);

	// device to host copy
	cudaMemcpy( result, result_d, Size*sizeof(unsigned char), cudaMemcpyDeviceToHost );

	checkCUDAError("cudaMemcpy to host");
	cudaEventRecord(stop, 0);

	//uvolneni pameti
	cudaFree(img_d);
	cudaFree(result_d);
	//cudaFree(val_d);

	//vysledny cas
	float elapsedTime;
	cudaEventElapsedTime(&elapsedTime, start, stop);//vypocet casu, presnost okolo 0.5 microseconds
	cudaEventDestroy(start);
	cudaEventDestroy(stop);

	return elapsedTime;

}
