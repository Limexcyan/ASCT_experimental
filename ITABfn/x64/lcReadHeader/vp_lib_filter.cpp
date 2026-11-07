/********************************************************************/
/*  ViP library - Filters                                           */
/*                                                                  */
/*  by Vittorio Pizzella                                            */
/*                                                                  */
/*  Version 14.1.1                                                  */
/*                                                                  */
/*  Last revision:  May 24, 2003                                    */
/*  Last revision:  Feb 11, 2007      Updated bandpass filter with  */
/*                                    better buffer extension       */
/********************************************************************/


/************************************************************************************/
/*  Filter library for biomag programs                                              */
/*                                                                                  */
/* void  vp_correlation_flt (float *, float *, int, int)             Correlation    */
/* void  vp_rectifier_flt   (float *, int)                           Rectifier      */
/* void  vp_derivate_flt    (float *, int)                           Derivate       */
/* void  vp_artefact_filter (float *, int, int)                      Artefact       */
/* void  vp_bandpass_filter (float *, int, float, float, float)      Bandpass       */
/* void  vp_fltlp           (float *, float, float, float, int)      Low pass       */
/* void  vp_flthp           (float *, float, float, float, int)      High pass      */
/* void  sc_notch_filter    (float *, int, float, float, float)      Notch          */
/* void  sc_four1           (float *, int, int)                      FFT            */
/* void  lm_heart_filter    (float **, char *, int, int, ch_info *, int)  Heart flt */
/************************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
// #include "vp_biomag.h" Riccardo Navarra (test)
#include "lc_support.h"


/**********************************************************************************/
/**********************************************************************************/

void  vp_correlation_flt (float *signal, float *reference, int ndatapoints, int npts_corr)
{
   int     i, j, js, je;
   float   *buffer;
   double  s1, s2, base_sig, base_ref;

   buffer = (float *)malloc(ndatapoints * sizeof(float));
   if (buffer == NULL)
   {
      fprintf(stderr, "\n ERROR!  can't allocate buffer memory");
      exit(-1);
   }

/*  Find baseline  */
   base_sig = 0.;
   base_ref = 0.;
   for (j=0; j<ndatapoints; j++)
   {
      base_sig += (double)signal[j];
      base_ref += (double)reference[j];
   }
   base_sig /= ndatapoints;
   base_ref /= ndatapoints;

/*  Filter !!  */
   for (i=0; i<ndatapoints; i++)
   {
      s1 = 0;
      s2 = 0;
      js = i - npts_corr;
      je = i + npts_corr;
      if (js < 0)           js = 0;
      if (je > ndatapoints) je = ndatapoints;

      for (j=js; j<je; j++)
      {
         s1 += ((double)signal[j] - base_sig) * ((double)reference[j] - base_ref);
         s2 += ((double)reference[j] - base_ref) * ((double)reference[j] - base_ref);
      }
      buffer[i] = (float)(((double)signal[i] - base_sig) - ((double)reference[i] - base_ref) * s1 / s2);
   }

/*  Move data back to original buffer  */
   for (i=0; i<ndatapoints; i++)
      signal[i] = buffer[i];

   free(buffer);

   return;
}



/**************************/
/**************************/
/**   Rectifier filter   **/
/**************************/
/**************************/

void  vp_rectifier_flt   (float buffer[], int npt, int step)
{
   int    i, j, imin, imax;
   float  *buftemp;

   if (step < 0)        step = 5;
   if (step > npt / 2)  step = npt / 2;

   buftemp = (float *)malloc(npt * sizeof(float));
   if (buftemp != NULL)
   {

      for (i=0; i<npt; i++)
         buftemp[i] = (float)fabs(buffer[i]);

      for (i=0; i<npt; i++)
      {
         imin = i-step;
         imax = i+step;
         if (imin < 0)    imin = 0;
         if (imax > npt)  imax = npt;
         buffer[i] = 0;
         for (j=imin; j<imax; j++)
         buffer[i] += buftemp[j];
         buffer[i] = buffer[i] / (imax - imin + 1);
      }
      free (buftemp);
   }
   else
      fprintf(stderr, "\n ERROR!  can't allocate buffer memory\n");

   return;
}



