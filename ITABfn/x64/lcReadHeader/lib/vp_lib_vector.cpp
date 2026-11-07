/*************************************/
/*  ViP library - Vector  utilities  */
/*                                   */
/*  by Vittorio Pizzella             */
/*                                   */
/*  Version 14.0.1                   */
/*                                   */
/*  Last revision:  May 24, 2003     */
/*************************************/

/************************************************************************/
/*  Library for biomag programs                                         */
/*                                                                      */
/*  float vp_sum       (float *, int, int)       Find SUM[a(i)]         */
/*  float vp_dot       (float *, float *, int)   Find SUM[a(i)*b(i)]    */
/*  float vp_min       (float *, int)            Find minimum value     */
/*  float vp_max       (float *, int)            Find maximum value     */
/*  float vp_nthmax    (float *, int, int)       Find nth maximum value */
/*  void  vp_meanzero  (float *, int)            Subtract mean          */
/************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
// #include "vp_biomag.h" Riccardo Navarra (test)

/******************************/
/*  Sum elements of an array  */
/******************************/

float vp_sum(float a[], int inc, int n)
{
   float sum = 0;
   int   i;
   for (i=0; i<n*inc; i+=inc)
       sum += a[i];
   return(sum);
}


/****************************************/
/*  Find scalar product of two vectors  */
/****************************************/

float vp_dot(float a[], float b[], int n)
{
   double dot = 0;
   int   i;
   for (i=0; i<n; i++)
      dot += (double)(a[i] * b[i]);
   return((float)dot);
}


/******************************/
/*  Find minimum of a vector  */
/******************************/

float vp_min(float a[], int n)
{
   float amin = (float)1e38;
   while (n>0)
   {
      n--;
      if (a[n]<amin) amin = a[n];
   }
   return(amin);
}


/******************************/
/*  Find maximum of a vector  */
/******************************/

float vp_max(float a[], int n)
{
   float amax = (float)-1e38;
   while (n>0)
   {
      n--;
      if (a[n]>amax) amax = a[n];
   }
   return(amax);
}


/******************************************************/
/*  Find nth maximum value of a vector of lenght npt  */
/******************************************************/

float vp_nthmax(float *a, int npt, int nth)
{
   int   i, j;
   float *amax, aout;

   amax = (float *)malloc(nth * sizeof(float));
   if (amax == NULL)
   {
  	 fprintf(stderr, "\n ERROR!  vp_nthmax can't allocate memory");
	 return(0);
   }
   
   for (i=0; i<nth; i++)
	 amax[i] = (float)-1e38;

   while (npt>0)
   {
     npt--;
	 for (i=0; i<nth; i++)
	 {
	   if (a[npt]>amax[i])
	   {
		 for (j=nth-1; j>i; j--)
		   amax[j] = amax[j-1];
		 amax[i] = a[npt];
		 i = nth;                 /*  Exit for loop at next iteration  */
	   }
	 }

   }

   aout = amax[nth-1];
   free(amax);
   return(aout);
}



/*************************************/
/*  Subtract mean value from buffer  */
/*************************************/
void vp_meanzero(float *buffer, int buffer_points)
{
   int   i;
   float average;

   average = 0;
   for (i=0; i<buffer_points; i++)
      average +=buffer[i];
   average /= buffer_points;
   for (i=0; i<buffer_points; i++)
      buffer[i] -= average;

   return;
}