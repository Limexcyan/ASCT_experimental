/****************************************************************************/
/*  ViP library  - file utilities                                           */
/*                                                                          */
/*  by Vittorio Pizzella                                                    */
/*                                                                          */
/*  May 24, 2003 - 14.2.1                                                   */
/*  May 24, 2003 - 14.3.0    Added vp_read_data_flag                        */
/*  Feb 08, 2008 - 14.3.1    vp_find_filename: corrected bug (file no = 0   */
/*                           causes incorrect output)                       */
/*  Sep 17, 2008 - 14.3.2    vp_read_data_flag: write % read progression    */
/*                                                                          */
/****************************************************************************/

/****************************************************************************/
/*  Library for biomag programs. File utilities                             */
/*                                                                          */
/*  void  vp_find_filename(char *, char *, char *, char *name, int,         */
/*                         char *, int)      Find filename according to     */
/*                                            vp_biomag conventions         */
/*  int   vp_file_exist(char *file)          Test if a file already exists  */
/*  void  vp_get_filename(char *, char *)    Isolate file name              */
/*  void  vp_get_filepath(char *, char *)    Isolate file path              */
/*  void  vp_get_extension(char *, char *)   Isolate file extension         */
/*  int   vp_get_filenumber(char *)          Get file number                */
/*  void  vp_get_filename_noext(char *, char *)   Isolate file name without */
/*                                                extension                 */
/*  int   vp_read_data(void *, header640, int, int *, int, int, file *)     */
/*                                           Read data from file            */
/*  int   vp_read_ch(void *, header640, int, int, int, file *)              */
/*                                           Read single ch data from file  */
/*  int   vp_read_data_flag(int *, header640, int, int, int, file *)        */
/*                                           Read single ch flag data data  */
/*                                                                          */
/*  int   vp_read_data_short(float **, header640, int, int *, int,          */
/*                           int, FILE *)    Read data from file (short)    */
/*  int   vp_read_data_int(float **, header640, int, int *, int,            */
/*                           int, FILE *)    Read data from file (int)      */
/*  int   vp_read_data_float (float **, header640, int, int *, int,         */
/*                           int, FILE *)    Read data from file (float)    */
/*                                                                          */
/****************************************************************************/

#include <stdarg.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
// #include "vp_biomag.h" Riccardo Navarra (test)
#include "lc_support.h"

#if WIN_32
   #include <io.h>
#endif



/*************************************************************/
/*************************************************************/
/**  Find file path and name.                               **/
/**  - If extension is NULL use the existing one (if any).  **/
/**  - If number<0 don't change name.                       **/
/**  - If number>0 and name-lenght <= 6 append to name      **/
/**    number (2 digits).                                   **/
/**  - If number>0 and name-lenght > 6 replace last two     **/
/**    digits of name with number.                          **/
/*************************************************************/
/*************************************************************/