/**************************/
/**************************/
/**   Derivate filter    **/
/**************************/
/**************************/

void  vp_derivate_flt(float buffer[], int npt)
{
   int    i;

   for (i=0; i<(npt-2); i++)
     buffer[i] = buffer[i+1] - buffer[i];

   for (i=npt-1; i>0; i--)
      buffer[i] = buffer[i-1];

   return;
}



/****************************************/
/****************************************/
/**   Compute Fast Fourier Transform   **/
/****************************************/
/****************************************/

void sc_four1 (float data[], int nn, int isign)
{
   int    n, mmax, m, j, istep, i;
   double wtemp, wr, wpr, wpi, wi, theta;
   float  tempr, tempi;

   n = 2 * nn;
   j = 1;
   for (i = 1; i < n; i += 2)
   {
       if (j > i)
       {
          tempr = data[j-1];
          tempi = data[j];
          data[j-1] = data[i-1];
          data[j] = data[i];
          data[i-1] = tempr;
          data[i] = tempi;
       }
       m = n / 2;
       while (m >= 2 && j > m)
       {
          j -= m;
          m = m / 2;
       }
       j += m;
   }
   mmax = 2;
   while (n > mmax)
   {
      istep = 2 * mmax;
      theta = 6.28318530717959 / (isign * mmax);
      wtemp = sin(0.5 * theta);
      wpr = -2.0 * wtemp * wtemp;
      wpi = sin(theta);
      wr = 1.0;
      wi = 0.0;
      for (m = 1; m < mmax; m += 2)
      {
         for (i = m; i <= n; i += istep)
      {
          j = i + mmax;
          tempr = (float)(wr * (double)data[j-1] - wi * (double)data[j]);
          tempi = (float)(wr * (double)data[j] + wi * (double)data[j-1]);
          data[j-1] = data[i-1] - tempr;
          data[j] = data[i] - tempi;
          data[i-1] += tempr;
          data[i] += tempi;
      }
      wtemp = wr;
      wr = wr * wpr - wi * wpi + wr;
      wi = wi * wpr + wtemp * wpi + wi;
      }
      mmax = istep;
   }
}



/**********************/
/**********************/
/**   Notch Filter   **/
/**********************/
/**********************/

void sc_notch_filter (float y[], int nd, float rf, float bw, float sf)
{
   int    i;
   double theta, rho, a0, a1, a2, b1, b2, t0, t1, t2;

   theta = 2 * PI * rf / sf;
   rho   = 1 - (bw * PI / sf);

   a0 = 1;
   a1 = - 2 * cos (theta);
   a2 = 1;
   b1 = - a1 * rho;
   b2 = - rho * rho;

   t0 = y[0];
   y[0] = (float)(a0 * t0);
   t1 = t0;
   t0 = y[1];
   y[1] = (float)(a0 * t0 + a1 * t1 + b1 * (double)y[0]);

   for (i = 2; i < nd; i++)
   {
      t2 = t1;
      t1 = t0;
      t0 = y[i];
      y[i] = (float)(a0 * t0 + a1 * t1 + a2 * t2 + b1 * (double)y[i-1] + b2 * (double)y[i-2]);
   }
}



/*************************/
/*************************/
/**   Artefact filter   **/
/*************************/
/*************************/

void vp_artefact_filter (float buffer[], int ntppre, int len)
{
   int   i;
   float delta;

   delta = (buffer[ntppre+len-2] - buffer[ntppre-2]) / len;
   for (i=-2; i<(len-2); i++)
      buffer[ntppre+i+1] = buffer[ntppre+i] + delta;

   return;
}



/*************************/
/*************************/
/**   Bandpass filter   **/
/*************************/
/*************************/

