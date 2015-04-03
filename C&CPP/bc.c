#include <math.h>
//#include "bc.h"
/*
 *   @param x - Xova souradnice zkoumaneho pixelu
 *   @param y - Yova souradnice zkoumaneho pixelu
 *   @param col - barva (0 - 255) pixelu
 *   //TODO
 */
const int maxIteraci = 500;
const float minPosun = 0.002;

void meanShift( unsigned char *imageMatrix, unsigned char *resultMatrix, int xP, int yP, unsigned char color, int *H ){
    float windowSum = 0.0f;
    float xyzSum[3];
    for(int i =0; i < 3 ; i++)
    	xyzSum[i] = 0.0f;
    float sum = 0.0f;
    float posun = 0.0f;
    int iterace = 0;
    float x = xP;
    float y = yP;
    float rootColor = color;
    //xxd = (x - xi)/h etc.
    float xxd = 0.0f, yyd = 0.0f, zzd = 0.0f;
    unsigned char childColor = 0;
    //Hodnoty ze struktury
    int radiusE2 = H[4];
    int xImg = H[0];
    int yImg = H[1];
    int radius = H[3];
    int colorDiff = H[2];
    int ahoj1 = 0;


    while(1){

    	//okno
        for( int i = ( x - radius - 1) ; i < ( x + radius + 1) ; i++ )
        {
            for( int j = ( y - radius - 1) ; j < ( y + radius + 1) ; j ++)
            {
                //okraje obrazu
                if( i < 0 ) i = 0;
                if( j < 0 ) j = 0;
                if( i >= xImg ) break;
                if( j >= yImg ) break;
                sum = 0.0f;
                
                //kruh           
                if( (i - x) * (i - x) + (j - y ) * (j - y) <= radiusE2 )
                {
                    childColor = imageMatrix[ i * yImg + j];
                    float roz = childColor - rootColor;
                    if( roz < 0 )roz *= -1;
                    //odpovida-li bod parametrum
                    if( colorDiff - roz > 0 ){
                        xxd = (x - i) / (float)radius;
                        yyd = (y - j) / (float)radius;
                        zzd = (rootColor - childColor) / (float)colorDiff;
                        
                        sum = xxd*xxd + yyd*yyd + zzd*zzd;
                        
                        //kernel(Epanechnikov)
                        if( sum >= 1.0f )
                            sum = 0.0f;
                        else{                        
                            sum = 0.75f * ( 1.0f - sum * sum );
			    //printf("ahoj %i\n", ahoj1);ahoj1++;
			}                        
                        windowSum += sum;
                        
                        xyzSum[0] += sum*i;
                        xyzSum[1] += sum*j;
                        xyzSum[2] += sum*childColor;
                                           
                        //cout<< "suma pro: " << i << " , "  << j << " | je : " << sum << endl;

                    }
                    
                }//kruh
                
            }//for
        }//for
        
        //cout<< "iterace: " << iterace<< endl;

        xyzSum[0] /= windowSum;
        xyzSum[1] /= windowSum;
        xyzSum[2] /= windowSum;
        posun = sqrt((xyzSum[0] - x) * (xyzSum[0] - x) + (xyzSum[1] - y) * (xyzSum[1] - y) + (xyzSum[2] - rootColor) * (xyzSum[2] - rootColor));
        iterace++;

        if( iterace > maxIteraci || posun < minPosun ){
        	resultMatrix[ xP * yImg + yP] = xyzSum[2];
        	break;
        }

        //nove souradnice
        //if( fmod(xyzSum[0], (int)xyzSum[0]) > 0.0f ) xyzSum[0]++;
        //if( fmod(xyzSum[1], (int)xyzSum[1]) > 0.0f ) xyzSum[1]++;

        x = xyzSum[0];
        y = xyzSum[1];
        rootColor = xyzSum[2];

        xyzSum[0] = xyzSum[1] = xyzSum[2] = windowSum = 0.0f;

    }
	//TEST
	//return (unsigned char)xyzSum[2];
}