void vp_find_filename(char *filename, char *path_root, char *path_raw, char *name,
                      int number, char *extension, int ext_number)
{
   char lpath[256], temp[3], lext[16], lname[256], *ptr;
   int  len;

/*  Get file path and name on local variables  */

   vp_get_filepath(lpath, name);
   vp_get_filename(lname, name);

/*********************/
/*  Build extension  */
/*********************/

/* Look for extension. If present copy to ext and remove it from name */
/* If extension is simply a dot, remove it.                           */
   ptr = strrchr(lname, '.');
   if (ptr != NULL)
   {
      strcpy(lext, ptr);
      *ptr = '\0';
   }
   if (strcmp(lext, ".") == 0)
      strcpy(lext, "");

/* If extension is present and is not mhd override ext */

   if (extension != NULL)
   {
       if (strncmp(extension, "mhd", 3) == 0 )
          strcat(lext, ".mhd");
       else
       {
         strcpy(lext, ".");
         strcat(lext, extension);
       }
   }

/*  if ext_number > 0 add two digit number to extension  */
   if ((ext_number >= 0) && (ext_number <= 99))
   {
      sprintf(temp, "%.2d", ext_number);
      strcat(lext, temp);
   }


/**********************/
/*  Build data path   */
/**********************/

/*  If data path is explicitely stated in filename, use stated path (no matter what) */

   if (strcmp(lpath, "") == 0)
   {
      if ( (strncmp(lext+strlen(lext)-4, ".raw", 4) == 0) || (*lext == '\0') )
         strcpy(lpath, path_raw);                           /*  raw files  */
      else
         strcpy(lpath, path_root);                          /*  all but raw files  */

      if ((lpath[strlen(lpath)-1] != '/') && (lpath[strlen(lpath)-1] != '\\'))
	     strcat(lpath, "/"); 
 
	  if (strlen(lname) < 11)
         strncat(lpath, lname, 6);
      else
         strncat(lpath, lname, 11);
   }

 /* If last character is not a slash or backslash, add it to lpath */
  if ((lpath[strlen(lpath)-1] != '/') && (lpath[strlen(lpath)-1] != '\\'))
	   strcat(lpath, "/"); 
  
/*********************/
/*  Build file name  */
/*********************/

   len = strlen(lname);
   if (number < 0)
      strcpy(filename, lname);
   else if (len <= 6 && number >= 0)
   {
      strcpy(filename, lname);
      sprintf(temp, "%.2d", number);
      strcat(filename, temp);
   }
   else if (len > 6 && number >= 0)
   {
      lname[len-2] = '\0';           /*  Cut last two characters in name  */
      strcpy(filename, lname);
      sprintf(temp, "%.2d", number);
      strcat(filename, temp);
   }
   strcpy(lname, filename);

/************************************/
/*  Build complete file descriptor  */
/************************************/

   strcpy(filename, lpath);
   strcat(filename, lname);
   strcat(filename, lext);

   return;
}


/***********************************/
/***********************************/
/**   File name utilities         **/
/***********************************/
/***********************************/

/*  Get filename extension  */
void vp_get_extension(char *filename, char *file_in)
{
   char *ptr;

   ptr = strrchr(file_in, '.');
   if (ptr != NULL)
      strcpy(filename, ++ptr);
   else
      strcpy(filename, file_in);
   return;
}


/*  Get file number  */
int vp_get_filenumber(char *file_in)
{
   int  number;
   char filename[256], *ptr;

   vp_get_filename_noext(filename, file_in);
   ptr = filename;
   ptr = ptr + (strlen(filename) - 2);
   number = atoi(ptr);

   return(number);
}


/*  Get filename without path and extension  */
void vp_get_filename_noext(char *filename, char *file_in)
{
   char *ptr;

   vp_get_filename(filename, file_in);
   ptr = strchr(filename, '.');
   if (ptr != NULL)
      *ptr = '\0';
   return;
}


/*  Get filename without path  */
void vp_get_filename(char *filename, char *file_in)
{
   char *ptr, *ptr1, *ptr2;

   ptr  = strrchr(file_in, '/');
   ptr2 = strrchr(file_in, '\\');
   ptr1 = strrchr(file_in, ':');

   if (ptr != NULL)
      strcpy(filename, ++ptr);
   else if(ptr2 != NULL)
      strcpy(filename, ++ptr2);
   else if (ptr1 != NULL)
      strcpy(filename, ++ptr1);
   else
      strcpy(filename, file_in);

   return;
}


/*  Get path without filename */
void vp_get_filepath(char *pathname, char *filename)
{
   char *ptr, *ptr1, *ptr2, lname[256];

   strcpy(lname, filename);
   ptr  = strrchr(lname, '/');
   ptr2 = strrchr(lname, '\\');
   ptr1 = strrchr(lname, ':');

   if (ptr != NULL)
   {
      if (strcmp(ptr, lname) == 0)
      {
        ptr++;
        *ptr = '\0';
      }
      else
        *ptr = '\0';
        strcpy(pathname, lname);
   }
   else if (ptr2 != NULL)
   {

      if (strcmp(ptr2, lname) == 0)
      {
        ptr2++;
        *ptr2 = '\0';
      }
      else
        *ptr2 = '\0';
        strcpy(pathname, lname);

   }
   else if (ptr1 != NULL)
   {
      ptr1++;
      *ptr1 = '\0';
      strcpy(pathname, lname);
   }
   else
      strcpy(pathname, "");

   return;
}




