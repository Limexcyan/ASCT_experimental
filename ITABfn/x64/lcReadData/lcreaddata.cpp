#include "mex.h"
#include "matrix.h"
#include <stdio.h>
#include <string.h>
#include "/home/mirek/Sci/Exp/Sara/x64/lcReadHeader/vp_biomag.h"

/**********************************************

   argument list:
   
   biomagreaderdata(

      numero di canali da leggere,
      
      lista dei canali da leggere,
      
      offset di lettura,
      
      numero di punti da leggere per canale,
      
      nome del file

      )

**********************************************/

int biomagreaderdata(float **data,int nchan, int *ch_list,
                     int offset, int ntp,char *fname)
{
   header640 h;
   FILE *fp;

   fp = fopen(fname,"rb");
   if (fp==NULL) return -1;
   h = vp_read_header(fp,fname);

   vp_read_data(data, h, nchan, ch_list,
                 offset,  ntp, fp);

   fclose(fp);
   return 0;
}
                                                      
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
   int i,l,nchan,*ch_list,offset,npt;
   float **data;
   char fname[256];
   double *temp;
   
   /* Check for proper number of arguments. */
   if(nrhs < 4) {
      mexPrintf("\nlcReadData v2.0\n\n");
      mexPrintf("Reader of biomagnetic data.\n\n");
      mexPrintf("june 2003 - Luca Ciancetta & Vittorio Pizzella - ITAB institute\n\n");
      mexPrintf("Usage:\n\n");
      mexPrintf("lcreaddata( channel list , offset , number of points , [path +]file name  )\n\n\n");
      mexPrintf("Example:\n\n");
      mexPrintf("a = lcreaddata([1 2 3],0,1000,'e:/raw/albr01/albr0101.raw')\n\n\n");
      mexPrintf("Result is a matrix with dimension of (number of channel)x(number of points).\n\n\n\n");
      
      mexErrMsgTxt("Four input required.");
      return;
   } else if(nlhs > 1) {
      mexPrintf("\nlcReadData v2.0\n\n");
      mexPrintf("Reader of biomagnetic data.\n\n");
      mexPrintf("june 2003 - Luca Ciancetta & Vittorio Pizzella - ITAB institute\n\n");
      mexPrintf("Usage:\n\n");
      mexPrintf("lcreaddata( channel list , offset , number of points , [path +]file name  )\n\n\n");
      mexPrintf("Example:\n\n");
      mexPrintf("a = lcreaddata([1 2 3],0,1000,'e:/raw/albr01/albr0101.raw')\n\n\n");
      mexPrintf("Result is a matrix with dimension of (number of channel)x(number of points).\n\n\n\n");

      mexErrMsgTxt("Too many output arguments");
      return;
   }

   /* get the file name to read */
   mxGetString(prhs[3],fname,256);
  

   /* get channel list */
   nchan = mxGetM(prhs[0]);
   if (nchan<mxGetN(prhs[0])) nchan=mxGetN(prhs[0]);
   temp = mxGetPr(prhs[0]);
   
   ch_list = new int[nchan];
   
   /* get data offset */
   offset =(int)mxGetScalar(prhs[1]);
   /* get points per channel */
   npt = (int)mxGetScalar(prhs[2]);

   data = new float*[nchan];

   for(i=0;i<nchan;i++){
      ch_list[i] = (int)temp[i];
      data[i] = new float[npt];
   }

   /* read data */
   if (biomagreaderdata(data,nchan,ch_list,offset,npt,fname) == -1) {
      mexErrMsgTxt("Error in reading data.");
      return;
   }

   delete ch_list;

   /* create data matrix */
   plhs[0] = mxCreateDoubleMatrix(nchan,npt,mxREAL);
   temp = mxGetPr(plhs[0]);
   for(i=0;i<npt;i++)
      for(l=0;l<nchan;l++)
         temp[l+nchan*i] = data[l][i];

   for(i=0;i<nchan;i++) delete data[i];
   delete data;

}