void vp_bandpass_filter (float xbuf[], int npt, float smpfq, float alow, float ahigh)
{

   #define EXT 512			/* Buffer extension */
 
   int   i, nnpt;
   float vmean;
   float *ubuf;

   ubuf = (float*) calloc (npt+EXT*2, sizeof(float));
   if (ubuf == NULL)
   {
      fprintf(stderr, "\n ERROR!  Can't allocate filter buffer memory. Skipping bandpass filter.");
      return;
   }

/*****************************************************/
/*   Check for low pass filter value (max smpfq/2)   */
/*****************************************************/

   if (alow > (smpfq/2))
   {
      fprintf(stderr, "\n ERROR!  Lowpass > smpfq/2. Skipping lowpass filter.");
      alow = 0;
   }

/**************************************************************************************/
/*   Subtract DC value (only if high pass filter is used) and transfer to ubuf buffer */
/**************************************************************************************/
   
   vmean = 0;
   if (ahigh > 0.)
   {
      for (i=0; i<npt; i++)
         vmean = vmean + xbuf[i];
      vmean = vmean / npt;
   }
   for (i=0; i<npt; i++)
      ubuf[i+EXT] = xbuf[i] - vmean;

/******************************/
/*   Increase buffer length   */
/******************************/

   for (i=0; i<EXT; i++)
      ubuf[EXT+npt+i] = 2*ubuf[EXT+npt-1] - ubuf[EXT+npt-i-2];
 
   for (i=EXT; i>0; i--)
      ubuf[i-1] = 2*ubuf[EXT] - ubuf[2*EXT-i+1];
 
/********************************************/
/*   Perform desidered filter combination   */
/********************************************/

   nnpt  = npt + EXT*2;
   if (alow > 0.0)
      vp_fltlp (ubuf, smpfq, alow, 1, nnpt);
   if (ahigh > 0.0)
      vp_flthp (ubuf, smpfq, ahigh, 1, nnpt);

   for (i = 0; i < npt; i++)
      xbuf[i] = ubuf[i+EXT];
 

   free (ubuf);

   return;
}



/*******************************************************************/
/*******************************************************************/
/** A BUTTERWORTH (MAX. FLAT) FILTER OF EITHER 2ND OR 4TH         **/
/** ORDER IMPLEMENTED DIGITALLY WITH BILINEAR TRANSFORM.          **/
/** IN ADDITION, DATA IS PASSED THROUGH TWICE (FORWARD AND THEN   **/
/** TIME-REVERSED) GIVING ZERO PHASE SHIFT.  ROLLOFF RATES ARE    **/
/** EXTREMELY RAPID SINCE THE BILINEAR TRANSFORMATION             **/
/** COMPRESSES THE ANALOG FREQUENCY AXIS LOGARITHMICALLY,         **/
/** GIVING A ROLLOFF AT LOW FREQUENCIES OF -12 OR -24 dB/octave   **/
/** (FOR 2 & 4 POLES), INCREASING RAPIDLY ABOVE NYQUIST/2, AND    **/
/** BECOMING INFINITELY STEEP AT THE NYQUIST FREQUENCY.           **/
/** THE TWO PASSES THEN RESULT IN SQUARING THE FREQUENCY RESPON   **/
/** SE, OR, MEASURED IN dB, DOUBLING THE ATTENUATION.             **/
/** THE POLES ARE CALCULATED EACH TIME TO GIVE DESIRED            **/
/** CUTOFF FREQUENCY.  FILTER IS IMPLEMENTED WITH 1 OR 2 CASCADED **/
/** 2ND ORDER SECTIONS.                                           **/
/*******************************************************************/
/*******************************************************************/