/****************************************************************************/
/****************************************************************************/
/**  Test if a file already exists.  If file exists return  TRUE = 1, if   **/
/**  not return FALSE = 0                                                  **/
/****************************************************************************/
/****************************************************************************/

int vp_file_exist(char *file) // MODIFIED
{
#if WIN_32
   long fp;
   _finddata_t data;
#else
   FILE *fp;
#endif


#if WIN_32
   fp = _findfirst(file, &data);
   if(fp==-1) return 0;
   _findclose(fp);
#else
   fp = fopen(file, "rb");
   if (fp == NULL)
      return(0);
   fclose(fp);
#endif
   
   return(1);

}



/*******************************************************/
/*******************************************************/
/**  Read data of a single channel from a file.       **/
/**  This routine is actually calling vp_read_data.   **/
/*******************************************************/
/*******************************************************/

int vp_read_ch(float *data, header640 info, int ichan, int offset, int ntp, FILE *file)
{
   int   lchan[1];
   float *local_data[1];

   local_data[0] = data;
   lchan[0]      = ichan;

   return(vp_read_data(local_data, info, 1, lchan, offset, ntp, file));
}



/*********************************************************************/
/*********************************************************************/
/**  Read data from a file. Channel number to be read starts from 1 **/
/**                                                                 **/
/**  data     ** data out                                           **/
/**  info     header640                                             **/
/**  nchan    number of channels to read  (nchan<0 => all channels) **/
/**  ch_list  list of channels                                      **/
/**  offset   starting sample to read (used only for raw data read) **/
/**  ntp      number of time points to read for each channel        **/
/**  file     * stream to read from                                 **/
/*********************************************************************/
/*********************************************************************/

int vp_read_data(float **data, header640 info, int nchan, int *ch_list,
                 int offset, int ntp, FILE *file)

