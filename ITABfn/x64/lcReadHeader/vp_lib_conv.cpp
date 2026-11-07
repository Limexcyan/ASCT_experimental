/*****************************************/
/*  ViP library  - conversion utilities  */
/*                                       */
/*  by Vittorio Pizzella                 */
/*                                       */
/*  Version 14.0.2                       */
/*                                       */
/*  Last revision:  Feb 2, 2003          */
/*                                       */
/*****************************************/

/****************************************************************************/
/*  Library for biomag programs. Data storage conversion utilities          */
/*                                                                          */
/*  header640  vp_swap_header640(header640)     Swap header                 */
/*  header     vp_swap_header256(header)                                    */
/*  old_header vp_swap_old_header(old_header)                               */
/*  float      float_rtea2ieee(char *)          Float rtea --> ieee         */
/*  float      *float_ieee2rtea(float)          Float ieee --> rtea         */
/*  short      vp_swap_short(short)             Swap single word            */
/*  int        vp_swap_int(int)                                             */
/*  float      vp_swap_float(float)                                         */
/*  void       vp_swap_array4(void *, int)      Swap array of 4bytes word   */
/*  void       vp_swap_array2(void *, int)      Swap array of 2bytes word   */
/*                                                                          */
/*  short      short_pc2ieee(char *)            short int pc --> ieee       */
/*  void       vp_swapw(char *, char *, int)                                */
/*                                                                          */
/****************************************************************************/

#include <stdarg.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
// #include "vp_biomag.h" Riccardo Navarra (test)
#include "lc_support.h"


/******************************************/
/******************************************/
/**  Reverse bytes on header structure   **/
/******************************************/
/******************************************/


header vp_swap_header256(header info_sw)
{
   int     i;
   header  info;

   void vp_swap_array4(void *, int);

/* Copy structure */
   info = info_sw;

/* Swap first part */
   vp_swap_array4((void *)&info.nchan, 281);

/* Take care of channel information */
   for (i=0; i<info.nchan; i++)
   {
      info.ch[i].number = vp_swap_int(info.ch[i].number);
      vp_swap_array4( (void *)&info.ch[i].amvbit, 2);
      vp_swap_array4( (void *)&info.ch[i].ncoils, 71);
   }

/* Sample list and other stuff */
   vp_swap_array4( (void *)&info.r_center.comp[0], 21031);

/* Template info */
   vp_swap_array4( (void *)&info.source_files[0], 100);

   return(info);
}


/*********************************************/
/*********************************************/
/**  Reverse bytes on header640 structure   **/
/*********************************************/
/*********************************************/

header640 vp_swap_header640(header640 info_sw)
{
   int        i;
   header640  info;

   void vp_swap_array4(void *, int);


/* Copy structure */
   info = info_sw;

/* Swap subject info */
   vp_swap_array4((void *)&info.sub_info.height, 5);

/* Swap data acquisition info */
   vp_swap_array4((void *)&info.nchan, 21168);

/* Swap data acquisition info, 2nd part */
   vp_swap_array4((void *)&info.header_size, 6);

/* Swap channel information vector */
   for (i=0; i<info.nchan; i++)
   {
      info.ch[i].number = vp_swap_int(info.ch[i].number);
      vp_swap_array4( (void *)&info.ch[i].amvbit, 2);
      vp_swap_array4( (void *)&info.ch[i].ncoils, 71);
   }

/* Swap sensor position and other stuff */
   vp_swap_array4( (void *)&info.r_center.comp[0], 766);

   return(info);
}



/******************************************************/
/******************************************************/
/**  Reverse bytes on old header structure in order  **/
/**  to use it on PC running DOS/Windows.            **/
/******************************************************/
/******************************************************/

old_header vp_swap_old_header(old_header info_sw)
{
   old_header  info;

   void vp_swap_array4(void *, int);

/* Copy structure */
   info = info_sw;

/* Swap first part */
   vp_swap_array4((void *)&info.nchan, 2580);

/* Cup informations */
   vp_swap_array4((void *)&info.cup_vertex_center, 7);

/* Last part */
   vp_swap_array4((void *)&info.r_center.comp[0], 712);

   return(info);
}



/*****************************************************/
/*****************************************************/
/**  Convert floating point variable from HP rte_a  **/
/**  data format to IEEE data format.               **/
/*****************************************************/
/*****************************************************/