void vp_fltlp (float xbuf[], float fsamp, float fcut, float rloff, int ilp)
{

   int    i;
   double omega, om2, den, del11, del12, del21, del22,
          sum1, sum2, w, rscal, c1, c2, gains, del1, del2;
   double r[2], a1[2], a2[2], gain[2];

   r[0] = 0.765;
   r[1] = 1.848;

/* FIRST CALCULATE ANALOG FREQ. CORRESPONDING TO
   DESIRED DIGITAL FILTER CUTOFF ("PREWARP").    */

   omega = 2.0 * tan ((double)(fcut * PI / fsamp));

   if (rloff != 0.0)
   {

/* USE THE 4TH ORDER FILTER. */

/* ADJUST THE CUTOFF FREQ. SO FCUT IS ONLY -1.5 dB
   (NECESSARY SINCE WE FILTER TWICE)               */

      omega = 1.0783 * omega;
      om2 = omega * omega;
      for (i = 0; i < 2; i++)
      {
         den = 4.0 + 2.0 * omega * r[i] + om2;
         a1[i] = (8.0 - 2.0 * om2) / den;
         a2[i] = - (4.0 - 2.0 * r[i] * omega + om2) / den;
         gain[i] = om2 / den;
      }

/* INITIALIZE */

      del11 = 0;
      for (i = ilp-1; i >= ilp-4; i--)
         del11 = del11 + xbuf[i];
      del11 = del11 * 0.25;
      del12 = del11;
      del21 = del11;
      del22 = del11;

/* NOW APPLY FILTER TO TIME-REVERSED DATA */

      for (i = ilp-1; i >= 0; i--)
      {

/* FIRST 2ND-ORDER SECTION */

         sum1 = gain[0] * xbuf[i] + a1[0] * del11 + a2[0] * del12;
         w = sum1 + 2.0 * del11 + del12;
         del12 = del11;
         del11 = sum1;

/* SECOND 2ND-ORDER SECTION OPERATES ON OUTPUT OF FIRST */

         sum2 = gain[1] * w + a1[1] * del21 + a2[1] * del22;
         xbuf[i] = (float) (sum2 + 2.0 * del21 + del22);
         del22 = del21;
         del21 = sum2;
      }

/* NOW TIME REVERSE AND REFILTER */

/* INITIALIZE AGAIN */

      del11 = 0;
      for (i = 0; i < 4; i++)
      del11 = del11 + xbuf[i];
      del11 = del11 * 0.25;
      del12 = del11;
      del21 = del11;
      del22 = del11;

/* NOW APPLY FILTER */

      for (i = 0; i < ilp; i++)
      {

/* FIRST 2ND-ORDER SECTION */

         sum1 = gain[0] * xbuf[i] + a1[0] * del11 + a2[0] * del12;
         w = sum1 + 2.0 * del11 + del12;
         del12 = del11;
         del11 = sum1;

/* SECOND 2ND-ORDER SECTION OPERATES ON OUTPUT OF FIRST */

         sum2 = gain[1] * w + a1[1] * del21 + a2[1] * del22;
         xbuf[i] = (float) (sum2 + 2.0 * del21 + del22);
         del22 = del21;
         del21 = sum2;
       }

      return;

   }

   else

   {

/* HERE IS THE 2ND ORDER FILTER */

      rscal = 1.414;

/* AGAIN, ADJUST OMEGA SO FCUT CORRESP. TO -1.5dB */

      omega = 1.2478 * omega;
      om2 = omega * omega;
      den = 4.0 + 2.0 * omega * rscal + om2;
      c1 = (8.0 - 2.0 * om2) / den;
      c2 = - (4.0 - 2.0 * rscal * omega + om2) / den;
      gains = om2 / den;

/* NOW APPLY FILTER TO TIME REV. DATA */

      del1 = 0.5 * (xbuf[ilp-1] + xbuf[ilp-2]);
      del2 = del1;

      for (i = ilp-1; i >= 0; i--)
      {
         sum1 = gains * xbuf[i] + c1 * del1 + c2 * del2;
      xbuf[i] = (float) (sum1 + 2.0 * del1 + del2);
         del2 = del1;
         del1 = sum1;
      }

      del1 = 0.5 * (xbuf[0] + xbuf[1]);
      del2 = del1;

      for (i = 0; i < ilp; i++)
      {
         sum1 = gains * xbuf[i] + c1 * del1 + c2 * del2;
      xbuf[i] = (float) (sum1 + 2.0 * del1 + del2);
         del2 = del1;
         del1 = sum1;
      }

      return;
   }

}