{
   int    i, ii, ntps, npt, ich, type, file_pos, local_ch_list[640];
   short  *sbuffer;
   int    *ibuffer;

   float  fact;

/****************************************/
/*   Immediate exit on data type error  */
/****************************************/

   if (info.data_type == 7)
   {
     fprintf(stderr, "\n ERROR! RTE_A float data reader not implemented");
     return(0);
   }
   if (info.data_type == 8)
   {
     fprintf(stderr, "\n ERROR! Please be patient, ASCII data reader still not implemented");
     return(0);
   }
   if ((info.data_type < 0) || (info.data_type > 8))
   {
     fprintf(stderr, "\n ERROR! Unknown data type. Code: %d", info.data_type);
     return(0);
   }

/*****************************************/
/*   Create the local list of channels   */
/*****************************************/

   if (nchan<=0)
   {
      nchan = info.nchan;
      for (ich=0; ich<nchan; ich++)
         local_ch_list[ich] = ich + 1;
   }
   else
   {
      for (ich=0; ich<nchan; ich++)
         local_ch_list[ich] = ch_list[ich];
   }


/******************************************/
/*  Go to specific data reader functions  */
/******************************************/

/***************************/
/*  Read multiplexed data  */
/***************************/
   if (info.multiplexed_data == TRUE)
   {

     if ((info.data_type == 0) || (info.data_type == 3) || (info.data_type == 6))
       ii = vp_read_data_short(data, info, nchan, local_ch_list, offset, ntp, file);
     if ((info.data_type == 1) || (info.data_type == 4))
       ii = vp_read_data_int(data, info, nchan, local_ch_list, offset, ntp, file);
     if ((info.data_type == 2) || (info.data_type == 5))
       ii = vp_read_data_float(data, info, nchan, local_ch_list, offset, ntp, file);

     npt = ii;
   }

/*****************************/
/*  Read demultiplexed data  */
/*****************************/

   if (info.multiplexed_data == FALSE)
   {

/*  short  */
     if ((info.data_type == 0) || (info.data_type == 3) || (info.data_type == 6))
     {
         if (info.ave_alignement == TRUE)
            ntps = (int)((info.ntpch + 63) / 64) * 64;
         else
            ntps = info.ntpch;

         if (ntp<=0 || ntp>info.ntpch) ntp = info.ntpch;

         sbuffer = (short *)malloc(ntp * sizeof(short));
         if (sbuffer == NULL)
         {
            fprintf(stderr, "\n ERROR! Not enough memory for data transfer\n");
            return(0);
         }

         for (ich=0; ich<nchan; ich++)
         {
            file_pos = info.start_data + (offset+(local_ch_list[ich]-1) * ntps) * sizeof(short);
            ii = fseek(file, file_pos, 0);
            if (ii != 0)
               fprintf(stderr, "\n ERROR! fseek failed to position file pointer (pos: %d)", file_pos); // WARNING
            ii = fread(sbuffer, sizeof(short), ntp, file);

            if ( ( (LE_CPU == TRUE)  && (info.data_type == 0) ) ||
                 ( (LE_CPU == FALSE) && (info.data_type == 3) ) ||
                 ( (LE_CPU == TRUE)  && (info.data_type == 6) )    )
                   vp_swap_array2((void *)sbuffer, ntp);	                
	    
	        for (i=0; i<ntp; i++)
               data[ich][i] = (float)sbuffer[i];
         }

         free(sbuffer);
     }

/*  int  */
     if ((info.data_type == 1) || (info.data_type == 4))
     {
         if (info.ave_alignement == TRUE)
            ntps = (int)((info.ntpch + 63) / 64) * 64;
         else
            ntps = info.ntpch;

         if (ntp<=0 || ntp>info.ntpch) ntp = info.ntpch;

         ibuffer = (int *)malloc(ntp * sizeof(int));
         if (ibuffer == NULL)
         {
            fprintf(stderr, "\n ERROR! Not enough memory for data transfer\n");
            return(0);
         }

         for (ich=0; ich<nchan; ich++)
         {
            file_pos = info.start_data + (offset+(local_ch_list[ich]-1) * ntps) * sizeof(int);
            ii = fseek(file, file_pos, 0);
            if (ii != 0)
               fprintf(stderr, "\n ERROR! fseek failed to position file pointer (pos: %d)", file_pos);
            ii = fread(ibuffer, sizeof(int), ntp, file);

            if ( ( (LE_CPU == TRUE)  && (info.data_type == 1) ) ||
                 ( (LE_CPU == FALSE) && (info.data_type == 4) )    )
                   vp_swap_array4((void *)ibuffer, ntp);	    
            
	    for (i=0; i< ntp; i++)
               data[ich][i] = (float)ibuffer[i];
         }

         free(ibuffer);
     }

/*  float  */
     if ((info.data_type == 2) || (info.data_type == 5))
     {
        if (info.ave_alignement == TRUE)
            ntps = (int)((info.ntpch + 63) / 64) * 64;
         else
            ntps = info.ntpch;

         if (ntp<=0 || ntp>info.ntpch) ntp = info.ntpch;
         for (ich=0; ich<nchan; ich++)
         {
            file_pos = info.start_data + (offset+(local_ch_list[ich]-1) * ntps) * sizeof(float);
            ii = fseek(file, file_pos, 0);
            if (ii != 0)
               fprintf(stderr, "\n ERROR! fseek failed to position file pointer (pos: %d)", file_pos);
            ii = fread(((float *)data[ich]), (unsigned int)sizeof(float), (unsigned int)ntp, file);
            i  = ferror(file);
            i  = feof(file);

            if ( ( (LE_CPU == TRUE)  && (info.data_type == 2) ) ||
                 ( (LE_CPU == FALSE) && (info.data_type == 5) )    )
                   vp_swap_array4((void *)data[ich], ntp);
         }
     }

     npt = ii;
   }


/********************************/
/*  Calibrate data (if needed)  */
/********************************/

   if (info.rawfile == TRUE)
   {

      for (ich=0; ich<nchan; ich++)
      {

        type  = info.ch[local_ch_list[ich] - 1].type;
        fact  = info.ch[local_ch_list[ich] - 1].amvbit / info.ch[local_ch_list[ich] - 1].calib;

        if ( ((type == 2) || (type == 8)) && (info.raw_header_type == 2) )
          fact *= 1000;               /*  Historical reasons (sigh!)  */

        if ((type == 32) || (type == 128) || (type == 64))                 /*  Parameter channels have no calibration  */
          fact = 1;

        for (i=0; i<npt; i++)
           data[ich][i] = data[ich][i] * fact;
     }
   }

  return(npt);
}




