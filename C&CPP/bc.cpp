#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <stdio.h>
#include <math.h>
#include <omp.h> //mereni casu

//#include "bc.h"

using namespace cv;
using namespace std;

//nacitany a vysledny obr.
Mat image, vysledek;

//hodnoty nacitane z cml
int colorDiff = -1;
int radius = -1;

//rozmery obr.
int xImg = -1;
int yImg = -1;

//ukazatele ma matici obr.
uint8_t* imageMatrix;
uint8_t* resultMatrix;

extern "C" {
	void meanShift( unsigned char *imageMatrix, unsigned char *resultMatrix, int xP, int yP, unsigned char color, int * H );
}


int main( int argc, char** argv )
{

    if( argc != 4)
    {
         cout <<" Usage: ImageToProcess  WindowSize MaxColorDifference" << endl;
         return -1;
    }

    image = imread(argv[1], CV_LOAD_IMAGE_GRAYSCALE);   // Read the file
    vysledek = imread(argv[1], CV_LOAD_IMAGE_GRAYSCALE);  //Output file -

    radius = atoi(argv[2]);
        
    colorDiff = atoi(argv[3]);
    

    if(! image.data )                              // Check for invalid input
    {
        cout <<  "Could not open or find the image" << std::endl ;
        return -1;
    }

    xImg = image.rows;
    yImg = image.cols;

    imageMatrix = (unsigned char*)(image.data);
    resultMatrix = (unsigned char*)(vysledek.data);
    //-----Hodnoty----------
    int H[5];
    H[0] = xImg;
    H[1] = yImg;
    H[2] = colorDiff;
    H[3] = radius;
    H[4] = radius*radius;  
    //---------------------

    cout<<" Zacatek MeanShiftu."  <<endl;
    int numCores = 0;
    double start = omp_get_wtime();

    #pragma omp parallel for
    for( int i = 0 ; i < xImg ; i ++)
	for( int j = 0 ; j < yImg ; j ++){
	    meanShift( imageMatrix, resultMatrix,
				 i, j, (int)imageMatrix[ i * yImg + j], H);
	    if(i == 0 && j == 0)numCores = omp_get_num_threads();
    }
		
    double end = omp_get_wtime();
    cout<<" Konec MS. Cekovy cas: " << (end - start) <<"s. "<<"Pocet vlaken(jader) CPU : "<< numCores<<endl;
     
    imwrite("temp2.png", vysledek);
    namedWindow( "Display window", CV_WINDOW_AUTOSIZE );// Create a window for display.
    imshow( "Display window", vysledek );                   // Show our image inside it.

    waitKey(0);                                          // Wait for a keystroke in the window
    return 0;
}