float float_rtea2ieee(char *pts)
{
   unsigned char   exponent;
   unsigned int    mantissa;
   unsigned int    old, neww;
   unsigned short  ilow, ihig;

/*************************************************/
/* Build number from low and high word to avoid  */
/* alignement problems.                          */
/*************************************************/

   ihig = *(unsigned short *)pts;
   ilow = *(unsigned short *)(pts+2);
   old  = ( ((int)ihig<<16) | (int)ilow );

/*******************/
/*  If 0  exit     */
/*******************/

   if (old==0) return(0);

/*******************/
/*  Find exponent  */
/*******************/

   exponent = (old & 0x000000FE) >> 1;       /*  get exponent      */
   if ( (old & 0x00000001) == 1)             /*  if negative  ...  */
     exponent--;                             /*  subtract 1        */
   else                                      /*  otherwise    ...  */
     exponent += 127;            /*  add 127 to use offset binary  */
                                 /*  instead of 2's complement     */

   exponent--;                   /*  subtract 1 because of the implicit 1 */

/******************/
/* Find mantissa  */
/******************/

   mantissa = (old & 0x7FFFFF00) >> 8;       /*  get mantissa  */
   mantissa = (mantissa & 0x003FFFFF);       /*  clear most significant bit ... */
   mantissa = mantissa << 1;                 /*  and shift back 1 bit because   */
                                             /*  of the implicit 1             */

   if ( (old>>31) == 1)                      /*  if negative ...      */
      mantissa = (mantissa ^ 0x007FFFFF) + 1;/*  take 2's complement  */

/******************/
/*  Build number  */
/******************/

   neww = (old & 0x80000000);                 /*  sign of mantissa  */
   neww = (neww | mantissa);
   neww = (neww | (exponent<<23));

   return(*((float *)(&neww)));

}



/******************************************************/
/******************************************************/
/**  Convert floating point variable from IEEE data  **/
/**  format to HP rte_a data format.                 **/
/**  Data is returned as undigned int.               **/
/******************************************************/
/******************************************************/

unsigned int float_ieee2rtea(float number)
{
   unsigned char   exponent, sign_exponent;
   unsigned int    mantissa;
   unsigned int    old, newb;

/********************/
/*  Convert to int  */
/********************/

   old = *((int *)(&number));

/*****************/
/*  If 0 exit    */
/*****************/

   newb  = 0;
   if (old==0) return(newb);

/*******************/
/*  Find exponent  */
/*******************/

   exponent = (old & 0x7F800000) >> 23;      /*  get exponent    */
   exponent++;                               /*  add 1 because of the implicit 1  */
   if ( exponent > 127)                      /*  if positive ...  */
   {
      exponent -=127;                        /*  subtract 127  */
      sign_exponent  = 0;                    /*  set sign of exponent to 0  */
   }
   else                                      /*  else ...  */
   {
      exponent ++;                           /*  add 1  */
      sign_exponent  = 1;                    /*  set sign of exponent to 1  */
   }

/******************/
/* Find mantissa  */
/******************/

   mantissa = (old & 0x007FFFFF);             /*  get mantissa               */
   if ( number < 0. )                         /*  if negative ...            */
      mantissa = (mantissa ^ 0x007FFFFF) + 1; /*  take 2's complement        */
   mantissa = mantissa >> 1;                  /*  shift right 1 bit because  */
                                              /*  of the implicit 1          */
   mantissa = (mantissa | 0x00400000);        /*  add the implicit 1         */


/******************/
/*  Build number  */
/******************/

   newb = (old & 0x80000000);                 /*  sign of mantissa  */
   newb = (newb | (mantissa<<8));
   newb = (newb | (exponent<<1));
   newb = (newb | sign_exponent);              /*  sign of exponent  */

   return(newb);
}


/******************************************************************/
/******************************************************************/
/**  Swap array of four byte elements. Swap is done in place     **/
/**                                                              **/
/**  void *data   array to be swapped                            **/
/**  int   n      number of four bytes elements to be swapped    **/
/**                                                              **/
/******************************************************************/
/******************************************************************/

void vp_swap_array4(void *data, int n)
{
   int   i, nbyte;
   char  byte_0, byte_1, byte_2, byte_3;

   nbyte = n*4;
   for (i=0; i<nbyte; i+=4)
   {
      byte_0 = ((char *)data)[i];
      byte_1 = ((char *)data)[i+1];
      byte_2 = ((char *)data)[i+2];
      byte_3 = ((char *)data)[i+3];

      ((char *)data)[i]    = byte_3;
      ((char *)data)[i+1]  = byte_2;
      ((char *)data)[i+2]  = byte_1;
      ((char *)data)[i+3]  = byte_0;
   }
   return;
}


/*****************************************************************/
/*****************************************************************/
/**  Swap array of two byte elements. Swap is done in place     **/
/**                                                             **/
/**  void *data   array to be swapped                           **/
/**  int   n      number of two bytes elements to be swapped    **/
/**                                                             **/
/*****************************************************************/
/*****************************************************************/

