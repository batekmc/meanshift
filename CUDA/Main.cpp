#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <stdio.h>
#include <math.h>
#include "cuda.h"

using namespace cv;

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

int main( int argc, char** argv )
{

    if( argc != 4)
    {
         printf(" Usage: ImageToProcess  WindowSize MaxColorDifference\n");
         return -1;
    }

    image = imread(argv[1], CV_LOAD_IMAGE_GRAYSCALE);   // Read the file
    vysledek = imread(argv[1], CV_LOAD_IMAGE_GRAYSCALE);  //Output file

    radius = atoi(argv[2]);

    colorDiff = atoi(argv[3]);


    if(! image.data )                              // Check for invalid input
    {
        printf("Could not open or find the image\n");
        return -1;
    }

    xImg = image.rows;
    yImg = image.cols;

    resultMatrix = (uint8_t*)vysledek.data;
    imageMatrix = (uint8_t*)image.data;

    Hodnoty vals;
    vals.x = xImg;
    vals.y = yImg;
    vals.colorDiff = colorDiff;
    vals.radius = radius;
    vals.radiusE2 = radius*radius;
    Hodnoty *aleluja = &vals;

    printf("Start menanShift\n");
    float f = mainCu( imageMatrix, resultMatrix, aleluja);
    printf("Execution Time: %fs\n", f/1000); // Print Elapsed time

    namedWindow( "Display window", 2 );						// Create a window for display.
    imshow( "Display window", vysledek );                   // Show our image inside it.
    imwrite("MeanShiftResGB.png", vysledek);								// Zapis obr.

    waitKey(0);                                          // Wait for a keystroke in the window
    return 0;

}