/**************************************/
/**************************************/
/**   Read short data from a file.   **/
/**************************************/
/**************************************/

int vp_read_data_short(float **data, header640 info, int nchan, int *ch_list,
                       int offset, int ntp, FILE *file)
{

   int     i, ii, np, ie, ich, totpt, bufpt, maxbuf, maxntp, data_size;
   long    file_pos;
   short   *buffer;

   data_size = sizeof(short);

/***************************/
/*  Position file pointer  */
/***************************/

   if (offset < 0)                   offset = 0;
   if (offset > (info.ntpdata-ntp))  offset = info.ntpdata - ntp;
   file_pos  = info.start_data;
   file_pos += info.nchan*offset * data_size;

   ii = fseek(file, file_pos, 0);
   if (ii != 0)
      fprintf(stderr, "\n ERROR! fseek failed to position file pointer (pos: %d)", file_pos);

/********************************************************************/
/*  Get temporary buffer. If buffer is larger than MAXBUFFER, loop  */
/********************************************************************/

   maxbuf = MAXBUFFER * 1024 * 1024 / data_size ;
   maxntp = maxbuf / info.nchan;

   totpt  = ntp * info.nchan;

   if (totpt > maxbuf)
      bufpt = maxntp * info.nchan;
   else
      bufpt = totpt;

   buffer = (short *)malloc(bufpt * data_size);
   if (buffer == NULL)
   {
      fprintf(stderr, "\n ERROR! Not enough memory for data transfer\n");
      return(0);
   }

/****************/
/*  Read data   */
/****************/

   offset = 0;
   ii     = 0;
   np     = 0;
   while (offset < totpt)
   {
      if ( (totpt-offset) < bufpt)
       bufpt = totpt-offset;

/*  read data from file  */
      ii += fread(buffer, data_size, bufpt, file);

/*  swap data (if needed)  */
      if (    ((LE_CPU == TRUE) && ((info.data_type == 0) || (info.data_type == 6)))
           || ((LE_CPU == FALSE) && (info.data_type == 3))                      )
              vp_swap_array2((void *)buffer, bufpt);

/*  Store in matrix data as int  */
      for (ich=0; ich<nchan; ich++)
      {
        ie = bufpt/info.nchan;
        for (i=0; i<ie; i++)
          data[ich][np+i] = (float)buffer[i*info.nchan+ch_list[ich]-1];
      }
      np = np + ie;
      offset += bufpt;
   }
   free(buffer);

   ii = ii / info.nchan;
   if ( ii != ntp )
       fprintf(stderr, "\n ERROR! fread failed to get all requested data (req: %d, got: %d)",
             ntp, ii);

   return(ii);
}


/************************************/
/************************************/
/**   Read int data from a file.   **/
/************************************/
/************************************/