void vp_swap_array2(void *data, int n)
{
   int   i, nbyte;
   char  byte_0, byte_1;

   nbyte = n*2;
   for (i=0; i<nbyte; i+=2)
   {
      byte_0 = ((char *)data)[i];
      byte_1 = ((char *)data)[i+1];

      ((char *)data)[i]    = byte_1;
      ((char *)data)[i+1]  = byte_0;
   }
   return;
}


/*******************************/
/*******************************/
/**  Swap short (integer*2)   **/
/*******************************/
/*******************************/
short vp_swap_short(short in_short)
{
   unsigned char    byte_0, byte_1;
   short            out_short;

/* divide number into two bytes  */
   byte_0 = (unsigned char)(in_short & 0x00FF);
   byte_1 = (unsigned char)((in_short & 0xFF00) >> 8);

/* build new number swapping the two bytes  */
   out_short =  (byte_0 << 8) | (byte_1 << 0);

   return(out_short);
}


/*******************************/
/*******************************/
/**   Swap int (integer*4)    **/
/*******************************/
/*******************************/
int vp_swap_int(int in_int)
{
   unsigned char    byte_0, byte_1, byte_2, byte_3;
   int              out_int;

/* divide number into four bytes  */
   byte_0 = (unsigned char)(in_int & 0x000000FF);
   byte_1 = (unsigned char)((in_int & 0x0000FF00) >> 8);
   byte_2 = (unsigned char)((in_int & 0x00FF0000) >> 16);
   byte_3 = (unsigned char)((in_int & 0xFF000000) >> 24);

/* build new number swapping the four bytes  */
   out_int =   (int)(byte_0 << 24) | (int)(byte_1 << 16)
          | (int)(byte_2 << 8)  | (int)(byte_3);

   return(out_int);
}


#if 0
/******************************/
/******************************/
/**   Swap float (real*4)    **/
/******************************/
/******************************/
float vp_swap_float(float in_float)
{
   unsigned char    byte_0, byte_1, byte_2, byte_3;
   int              out_int;

/* divide number into four bytes  */
   byte_0 = (unsigned char)(i & 0x000000FF);
   byte_1 = (unsigned char)((i & 0x0000FF00) >> 8);
   byte_2 = (unsigned char)((i & 0x00FF0000) >> 16);
   byte_3 = (unsigned char)((i & 0xFF000000) >> 24);

/* build new number swapping the two bytes  */
   out_int =   (int)(byte_0 << 24) | (int)(byte_1 << 16)
          | (int)(byte_2 << 8)  | (int)(byte_3);

   return(out_float);
}
#endif




/* Codice obsoleto, da spostare  */


/****************************************************/
/*  Convert integer*2 variable from PC data format  */
/*  to HP-UX IEEE data format (swap bytes).         */
/****************************************************/

short short_pc2ieee(char *pts)
{
   unsigned char    byte_1, byte_2;
   short            new_byte;

/* divide number into two bytes  */
   byte_1 = *(unsigned char *)(pts);
   byte_2 = *(unsigned char *)(pts+1);

/* build new number swapping the two bytes  */
   new_byte =  byte_2;
   new_byte =  new_byte | (short)(byte_1 << 8);

   return(new_byte);
}


/***************/
/*  Swap word  */
/***************/

void vp_swapw(char *in, char *out, int n)
{
   int   i;
   char  byte_0, byte_1, byte_2, byte_3;

   for (i=0; i<n; i+=4)
   {
      byte_0 = in[i];
      byte_1 = in[i+1];
      byte_2 = in[i+2];
      byte_3 = in[i+3];

      out[i]   = byte_3;
      out[i+1] = byte_2;
      out[i+2] = byte_1;
      out[i+3] = byte_0;
   }
   return;
}


/****************/
/*  Swap bytes  */
/****************/

void vp_swapb(char *in, char *out, int n)
{
   int   i;
   char  byte_0, byte_1;

   for (i=0; i<n; i+=2)
   {
      byte_0 = in[i];
      byte_1 = in[i+1];

      out[i]   = byte_1;
      out[i+1] = byte_0;
   }
   return;
}


int int_pc2ieee(int i)
{
   int            j;
   unsigned char  byte_0, byte_1, byte_2, byte_3;

/* divide number into four bytes  */
   byte_0 = (unsigned char)(i & 0x000000FF);
   byte_1 = (unsigned char)((i & 0x0000FF00) >> 8);
   byte_2 = (unsigned char)((i & 0x00FF0000) >> 16);
   byte_3 = (unsigned char)((i & 0xFF000000) >> 24);

/* build new number swapping the two bytes  */
   j =   (int)(byte_0 << 24) | (int)(byte_1 << 16)
        | (int)(byte_2 << 8)  | (int)(byte_3);

   return(j);
}