/********************************************************************/
/********************************************************************/
/** A BUTTERWORTH HIGH PASS FILTER OF EITHER 2ND OR 4TH            **/
/** ORDER IMPLEMENTED DIGITALLY WITH BILINEAR TRANSFORM.           **/
/** IN ADDITION, DATA IS PASSED THROUGH TWICE (FORWARD AND THEN    **/
/** TIME-REVERSED) GIVING ZERO PHASE SHIFT.  ROLLOFF RATES ARE     **/
/** EITHER 24 OR 48 dB/oct:  12/24 FOR THE BASIC 2/4 POLE          **/
/** FILTERS, DOUBLED BY PASSING THROUGH TWICE.                     **/
/** THE POLES ARE CALCULATED EACH TIME TO GIVE DESIRED             **/
/** CUTOFF FREQUENCY.  FILTER IS IMPLEMENTED WITH 1 OR 2 CASCADED  **/
/** 2ND ORDER SECTIONS.                                            **/
/********************************************************************/
/********************************************************************/

void vp_flthp (float xbuf[], float fsamp, float fcut, float rloff, int ilp)
{

   int    i;
   double omega, om2, den, del11, del12, del21, del22,
          sum1, sum2, w, rscal, c1, c2, gains, del1, del2;
   double r[2], a1[2], a2[2], gain[2];

   r[0] = 0.765;
   r[1] = 1.848;

/* FIRST CALCULATE ANALOG FREQ. CORRESPONDING TO
   DESIRED DIGITAL FILTER CUTOFF ("PREWARP").    */

   omega = 2.0 * tan ((double)(fcut * PI / fsamp));

   if (rloff != 0.0)
   {

/* USE THE 4TH ORDER FILTER. */

/* ADJUST THE CUTOFF FREQ. SO FCUT IS ONLY -1.5 dB
   (NECESSARY SINCE WE FILTER TWICE)               */

      omega = 0.8952 * omega;
      om2 = omega * omega;
      for(i = 0; i < 2; i++)
      {
      den = 4.0 + 2.0 * omega * r[i] + om2;
         a1[i] = (8.0 - 2.0 * om2) / den;
         a2[i] = - (4.0 - 2.0 * r[i] * omega + om2) / den;
         gain[i] = 4.0 / den;
      }

/* INITIALIZE */

      del11 = 0;
      for(i = ilp-1; i >= ilp-4; i--)
      del11 = del11 + xbuf[i];
      del11 = del11 * 0.25;
      del12 = del11;
      del21 = del11;
      del22 = del11;

/* NOW APPLY FILTER TO TIME-REVERSED DATA */

      for(i = ilp-1; i > 1; i--)
      {

/* FIRST 2ND-ORDER SECTION */

      sum1 = gain[0] * xbuf[i] + a1[0] * del11 + a2[0] * del12;
         w = sum1 - 2.0 * del11 + del12;
         del12 = del11;
         del11 = sum1;

/* SECOND 2ND-ORDER SECTION OPERATES ON OUTPUT OF FIRST */

      sum2 = gain[1] * w + a1[1] * del21 + a2[1] * del22;
         xbuf[i] = (float) (sum2 - 2.0 * del21 + del22);
         del22 = del21;
         del21 = sum2;

      }

/* NOW TIME REVERSE AND REFILTER */

/* INITIALIZE AGAIN */

      del11 = 0;
      for(i = 0; i < 4; i++)
         del11 = del11 + xbuf[i];
      del11 = del11 * 0.25;
      del12 = del11;
      del21 = del11;
      del22 = del11;

/* NOW APPLY FILTER */

      for(i = 0; i < ilp; i++)
      {

/* FIRST 2ND-ORDER SECTION */

      sum1 = gain[0] * xbuf[i] + a1[0] * del11 + a2[0] * del12;
         w = sum1 - 2.0 * del11 + del12;
         del12 = del11;
         del11 = sum1;

/* SECOND 2ND-ORDER SECTION OPERATES ON OUTPUT OF FIRST */

      sum2 = gain[1] * w + a1[1] * del21 + a2[1] * del22;
         xbuf[i] = (float) (sum2 - 2.0 * del21 + del22);
         del22 = del21;
         del21 = sum2;

      }

      return;

   }

   else

   {

/* HERE IS THE 2ND ORDER FILTER */

      rscal = 1.4142;

/* AGAIN, ADJUST OMEGA SO FCUT CORRESP. TO -1.5dB */

      omega = 0.8014 * omega;
      om2 = omega * omega;
      den = 4.0 + 2.0 * omega * rscal + om2;
      c1 = (8.0 - 2.0 * om2) / den;
      c2 = - (4.0 - 2.0 * rscal * omega + om2) / den;
      gains = 4.0 / den;

/* NOW APPLY FILTER TO TIME REV. DATA */

      del1 = 0.5 * (xbuf[ilp] + xbuf[ilp-1]);
      del2 = del1;

      for(i = ilp-1; i >= 0; i--)
      {
      sum1 = gains * xbuf[i] + c1 * del1 + c2 * del2;
         xbuf[i] = (float) (sum1 - 2.0 * del1 + del2);
         del2 = del1;
         del1 = sum1;
      }

      del1 = 0.5 * (xbuf[0] + xbuf[1]);
      del2 = del1;

      for(i = 1; i <= ilp; i++)
      {
      sum1 = gains * xbuf[i] + c1 * del1 + c2 * del2;
         xbuf[i] = (float) (sum1 - 2.0 * del1 + del2);
         del2 = del1;
         del1 = sum1;
      }

   return;

   }

}