int vp_read_data_int(float **data, header640 info, int nchan, int *ch_list,
                 int offset, int ntp, FILE *file)
{

   int     i, ii, np, ie, ich, totpt, bufpt, maxbuf, maxntp, data_size;
   long    file_pos;
   int     *buffer;

   data_size = sizeof(int);

/***************************/
/*  Position file pointer  */
/***************************/

   if (offset < 0)                   offset = 0;
   if (offset > (info.ntpdata-ntp))  offset = info.ntpdata - ntp;
   file_pos  = info.start_data;
   file_pos += info.nchan*offset * data_size;

   ii = fseek(file, file_pos, 0);
   if (ii != 0)
      fprintf(stderr, "\n ERROR! fseek failed to position file pointer (pos: %d)", file_pos);

/********************************************************************/
/*  Get temporary buffer. If buffer is larger than MAXBUFFER, loop  */
/********************************************************************/

   maxbuf = MAXBUFFER * 1024 * 1024 / data_size ;
   maxntp = maxbuf / info.nchan;

   totpt  = ntp * info.nchan;

   if (totpt > maxbuf)
      bufpt = maxntp * info.nchan;
   else
      bufpt = totpt;

   buffer = (int *)malloc(bufpt * data_size );
   if (buffer == NULL)
   {
      fprintf(stderr, "\n ERROR! Not enough memory for data transfer\n");
      return(0);
   }

/****************/
/*  Read data   */
/****************/

   offset = 0;
   ii     = 0;
   np     = 0;
   while (offset < totpt)
   {
      if ( (totpt-offset) < bufpt)
       bufpt = totpt-offset;

/*  read data from file  */
      ii += fread(buffer, data_size, bufpt, file);

/*  swap data (if needed)  */
      if (    ((LE_CPU == TRUE)  && (info.data_type == 1))
           || ((LE_CPU == FALSE) && (info.data_type == 4))  )
              vp_swap_array4((void *)buffer, bufpt);

/*  Store in matrix data as float  */
      for (ich=0; ich<nchan; ich++)
      {
        ie = bufpt/info.nchan;
        for (i=0; i<ie; i++)
          data[ich][np+i] = (float)buffer[i*info.nchan+ch_list[ich]-1];
      }
      np = np + ie;
      offset += bufpt;
   }
   free(buffer);

   ii = ii / info.nchan;
   if ( ii != ntp )
       fprintf(stderr, "\n ERROR! fread failed to get all requested data (req: %d, got: %d)",
             ntp, ii);

   return(ii);
}



/*************************************/
/*************************************/
/**  Read float data from a file.   **/
/*************************************/
/*************************************/

int vp_read_data_float(float **data, header640 info, int nchan, int *ch_list,
                 int offset, int ntp, FILE *file)
{

   int     i, ii, np, ie, ich, totpt, bufpt, maxbuf, maxntp, data_size;
   long    file_pos;
   float   *buffer;

   data_size = sizeof(float);

/***************************/
/*  Position file pointer  */
/***************************/

   if (ntp>info.ntpdata) ntp = info.ntpdata;

   if (offset < 0)                   offset = 0;
   if (offset > (info.ntpdata-ntp))  offset = info.ntpdata - ntp;
   file_pos  = info.start_data;
   file_pos += info.nchan*offset * data_size;

   ii = fseek(file, file_pos, 0);
   if (ii != 0)
      fprintf(stderr, "\n ERROR! fseek failed to position file pointer (pos: %d)", file_pos);

/********************************************************************/
/*  Get temporary buffer. If buffer is larger than MAXBUFFER, loop  */
/********************************************************************/

   maxbuf = MAXBUFFER * 1024 * 1024 / data_size ;
   maxntp = maxbuf / info.nchan;

   totpt  = ntp * info.nchan;

   if (totpt > maxbuf)
      bufpt = maxntp * info.nchan;
   else
      bufpt = totpt;

   buffer = (float *)malloc(bufpt * data_size );
   if (buffer == NULL)
   {
      fprintf(stderr, "\n ERROR! Not enough memory for data transfer\n");
      return(0);
   }

/****************/
/*  Read data   */
/****************/

   offset = 0;
   ii     = 0;
   np     = 0;
   while (offset < totpt)
   {
      if ( (totpt-offset) < bufpt)
       bufpt = totpt-offset;

/*  read data from file  */
      ii += fread(buffer, data_size, bufpt, file);

/*  swap data (if needed)  */
      if (    ((LE_CPU == TRUE)  && (info.data_type == 2))
           || ((LE_CPU == FALSE) && (info.data_type == 5))  )
              vp_swap_array4((void *)buffer, bufpt);

/*  Store in matrix data as float  */
      for (ich=0; ich<nchan; ich++)
      {
        ie = bufpt/info.nchan;
     for (i=0; i<ie; i++)
          data[ich][np+i] = buffer[i*info.nchan+ch_list[ich]-1];
      }
      np = np + ie;
      offset += bufpt;
   }
   free(buffer);

   ii = ii / info.nchan;
   if ( ii != ntp )
       fprintf(stderr, "\n ERROR! fread failed to get all requested data (req: %d, got: %d)",
             ntp, ii);

   return(ii);
}


