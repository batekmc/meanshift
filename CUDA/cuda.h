
#define grid	    16
#define halfGrid	8

struct Hodnoty{
	int x,y,radius, radiusE2, colorDiff;

};

//return time of running kernel in millsec
float mainCu( unsigned char *img, unsigned char *result, Hodnoty *c );