/*******************************************************/
/*******************************************************/
/**    Heart filter                                   **/
/**                                                   **/
/**   xbuf: **rdata                                   **/
/**   ndatapoints: n. of points in the current sample **/
/**   pretr: info.ntppre                              **/
/**   ch_list: list of channels                       **/
/**   nchan: number of channels                       **/
/*******************************************************/
/*******************************************************/

void lm_heart_filter (float **xbuf, char *filename, int ndatapoints, int offset,
                 ch_info *ch, int nch)
{

   FILE       *fp_in;
   header640  info;
   int        i, j, js, k, ks, ke, seg_start[4096], ich, ch_list[640],
              itri, itri_start, itri_end;

   float      *adata[640], *xbuf_filt[640], dot;

   header640  vp_read_header(FILE *, char *);


/**************************************************/
/*  Read versors from .hrt file and put in adata  */
/**************************************************/

/*  Open file and read info  */
   fp_in = fopen(filename, "rb");                 /*  Open file  */
   if (fp_in == NULL)
   {
      fprintf(stderr, "\n ERROR ! Can't open data file %s\n", filename);
      return;
   }
   info = vp_read_header(fp_in, filename);         /*  Read header  */

/***********************/
/*  Allocate memory    */
/***********************/

   for (i=0; i<nch; i++)
   {
      adata[i] = (float *)malloc(info.ntpch * sizeof(float));
      if (adata[i] == NULL)
      {
         fprintf(stderr, "\n ERROR!  can't allocate buffer memory");
         exit(-1);
      }
      xbuf_filt[i] = (float *)malloc(ndatapoints * sizeof(float));
      if (xbuf_filt[i] == NULL)
      {
         fprintf(stderr, "\n ERROR!  can't allocate buffer memory");
         exit(-1);
      }
   }


/************************/
/*  Find channel list   */
/************************/

/* Find channel list on .hrt file by matching channel type and number  */
   for (ich=0; ich<nch; ich++)
   {
      ch_list[ich] = 1;         /*  Initialize to channel 1, the electric heart channel) */
      for (j=0; j<info.nchan; j++)
      if ( (info.ch[j].number == ch[ich].number) && (info.ch[j].type == ch[ich].type) )
         ch_list[ich] = j + 1;
   }

/*******************************/
/*  Read data and close file   */
/*******************************/

   i = vp_read_data(adata, info, nch, ch_list, 0, info.ntpch, fp_in);

   fclose(fp_in);


/********************/
/*  Set xbuf_filt   */
/********************/

   for (ich=0; ich<nch; ich++)
   {
      for (j=0; j<ndatapoints; j++)
        xbuf_filt[ich][j] = xbuf[ich][j];
      vp_bandpass_filter(xbuf_filt[ich], ndatapoints, info.smpfq, 0.0, 2.0);
   }

/***********************/
/*  Go with filter !!  */
/***********************/

/*  Build seg_start including pretrigger  */
   for (itri=0; itri<info.nsmpl; itri++)
      seg_start[itri] = (info.smpl[itri].start-info.smpl[itri].ntppre);


/*  Find first and last trigger within the data segment  */
   itri = 0;
   while (seg_start[itri] < offset)
      itri++;
   itri_start = itri;

   while ( (seg_start[itri] < (offset+ndatapoints)) && (itri < info.nsmpl) )
      itri++;
   itri_end = itri-1;


/***************************************/
/*  Clean first segment (if possible)  */
/***************************************/

   if (itri_start > 0)       /* Il primo pezzo si puo' pulire solo se esiste un trigger precedente  */
   {
      ks = offset - seg_start[itri_start-1];
      if (ks < info.ntpch)   /* e solo se questo trigger e' vicino al successivo  */
      {
         ke = seg_start[itri_start] - seg_start[itri_start-1];
         if (ndatapoints < (ke-ks))     /*  First segment is also the last one !!  */
            ke = (offset + ndatapoints) - seg_start[itri_start-1];
         if (ke > info.ntpch) ke = info.ntpch;
         js = 0;

         for (ich=0; ich<nch; ich++)
         {
           if (ch_list[ich] > 1)
		   {

/*  Find data projection on mean ....  */
              dot = 0;
              j   = js;
              for (k=ks; k<ke; k++)
              {
                dot += xbuf_filt[ich][j]*adata[ich][k];
                j++;
              }

/*  Subtract projection from data  */
              j = js;
              for (k=ks; k<ke; k++)
              {
                xbuf[ich][j] -= adata[ich][k]*dot;
                j++;
              }
            }
		 }
      }
   }


/********************************************************************/
/*  Loop over different segments, starting from first complete one  */
/********************************************************************/

   for (itri=itri_start; itri<=itri_end; itri++)
   {

/*  Set segment limits  */
      ks = 0;
      js = seg_start[itri] - offset;

      if (itri == itri_end)
        ke = (offset + ndatapoints) - seg_start[itri];     /*  Last segment  */
      else
        ke = seg_start[itri+1] - seg_start[itri];          /*  Central segment  */

      if (ke > info.ntpch) ke = info.ntpch;

      for (ich=0; ich<nch; ich++)
      {
         if (ch_list[ich] > 1)
		 {

/*  Find data projection on mean ....  */
            dot = 0;
            j   = js;
            for (k=ks; k<ke; k++)
            {
              dot += xbuf_filt[ich][j]*adata[ich][k];
              j++;
            }

/*  Subtract projection from data  */
            j = js;
            for (k=ks; k<ke; k++)
            {
              xbuf[ich][j] -= adata[ich][k]*dot;
              j++;
            }
		 }
      }
   }


/************************************************/
/*  Free memory and return to calling function  */
/************************************************/

   for (i=0; i<nch; i++)
   {
      free (adata[i]);
      free (xbuf_filt[i]);
   }


   return;
}