/*********************************************************************/
/*********************************************************************/
/**  Read FLAG data from file. Use this only to read FLG channel    **/
/**  from a rawfile                                                 **/
/**                                                                 **/
/**  data     *data out as int                                      **/
/**  info     header640                                             **/
/**  ch       flag channel to be read                               **/
/**  offset   starting sample to read                               **/
/**  ntp      number of time points to read for each channel        **/
/**  file     * stream to read from                                 **/
/*********************************************************************/
/*********************************************************************/

int vp_read_data_flag(int *idata, header640 info, int ich, int offset,
					  int ntp, FILE *file)
{

   int     i, ii, np, ie, totpt, bufpt, maxbuf, maxntp, data_size;
   long    file_pos;
   void    *buffer;

/**********************/
/*  Check if rawfile  */
/**********************/
   
   if ( (info.multiplexed_data != TRUE) || (info.rawfile != TRUE) )
   {
      fprintf(stderr, "\n ERROR in vp_read_data_flag! Only multiplexed file allowed");
	  return (0);
   }

/*********************/
/*  Check data type  */
/*********************/

   data_size = 0;

   if ((info.data_type == 0) || (info.data_type == 3) || (info.data_type == 6))
     data_size = sizeof(short);
   if ((info.data_type == 1) || (info.data_type == 4))
     data_size = sizeof(int);

   if (data_size == 0)
   {
     fprintf(stderr, "\n ERROR in vp_read_data_flag! Illegal data type (%d)", info.data_type);
	 return (0);
   }


/************************/
/*  Check other inputs  */
/************************/

   if ((ich < 1) || (ich > info.nchan))
   {
     fprintf(stderr, "\n ERROR in vp_read_data_flag! Illegal ch number (%d)", ich);
	 return (0);
   }

/***************************/
/*  Position file pointer  */
/***************************/

   if (offset < 0)                   offset = 0;
   if (offset > (info.ntpdata-ntp))  offset = info.ntpdata - ntp;
   file_pos  = info.start_data;
   file_pos += info.nchan*offset * data_size;

   ii = fseek(file, file_pos, 0);
   if (ii != 0)
      fprintf(stderr, "\n ERROR! fseek failed to position file pointer (pos: %d)", file_pos);

/********************************************************************/
/*  Get temporary buffer. If buffer is larger than MAXBUFFER, loop  */
/********************************************************************/

   maxbuf = MAXBUFFER * 1024 * 1024 / data_size ;
   maxntp = maxbuf / info.nchan;

   totpt  = ntp * info.nchan;

   if (totpt > maxbuf)
      bufpt = maxntp * info.nchan;
   else
      bufpt = totpt;

   buffer = (void *)malloc(bufpt * data_size);
   if (buffer == NULL)
   {
      fprintf(stderr, "\n ERROR! Not enough memory for data transfer\n");
      return(0);
   }

/****************/
/*  Read data   */
/****************/

   offset = 0;
   ii     = 0;
   np     = 0;

   while (offset < totpt)
   {
      if ( (totpt-offset) < bufpt)
       bufpt = totpt-offset;

/*  read data from file  */
      fprintf(stdout, " %d%% ", (int)(100*(float)offset/(float)totpt) );
      ii += fread(buffer, data_size, bufpt, file);

/*  swap data (if needed)  */
      if (    ((LE_CPU == TRUE)  && (info.data_type == 1))
           || ((LE_CPU == FALSE) && (info.data_type == 4))  )
              vp_swap_array4((void *)buffer, bufpt);

/*  Store in idata as int  */
      ie = bufpt/info.nchan;

      if (data_size == 2)
        for (i=0; i<ie; i++)
          idata[np+i] = ((short *)buffer)[i*info.nchan+(ich-1)];
      else
        for (i=0; i<ie; i++)
          idata[np+i] = ((int *)buffer)[i*info.nchan+(ich-1)];

      np = np + ie;
      offset += bufpt;
   }
   free(buffer);

   ii = ii / info.nchan;
   if ( ii != ntp )
       fprintf(stderr, "\n ERROR! fread failed to get all requested data (req: %d, got: %d)",
             ntp, ii);

   return(ii);
}