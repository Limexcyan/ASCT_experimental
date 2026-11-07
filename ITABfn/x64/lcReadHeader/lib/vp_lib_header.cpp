/*************************************************************************/
/*  ViP library  - header utilities                                      */
/*                                                                       */
/*  by Vittorio Pizzella                                                 */
/*                                                                       */
/*  Dec 08, 2007 - 14.0.3    vp_read_atb_header: FLG ch number           */
/*                           General cleanup                             */
/*  Jan 12, 2008 - 14.1.0    vp_read_atb_header: added FLG calibration   */
/*  Jan 17, 2008 - 14.1.1    vp_read_atb_header: added FLG_002 channel   */
/*                                               as default trigger      */
/*  Mar 08, 2009 - 14.2.0    Added vp_read_bmdsys_header                 */
/*  Jun 12, 2009 - 14.3.0    Fixed several bugs on vp_read_bmdsys_header */
/*                                                                       */
/*************************************************************************/

/******************************************************************************/
/*  Library for biomag programs. Header utilities                             */
/*                                                                            */
/*  header    vp_read_info(FILE *, char *)    Read VP_BIOMAG header           */
/*  header640 vp_read_header(FILE *, char *)  Read VP_BIOMAG header640        */
/*  header    vp_read_old_header(FILE *)      Read old header                 */
/*                                                                            */
/*  header640 vp_read_ge_header(FILE *)       Read GE runfile header640       */
/*  header640 vp_read_atb_header(FILE *)      Read ATB runfile header640      */
/*  header640 vp_read_ifn_header(FILE *)      Read IFN runfile header640      */
/*                                                                            */
/*  header640 vp_header_to_header640(header)  Translate header into header640 */
/*                                                                            */
/*  int       vp_setchtype(char *)            Find channel type from standard */
/*                                            label (IFN header)              */
/*                                                                            */
/******************************************************************************/

#include <stdarg.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>
// #include "vp_biomag.h" Riccardo Navarra (test)
#include "lc_support.h"


/************************/
/************************/
/**  Read INFO header  **/
/************************/
/************************/

header640 vp_read_header(FILE *file, char *fname)
{
   char        info_rtea[1536], line[256], line_1[256], line_2[256];
   header      info256;
   header640   info640, info_mhd;
   short       rtea_test;
   int         header_type, le_data;

/********************/
/*  Clear headers   */
/********************/
   memset(&info256, '\0', sizeof(header));
   memset(&info640, '\0', sizeof(header640));

/**********************/
/*  Find header type  */
/**********************/

   rewind(file);
   fread(info_rtea, sizeof(char), 1536, file);
   rewind(file);

   if (lc_parse(info_rtea,1536,"sSs",line,line_1,line_2)) 
	   printf("Errore nel parsing dell'header...");

   rtea_test = *(short *)(info_rtea+148);
   le_data = TRUE;                                    /*  Default little endian  */
   if (LE_CPU)
      rtea_test = vp_swap_short(rtea_test);

   if (strcmp(line, "BIOMAG_RUNFILE") == 0)
      header_type = 3;
   else if ( (strcmp(line, "FORMAT:") == 0) && (strcmp(line_1, "ATB-BIOMAGDATA") == 0) )
      header_type = 31;
   else if ( (strcmp(line, "[HeaderType]") == 0) && (strcmp(line_1, "FORMAT=DM1.0") == 0) )
      header_type = 41;
   else if ( (strcmp(line, "FORMAT:") == 0) && (strcmp(line_1, "BMDSYS-Apollo55") == 0) )
      header_type = 51;
   else if (strcmp(line, "VP_BIOMAG") == 0)
   {
      if (strcmp(line_1, "2.0") != 0)
      {
         header_type = 10;                             /*  256ch header  */
         le_data = FALSE;
      }
      else
      {
         header_type = 20;                             /*  640ch header  */
         le_data = TRUE;
         if (strcmp(line_2, "BE") == 0)
           le_data = FALSE;
      }
   }
   else {
		if (rtea_test == 768)
   {
      header_type = 2;
      le_data = FALSE;
   }
   else
      header_type = 1;

      return(info640);

   }
/**********************************/
/*  Read VP_BIOMAG header 640 ch  */
/**********************************/

   if ((header_type == 20) || (header_type == 21))
   {
      fread(&info640, sizeof(header640), 1, file);   /*  read data            */
      if ((info640.nchan > 1024) || (info640.nchan < 0))
         info640 = vp_swap_header640(info640);       /*  swap if needed       */
   }

/**********************************/
/*  Read VP_BIOMAG header 256 ch  */
/**********************************/

   if ((header_type == 10) || (header_type == 11))
   {
      fread(&info256, sizeof(header), 1, file);      /*  read data            */
      if ((info256.nchan > 1024) || (info256.nchan < 0))
         info256 = vp_swap_header256(info256);       /*  swap if needed       */
      info256.start_data = info256.header_size;      /*  on 256ch header force start_data to be equal to header_size  */ 
	  info640 = vp_header_to_header640(info256);     /*  convert to info640   */
      strcpy(info640.stendian, "LE");                /*  update some info's   */
   }

/*****************************/
/*  Read IFN header (ASCII)  */
/*****************************/

   if (header_type == 41)
      info640 = vp_read_ifn_header640(file);

/****************************/
/*  Read GE header (ASCII)  */
/****************************/

   if (header_type == 3)
      info640 = vp_read_ge_header640(file);

/*****************************************/
/*  Read ATB-BIOMAGDATA header (ASCII)   */
/*****************************************/

   if (header_type == 31)
      info640 = vp_read_atb_header640(file);

/*********************************/
/*  Read BMDSYS header (ASCII)   */
/*********************************/

   if (header_type == 51)
      info640 = vp_read_bmdsys_header640(file);

/**********************/
/*  Read old_header   */
/**********************/

   if (header_type == 1)
      info640 = vp_read_old_header640(file);

/***********************/
/*  Read rte_a header  */
/***********************/

   if (header_type == 2)
   {
      info640 = vp_read_rtea_header640(file);
      info640.raw_header_type = 2;
      strcpy(info640.stendian, "LE");
   }

/*********************************************************/
/*  Check if raw file, if yes try to read master header  */
/*********************************************************/

   if ((info640.rawfile == TRUE) && (info640.data_type != 6) && ((info640.header_type != 11) || (info640.header_type != 21)) )   
   {

      info_mhd = vp_read_mhd(fname);

/*  Master header found. Check if compatible with raw file header  */
      if (strcmp(info_mhd.stname, "VP_BIOMAG") == 0)
      {

         if ( (info_mhd.nchan      == info640.nchan    ) &&
              (info_mhd.nelech     == info640.nelech   ) &&
              (info_mhd.nmagch     == info640.nmagch   ) &&
              (info_mhd.nmagrefch  == info640.nmagrefch) &&
              (info_mhd.ntpdata/(int)4096 == info640.ntpdata/(int)4096) ) 
            return(info_mhd);
         else
           fprintf(stderr, "\n ERROR ! Master header is not compatible with raw file. Returning header from raw file.");
      }
      else
         fprintf(stderr, "\n WARNING ! No master header found. \n");
   }

   strcpy(info640.stver, "2.0");
   strcpy(info640.stname, "VP_BIOMAG");
   return(info640);
}



/**************************/
/**************************/
/**  Read master header  **/
/**************************/
/**************************/

header640 vp_read_mhd(char *fname)
{
   FILE        *fp_in;
   char        file_in[256], env_path_root[256], env_path_raw[256],
               filename[256], filepath[256];
   char        strnull[2];

   char        inidir[256];

   header      info256;
   header640   info640;
   int         len, le_data, ii;

   iniFileStruct *ifs;

/*  Clear header  */
   memset(&info640, '\0', sizeof(header640));
   memset(&info256, '\0', sizeof(header));

/*  Check environment  */

#if WIN_32
   if (getenv("HOME")!=NULL)
      strcpy(inidir,getenv("HOME"));
   else if (getenv("USERPROFILE")!=NULL)
      strcpy(inidir,getenv("USERPROFILE"));
   else if ((getenv("HOMEDRIVE")!=NULL) && (getenv("HOMEPATH")!=NULL))
      strcpy(inidir,getenv("USERPROFILE"));
   else
      strcpy(inidir,"");
#else
   if (getenv("HOME")!=NULL)
      strcpy(inidir,getenv("HOME"));
   else
      strcpy(inidir,"");
#endif

   if (checkDir(inidir[strlen(inidir)-1])) inidir[strlen(inidir)-1] = 0;
     ifs = lc_iniOpen(strcat(inidir,"/browser.ini"),INI_READ);

   if (ifs==NULL)
   {

/* search in global dir */

      strcpy(inidir,_ROOT);
      strcat(inidir,"config");
      ifs = lc_iniOpen(strcat(inidir,"/browser.ini"),INI_READ);

      if (ifs==NULL){
         fprintf(stderr, "\n ERROR !  Configuration file not found.");
         return(info640);
      }
      
   }

   if (lc_iniReadValue(ifs,"paths","data_root",INI_STRING,env_path_root)==NULL)
       strcpy(env_path_root,_DATA_ROOT);
         
   if (lc_iniReadValue(ifs,"paths","raw_data",INI_STRING,env_path_raw) == NULL)
       strcpy(env_path_raw,_DATA_RAW);

   lc_iniClose(ifs);

   if (checkDir(env_path_root[strlen(env_path_root)-1])) env_path_root[strlen(env_path_root)-1] = 0;
   if (checkDir(env_path_raw[strlen(env_path_raw)-1])) env_path_raw[strlen(env_path_raw)-1] = 0;

/*************************************************************************/
/*  Try to read master_header in the following directories:              */
/*    1st choice  -  Same directory as processed files  (.ave files)     */
/*    2nd choice  -  Same directory as raw files  (.raw files)           */
/*    3rd choice  -  Specific directory for master headers               */
/*************************************************************************/

   vp_get_filename_noext(filename, fname);                       /*  First choice  */
   vp_find_filename(file_in, env_path_root, strnull, filename, -1, "ave", -1);
   len = strlen(file_in);
   file_in[len-4] = '\0';
   strcat(file_in, ".raw.mhd");

   if (vp_file_exist(file_in) == FALSE)
   {
      strcpy(file_in, fname);                                    /*  Second choice  */
      vp_get_filepath(filepath, fname);
      if (strcmp(filepath, "") == 0)
      {
         strcpy(filepath, env_path_raw);
      strcat(filepath, "/");
      strcat(filepath, fname);
      strcpy(file_in, filepath);
      }
      strcat(file_in, ".mhd");
   }

   if (vp_file_exist(file_in) == FALSE)
   {                                                              /*  Third choice  */
      vp_find_filename(file_in, env_path_root, strnull, filename, -1, "mhd", -1);
   }

/*********************************/
/*  Open and read master_header  */
/*********************************/

   fp_in = fopen(file_in, "rb");
   if (fp_in == NULL)
      return(info640);          /* No master header found */

/************************************************************************/
/*  Master header is a VP_BIOMAG header, but version must be assessed.  */
/*  This is done by reading the file as header640, if stver is 2.0 or   */
/*  greater, header format is header640.                                */  
/************************************************************************/

   ii = fread(&info640, sizeof(header640), 1, fp_in);

   if ( ( strcmp(info640.stver, "2.0") == 0 ) && (ii == 1) )
   {
     le_data = FALSE;
     if (strcmp(info640.stendian, "LE") == 0)
        le_data = TRUE;
     if ((info640.nchan>1024) || (info640.nchan<0)) /*  test if swap needed  */
      info640 = vp_swap_header640(info640);         /*  swap if needed       */
   }
   else
   {
     rewind(fp_in); 
     fread(&info256, sizeof(header), 1, fp_in);
     le_data = FALSE;
     if ((info256.nchan>1024) || (info256.nchan<0)) /*  test if swap needed  */
        info256 = vp_swap_header256(info256);       /*  swap if needed       */
     info640 = vp_header_to_header640(info256);     /*  convert to info640   */
     strcpy(info640.stendian, "LE");                /*  update some info's   */
   }

   fclose(fp_in);
   return(info640);
}


/***********************/
/***********************/
/**  Read old_header  **/
/***********************/
/***********************/

header640 vp_read_old_header640(FILE *file)
{
   char        line[16];
   old_header  info_old;
   header      info;
   header640   info640;
   int         i, j, type, number, ch_list[640];

   vp_vector   temp_pos;
   old_header  vp_swap_old_header(old_header);
   header640   vp_header_to_header640(header);


/*  Read header from file  */
   rewind(file);
   fread(&info_old, sizeof(old_header), 1, file);

   if ((info_old.nchan > 1024) || (info_old.nchan < 0))
      info_old = vp_swap_old_header(info_old);

/**************************************/
/*  Translate old_header into header  */
/**************************************/

   for (i=0; i<16; i++)
      info.first_name[i] = info_old.lname[i];
   for (i=0; i<16; i++)
      info.last_name[i] = info_old.fname[i];
   strcpy(info.id, "");
   strcpy(info.notes, "");

   strncpy(info.time, info_old.date, 10);
   info.time[11] = '\0';
   strncpy(info.date, &info_old.date[10], 14);
   info.date[15] = '\0';
   info.nchan  = info_old.nchan;
   if ((info_old.iftyp > 0) && (info_old.iftyp < 7))
     info.data_type = 0;                                /*  0 - IEEE_SHORT  */
   else
     info.data_type = 1;                                /*  1 - IEEE_FLOAT  */
   info.acq_type = info_old.iaqty;
   info.smpfq    = (float)info_old.ismpfq;
   info.low_fr   = info_old.low_fr;
   info.hig_fr   = info_old.hig_fr;
   info.nsamp    = info_old.nsamp;
   info.ntpsmp   = info_old.ntpsmp;
   info.ntpdata  = info.nsamp * info.ntpsmp;
   info.nrefchan = 0;
   for (i=0; i<256; i++)
      info.ref_ch[i] = 0;
   info.ntpref   = 0;
   info.header_size = info_old.header_size;
   info.header_type = 0;
   info.start_reference = 0;
   info.start_data = info_old.header_size;
   info.irev  = info_old.irev;
   info.iftyp = info_old.iftyp;
   if ((info.iftyp == 0) || (info.iftyp == 6) || (info.iftyp == 7))
      info.rawfile = 1;
   else
      info.rawfile = 0;
   info.isns  = info_old.isns;

/*  Set sensor and channel position  */

   info.r_center       = info_old.r_center;
   info.u_center       = info_old.u_center;
   temp_pos            = vp_car2sph(info.u_center);
   info.th_center      = temp_pos.comp[1];
   info.fi_center      = temp_pos.comp[2];
   info.rotation_angle = info_old.rotation_angle;

   for (i=0; i<info.nchan; i++)
   {
      type   = (int)(info_old.ch_type[i] / 100);

      if ((type == 2) || (type == 3))                            /* Handle magnetic channels */
      {
         number = (int) fmod( (float)info_old.ch_type[i], (float)200);
         info.ch[i]        = vp_get_ch_info(number, 2, info.isns, info.date);
         info.ch[i].flag   = info_old.ch_flag[i];
         info.ch[i].amvbit = info_old.amvbit;
         info.ch[i].calib  = info_old.ch_calb[i];

         for (j=0; j<info.ch[i].ncoils; j++)
         {
           info.ch[i].pos[j].r_s = vp_Sp2S(info.ch[i].pos[j].r_s,
                                           info.r_center.comp[0], info.r_center.comp[1], info.r_center.comp[2],
                                           info.th_center, info.fi_center, info.rotation_angle);
           info.ch[i].pos[j].u_s = vp_Sp2S(info.ch[i].pos[j].u_s,
                                           0., 0., 0.,
                                           info.th_center, info.fi_center, info.rotation_angle);
         }
      }

      if (type == 1)                                              /* Handle electric channels */
      {
         number = (int)fmod((float)info_old.ch_type[i], (float)100);
         info.ch[i]        = vp_get_ch_info(number, 1, info.isns, info.date);
         info.ch[i].flag   = info_old.ch_flag[i];
         info.ch[i].amvbit = info_old.amvbit;
         info.ch[i].calib  = info_old.ch_calb[i];
         if (info.ch[i].calib == 0.001)                          /* TTL Trigger channel */
         {
            info.ch[i].type   = 16;
            strcpy(info.ch[i].label, "AUX_");
            sprintf(line, "%d", number);
            strcat(info.ch[i].label, line);
         }
      }
   }

/*  Count number of channels of each type  */

   info.nelech    = vp_get_channel_number(info, ch_list, 1+256);
   info.nmagch    = vp_get_channel_number(info, ch_list, 2+256);
   info.nelerefch = vp_get_channel_number(info, ch_list, 4+256);
   info.nmagrefch = vp_get_channel_number(info, ch_list, 8+256);
   info.nauxch    = vp_get_channel_number(info, ch_list, 16+256);
   info.nparamch  = vp_get_channel_number(info, ch_list, 32+256);

   for (i=0; i<3; i++)
     info.cosdir[i] = info_old.cosdir[i];

   info.num_markers = info_old.num_markers;
   for(i=0; i<info.num_markers; i++)
   {
     info.i_coil[i]     = info_old.i_coil[i];
     info.marker[i].r_s = info_old.marker[i].r_s;
     info.marker[i].u_s = info_old.marker[i].u_s;
   }
   info.best_chi    = info_old.best_chi;
   info.zpos_nasion = info_old.zpos_nasion;

   info.cup_vertex_center   = info_old.cup_vertex_center;
   info.cup_fi_center       = info_old.cup_fi_center;
   info.cup_rotation_angle  = info_old.cup_rotation_angle;
   info.dist_a1_a2          = info_old.dist_a1_a2;
   info.dist_inion_nasion   = info_old.dist_inion_nasion;
   info.max_circ            = info_old.max_circ;
   info.nasion_vertex_inion = info_old.nasion_vertex_inion;

   info.security = 0;
   info.itri     = info_old.itri;
   info.ntpch    = info_old.ntpch;
   info.ntppre   = info_old.ntppre;
   info.navrg    = info_old.navrg;
   info.nover    = info_old.nover;

   info.stdev     = info_old.stdev;
   info.bas_start = info_old.bas_start;
   info.bas_end   = info_old.bas_end;

   info.nsmpl = 0;
   for(i=0; i<32; i++)
      info.source_files[i] = info_old.source_files[i];

   info.ichtpl   = info_old.ichtpl;
   info.ntptpl   = info_old.ntptpl;
   info.ifitpl   = info_old.ifitpl;
   info.corlim   = info_old.corlim;
   info.tpl_filt = info_old.tpl_filt;

   info640 = vp_header_to_header640(info);     /*  convert to info640   */
   return(info640);
}



/*************************/
/*************************/
/**  Read rte_a header  **/
/*************************/
/*************************/

header640 vp_read_rtea_header640(FILE *file)
{
   char        info_rtea[1536], line[16];
   header      info;
   header640   info640;
   int         i, type, number, ch_list[256], ismpfq, nchan, swap;
   float       amvbit;

   int         int_pc2ieee(int);
   header640   vp_header_to_header640(header);

/***************************/
/*  Initialize info block  */
/***************************/

   memset(&info, '\0', sizeof(header));

/***************************/
/*  Read rte_a INFO block  */
/***************************/

   rewind(file);
   fread(info_rtea, sizeof(char), 1536, file);

/*****************************/
/*  Find if swap is needed   */
/*****************************/

   nchan = (int)*(short *)(info_rtea+80);
   if ((nchan > 1024) || (nchan < 0))
     swap = TRUE;
   else
     swap = FALSE;


/***********************************************************/
/*  Convert a rte_a INFO block into the header structure   */
/*  using natural alignement.                              */
/*  All short integers are converted to standard int.      */
/***********************************************************/

   for (i=0; i<15; i++) info.first_name[i] =  *(info_rtea+i);
   info.first_name[15] = '\0';
   for (i=0; i<15; i++) info.last_name[i] =  *(info_rtea+16+i);
   info.last_name[15] = '\0';
   strcpy(info.id, "");
   strcpy(info.notes, "");
   for (i=0; i<10; i++) info.time[i] =  *(info_rtea+58+i);
   info.time[10] = '\0';
   for (i=0; i<13; i++) info.date[i] =  *(info_rtea+68+i);
   info.date[13] = '\0';

   if (swap == TRUE)
   {
      info.nchan    = (int)vp_swap_short(*(short *)(info_rtea+80));
      info.itri     = (int)vp_swap_short(*(short *)(info_rtea+86));
      info.acq_type = (int)vp_swap_short(*(short *)(info_rtea+88));
      ismpfq        = (int)vp_swap_short(*(short *)(info_rtea+90));
      info.nsamp    = (int)vp_swap_short(*(short *)(info_rtea+92));
      info.ntpsmp   = (int)vp_swap_short(*(short *)(info_rtea+98));
      info.ntpch    = (int)vp_swap_short(*(short *)(info_rtea+126));
      info.ntppre   = (int)vp_swap_short(*(short *)(info_rtea+128));
      info.navrg    = (int)vp_swap_short(*(short *)(info_rtea+138));
      info.nover    = (int)vp_swap_short(*(short *)(info_rtea+140));
      info.irev     = (int)vp_swap_short(*(short *)(info_rtea+230));
      info.iftyp    = (int)vp_swap_short(*(short *)(info_rtea+234));
      info.isns     = (int)vp_swap_short(*(short *)(info_rtea+246));
   }
   else
   {
      info.nchan    = (int)*(short *)(info_rtea+80);
      info.itri     = (int)*(short *)(info_rtea+86);
      info.acq_type = (int)*(short *)(info_rtea+88);
      ismpfq        = (int)*(short *)(info_rtea+90);
      info.nsamp    = (int)*(short *)(info_rtea+92);
      info.ntpsmp   = (int)*(short *)(info_rtea+98);
      info.ntpch    = (int)*(short *)(info_rtea+126);
      info.ntppre   = (int)*(short *)(info_rtea+128);
      info.navrg    = (int)*(short *)(info_rtea+138);
      info.nover    = (int)*(short *)(info_rtea+140);
      info.irev     = (int)*(short *)(info_rtea+230);
      info.iftyp    = (int)*(short *)(info_rtea+234);
      info.isns     = (int)*(short *)(info_rtea+246);
   }
   info.data_type = 6;
   info.smpfq     =  (float)ismpfq;
   if (swap == TRUE)
        vp_swapb(info_rtea+284, info_rtea+284, 8);
   info.low_fr  = float_rtea2ieee(info_rtea+284);
   info.hig_fr  = float_rtea2ieee(info_rtea+288);

/*  This header part is taken from file  */

   info.ntpdata     = info.nsamp * info.ntpsmp;
   info.rawfile     = TRUE;
   info.header_size = 1536;
   info.header_type = 2;

   info.start_reference = 0;
   info.start_data      = 1536;

   info.nrefchan = 0;
   for (i=0; i<256; i++)
      info.ref_ch[i] = 0;
   info.ntpref   = 0;

/*  Set amvbit, all channels have the same value  */
   if (swap == TRUE)
      vp_swapb(info_rtea+100, info_rtea+100, 4);         
   amvbit = float_rtea2ieee(info_rtea+100);

   for (i=0; i<info.nchan; i++)
   {

       if (swap == TRUE)
         number = (int)short_pc2ieee(info_rtea+384+(i*2));
       else
         number = (int)(*(short *)(info_rtea+384+(i*2)));

       type = number / 100;
       if ((type == 2) || (type == 3))                            /* Handle magnetic channels */
       {
          number = (int)fmod((float)number, (float)200);
          info.ch[i]        = vp_get_ch_info(number, 2, info.isns, info.date);
          if (swap == TRUE)
             vp_swapb(info_rtea+512+(i*4), info_rtea+512+(i*4), 4);
          info.ch[i].calib  = float_rtea2ieee(info_rtea+512+(i*4));
          info.ch[i].amvbit = amvbit;
       }
       
       if (type == 1)                                              /* Handle electric channels */
       {
          number = (int)fmod((float)number, (float)100);
          info.ch[i]        = vp_get_ch_info(number, 1, info.isns, info.date);
          info.ch[i].flag   = 0;
          if (swap == TRUE)
             vp_swapb(info_rtea+512+(i*4), info_rtea+512+(i*4), 4);
          info.ch[i].calib  = float_rtea2ieee(info_rtea+512+(i*4));
          info.ch[i].amvbit = amvbit;
          if (info.ch[i].calib == 0.001)                          /* TTL Trigger channel */
          {
             info.ch[i].type   = 16;
             strcpy(info.ch[i].label, "AUX_");
             sprintf(line, "%d", number);
             strcat(info.ch[i].label, line);
          }
      }
   }

/*  Count number of channels of each type  */

      info.nelech    = vp_get_channel_number(info, ch_list, 1+256);
      info.nmagch    = vp_get_channel_number(info, ch_list, 2+256);
      info.nelerefch = vp_get_channel_number(info, ch_list, 4+256);
      info.nmagrefch = vp_get_channel_number(info, ch_list, 8+256);
      info.nauxch    = vp_get_channel_number(info, ch_list, 16+256);
      info.nparamch  = vp_get_channel_number(info, ch_list, 32+256);

   info640 = vp_header_to_header640(info);     /*  convert to info640   */
   return(info640);
}



/*****************************************************/
/*****************************************************/
/**  Read GE runfile header into vp info structure  **/
/*****************************************************/
/*****************************************************/

header640 vp_read_ge_header640(FILE *file)
{
   char          line[256], line1[80], line2[80];
   char          *info_runfile, *ptr, *ptre, ch_list[256][64], dataword[16384];
   int           i, ich, nchan, number, nbyte_header, ndatapoints, nsegments,
                 len, year;
   long int      f_start_reference_data, f_start_segment_map, f_start_data;
   float         gain, cfact;
   header640     info;

   int           vp_parse_runfile(char *, char *, char *, ...);
   char          *vp_setpos_runfile(char *, char *);
   char          *vp_advance_ptr(char *);
 
   
   memset(&info, '\0', sizeof(header640));

/****************************/
/*  Find header dimensions  */
/****************************/

   rewind(file);
   f_start_data = ftell(file);
   while( fgets(line, 80, file) != NULL && (f_start_data == 0))
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strcmp(line1, "START_DATA") == 0)
        f_start_data = ftell(file);
   }

   rewind(file);
   f_start_reference_data = ftell(file);
   while( fgets(line, 80, file) != NULL && (f_start_reference_data == 0) && (ftell(file)<f_start_data) )
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strcmp(line1, "START_REFERENCE_DATA") == 0)
        f_start_reference_data = ftell(file);
   }

   rewind(file);
   f_start_segment_map = ftell(file);
   while( fgets(line, 80, file) != NULL && (f_start_segment_map == 0) && (ftell(file)<f_start_data) )
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strcmp(line1, "START_SEGMENT_MAP") == 0)
        f_start_segment_map = ftell(file);
   }


/*  Find header lenght  */
   nbyte_header = f_start_data;
   if ((f_start_segment_map < nbyte_header) && (f_start_segment_map > 0))
          nbyte_header = f_start_segment_map;
   if ((f_start_reference_data < nbyte_header) && (f_start_reference_data > 0))
          nbyte_header = f_start_reference_data;

   info.start_data = f_start_data;

/******************************************************/
/*   Read some inmportant info's directly from file   */
/******************************************************/

/*  Read TOTAL_OUTPUT_PACKETS  */

   rewind(file);
   ndatapoints = 0;
   while( fgets(line, 80, file) != NULL && (ndatapoints == 0) )
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strncmp(line1, "TOTAL_OUTPUT_PACKETS:", 21) == 0)
         vp_parse_runfile(line, "TOTAL_OUTPUT_PACKETS:", "%d", &ndatapoints);
   }

#if 0
/*  Read TOTAL_REFERENCE_PACKETS  */

   rewind(file);
   tot_ref_packets = 0;
   while( fgets(line, 80, file) != NULL && (tot_ref_packets == 0) )
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strncmp(line1, "TOTAL_REFERENCE_PACKETS:", 24) == 0)
         vp_parse_runfile(line, "TOTAL_REFERENCE_PACKETS:", "%d", &tot_ref_packets);
   }
#endif


/*********************/
/*  Allocate memory  */
/*********************/

   info_runfile = (char *)malloc(nbyte_header * sizeof(char));
   if (info_runfile == NULL)
   {
      fprintf(stderr, "\n ERROR in vp_read_runfile_header!  can't allocate memory");
      exit(-1);
   }

/*****************/
/*  Read header  */
/*****************/

   rewind(file);
   fread(info_runfile, sizeof(char), nbyte_header, file);

/**********************************************/
/*  Interpret header into vp info structure   */
/**********************************************/

   info.header_size = (int)f_start_data;

   strcpy(info.last_name, "LastName");
   strcpy(info.first_name, "FirstName");
   vp_parse_runfile(info_runfile, "TIME:", "%s", &info.time[0]);
   vp_parse_runfile(info_runfile, "DATE:", "%s %s %s", line, line1, line2);
   strcpy(info.date, line);
   strcat(info.date, " ");
   strcat(info.date, line1);
   strcat(info.date, " ");
   if (strcmp(line2, "97") == 0)   strcpy(line2, "1997");
   if (strcmp(line2, "98") == 0)   strcpy(line2, "1998");
   if (strcmp(line2, "99") == 0)   strcpy(line2, "1999");
   if (strcmp(line2, "100") == 0)  strcpy(line2, "2000");
   if (strcmp(line2, "101") == 0)  strcpy(line2, "2001");
   if (strcmp(line2, "102") == 0)  strcpy(line2, "2002");
   if (strcmp(line2, "103") == 0)  strcpy(line2, "2003");
   if (strcmp(line2, "104") == 0)  strcpy(line2, "2004");
   strcat(info.date, line2);

   vp_parse_runfile(info_runfile, "STORED_SAMPLE_RATE:", "%f", &info.smpfq);
   vp_parse_runfile(info_runfile, "STORED_PACKET_SIZE:", "%d", &info.nchan);
   vp_parse_runfile(info_runfile, "STORED_MAG_CHANNELS:", "%d", &info.nmagch);
   vp_parse_runfile(info_runfile, "STORED_MAG_REF_CHANNELS:", "%d", &info.nmagrefch);
   vp_parse_runfile(info_runfile, "STORED_ELECTRICAL_CHANNELS:", "%d", &info.nelech);
   vp_parse_runfile(info_runfile, "STORED_ELECTRICAL_REF_CHANNELS:", "%d", &info.nelerefch);
   vp_parse_runfile(info_runfile, "STORED_AUX_CHANNELS:", "%d", &info.nauxch);
   vp_parse_runfile(info_runfile, "STORED_PARAMETER_CHANNELS:", "%d", &info.nparamch);
   nchan = info.nmagch + info.nmagrefch + info.nelech + info.nelerefch +
           info.nauxch + info.nparamch;
   if (info.nchan != nchan)
      fprintf(stderr, "\n WARNING! Total number of channels different from the sum of all ",
                    "channels of different kind");

/* Find number of segments. If only one segment is present data is just a continuous */
/* stream as in the standard 28 channel acquisition mode.                            */
/* If more than one segment is present the stream is segmented                       */

   vp_parse_runfile(info_runfile, "NUMBER_OF_SEGMENTS:", "%d", &nsegments);
   if (nsegments < 1)
   {
      fprintf(stderr, "\n ERROR! At least one data segment must be present %d", nsegments);
      return(info);
   }

   info.data_type = 0;        /* Data type is always short, big endian  */
   info.ntpdata   = ndatapoints;
   info.itri      = 0;

   /*
   ptr = vp_setpos_runfile(info_runfile, "LOW_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.low_fr);
   ptr = vp_setpos_runfile(info_runfile, "HIGH_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.hig_fr;
   */

   info.rawfile          = TRUE;             /* Always a raw file  */
   info.multiplexed_data = TRUE;
   info.header_type      = 3;
   info.raw_header_type  = 3;

   info.isns = 55;                                    /*  Default  */
   len = strlen(info.date);
   sscanf(info.date+(len-5), "%d", &year);

   if ((info.nmagch > 100) && (year >= 2002))
      info.isns   = 154;
   else
      info.isns   = 153;

   if (info.nmagch < 100 && info.nmagch > 40)
      info.isns   = 55;

/******************/
/*  Get slot map  */
/******************/

   i = 0;
   ptr = vp_setpos_runfile(info_runfile, "START_STORED_SLOT_MAP");
   while(TRUE)
   {
      sscanf(ptr, "%s", line);
      if (strcmp(line, "END_STORED_SLOT_MAP") == 0)
       break;

      strcpy(&ch_list[i][0], line);
      i++;
      ptr = vp_advance_ptr(ptr);
   }
   if (info.nchan != i)
      fprintf(stderr, "\n ERROR. Number of channels in slot map and packet size do not match");

/******************************/
/*  Get channel informations  */
/******************************/

   ptr    = info_runfile;

   for (i=0; i<info.nchan; i++)
   {
      ptr  = vp_setpos_runfile(ptr, "START_DATA_WORD");  /*  Find data start for next channel   */
      ptre = vp_setpos_runfile(ptr, "END_DATA_WORD");    /*  Find data end for next channel     */

      strncpy(dataword, ptr, (ptre-ptr));                /*  Copy string related to examined channel  */

      vp_parse_runfile(dataword, "NAME:", "%s", line);   /*  Read channel label in runfile format */
      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;

      if (ich >= info.nchan)
      {
       fprintf(stderr, "\n ERROR! channel %s is not in slot map", line);
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      if ( (strcmp(info.ch[ich].label, "AUX_0") == 0) ||    /*  Look for trigger channel      */
         (strcmp(info.ch[ich].label, "TRIGGER") == 0) )
       info.itri = i;
      info.ch[ich].type   = vp_rnf2header(line, &number);   /*  Find channel type and number  */
      info.ch[ich].number = number;

      if (info.ch[ich].type != 32)                          /* Read UNIT label only if not PARAM */
      {
		 vp_parse_runfile(dataword, "UNITS:", "%s", line);     /*  Find unit label  */
         ptr = strchr(line, '/');                              /*  Leave out the /LSB  */
         if (ptr != NULL)
			strncpy(info.ch[ich].unit, line, (ptr-line));
         else {
	         ptr = strchr(line, '\\');                              /*  Leave out the /LSB  */
	         if (ptr != NULL)
				strncpy(info.ch[ich].unit, line, (ptr-line));
			 else
		         strcpy(info.ch[ich].unit, line);
		 }
      }

/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      vp_parse_runfile(dataword, "ORIENTATION:", "%f %f %f",
                      &info.ch[ich].pos[0].u_s.comp[0],
                      &info.ch[ich].pos[0].u_s.comp[1],
                      &info.ch[ich].pos[0].u_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Convert position to mm  */
      info.ch[ich].pos[0].r_s.comp[0] *= 10.;
      info.ch[ich].pos[0].r_s.comp[1] *= 10.;
      info.ch[ich].pos[0].r_s.comp[2] *= 10.;

/*  Check orientation for unit vector */
      cfact = (float)sqrt( info.ch[ich].pos[0].u_s.comp[0]*info.ch[ich].pos[0].u_s.comp[0] +
                           info.ch[ich].pos[0].u_s.comp[1]*info.ch[ich].pos[0].u_s.comp[1] +
                           info.ch[ich].pos[0].u_s.comp[2]*info.ch[ich].pos[0].u_s.comp[2] );
      info.ch[ich].pos[0].u_s.comp[0] /= cfact;
      info.ch[ich].pos[0].u_s.comp[1] /= cfact;
      info.ch[ich].pos[0].u_s.comp[2] /= cfact;

      gain  = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "GAIN:", "%f", &gain);
      cfact = 1.;
      vp_parse_runfile(dataword, "CONVERSION_FACTOR:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / (gain * cfact));

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptr = ptre;
   }

/*  Read sensor position  */
   ptr = vp_setpos_runfile(info_runfile, "START_PATIENT_COORDINATE_SYSTEM");
   vp_parse_runfile(ptr, "POSITION:", "%f %f %f",
                                      &info.r_center.comp[0],
                                      &info.r_center.comp[1],
                                      &info.r_center.comp[2]);
   vp_parse_runfile(ptr, "ORIENTATION:", "%f %f %f",
                                        &info.u_center.comp[0],
                                        &info.u_center.comp[1],
                                        &info.u_center.comp[2]);
   vp_parse_runfile(ptr, "TWIST:", "%f", &info.rotation_angle);




/**********************************************************************************/
/*   Check NUMBER_OF_SEGMENTS. If more than one segment is present, identify the  */
/*   starting packet of each segment by looking at time stamp.                    */
/*   Alternativamente si puo' controllare il time stamp veloce e vedere quando    */
/*   il salto e' differente dal previsto. Il problema e' sul previsto.            */
/**********************************************************************************/

#if 0
   if (nsegments > 1)
   {
      ch_timestamp = 255;

      delta      = 10000 / info.smpfq;
      nsegm      = 0;
      offset     = 0;
      info.smpl[nsegm++].start = 0;              /* Set first segment  */

      while (offset < (info.ntpdata - 1))
      {
         ndatapoints = info.ntpdata - offset;
         if (ndatapoints > 16384)
            ndatapoints = 16384;
         vp_read_ch(buffer,  info, ch_timestamp, offset, ndatapoints, file);

         for(i=0; i<(ndatapoints-1); i++)
      {
         if ( fabs((buffer[i+1] - buffer[i]) > 1) )
            info.smpl[nsegm++].start = offset + i + 1;
      }

         offset += (ndatapoints - 1);
      }

      info.nsmpl = nsegm;
      if (nsegm != nsegments)
        fprintf(stderr, "\n ERROR! No. of segments found in data is not correct (found %d, defined %d)",
          nsegm, nsegments);
      }
#endif

/***********************************************/
/*  Free memory and return to calling program  */
/***********************************************/

   free(info_runfile);
   return(info);
}



/************************************************************/
/*  Convert from runfile channel label to vp channel label  */
/************************************************************/

int vp_rnf2header(char *line, int *number)
{
   int ich, type;

   if (strncmp(line, "MAG_REF_", 8) == 0)        /*  Magnetic ref channel (type 8)  */
   {
      sscanf(line, "MAG_REF_%d", &ich);
      type    = 8;
      *number = ich;
   }
   else if (strncmp(line, "MAG_", 4) == 0)       /*  Magnetic channel (type 2)  */
   {
      sscanf(line, "MAG_%d", &ich);
      type    = 2;
      *number = ich;
   }
   else if (strncmp(line, "ELC_REF_", 8) == 0)   /*  Electric ref channel (type 4)  */
   {
      sscanf(line, "ELC_REF_%d", &ich);
      type    = 4;
      *number = ich;
   }
   else if (strncmp(line, "ELC_", 4) == 0)       /*  Electric channel (type 1)  */
   {
      sscanf(line, "ELC_%d", &ich);
      type    = 1;
      *number = ich;
   }
   else if (strncmp(line, "AUX_", 4) == 0)       /*  Auxiliary channel (type 16) */
   {
      sscanf(line, "AUX_%d", &ich);
      type    = 16;
      *number = ich;
   }
   else                                          /*  Service channel code 32   */
   {
      type    = 32;
      *number = 1;
   }

   return(type);
}




/*****************************************************************************/
/*  Find, within the string info_runfile, the position of the string token   */
/*  and set string pointer to the end of token.                              */
/*****************************************************************************/

char *vp_setpos_runfile(char *info_runfile, char *token)
{
   char *ptr;

   ptr = strstr(info_runfile, token);
   if (ptr == NULL)
   {
      fprintf(stderr, "\nERROR in vp_parse_runfile. Token %s not found in header", token);
      return(ptr);
   }
   ptr += strlen(token);

   return(ptr);
}



/*****************************************************************************/
/*  This functions parses the string info_runfile and find first occurrence  */
/*  of token. After, the next informations are read into the supplied data   */
/*  pointers according to format string, pretty much as scanf does.          */
/*  The functions returns the number of succesfully matched and assigned     */
/*  input items. Only very limited conversion specifications are recognized. */
/*  Presently legal conversion specifiers are:   %d  %f  %s                  */
/*****************************************************************************/

int vp_parse_runfile(char *info_runfile, char *token, char *format, ...)
{
   va_list ap;
   char    *p, *ptr;
   int     i;

   char    *vp_advance_ptr(char *);

   ptr = strstr(info_runfile, token);
   if (ptr == NULL)
   {
      fprintf(stderr, "\nERROR in vp_parse_runfile. Token %s not found in header", token);
      return(0);
   }
   ptr += strlen(token);

   va_start(ap, format);

   i = 0;
   for (p=format; *p!=NULL; p++)
   {

      while( (*p != '%') && (*p != NULL) )
         p++;

      p++;
      switch(*p)
      {
       case 'd':
          sscanf(ptr, "%d", va_arg(ap, int *));
          ptr = vp_advance_ptr(ptr);
          i++;
          break;
       case 'f':
          sscanf(ptr, "%f", va_arg(ap, float *));
          ptr = vp_advance_ptr(ptr);
          i++;
          break;
       case 's':
          sscanf(ptr, "%s", va_arg(ap, char *));
          ptr = vp_advance_ptr(ptr);
          i++;
          break;
       default:
          break;
      }
   }

   va_end(ap);

   return(i);
}

/*********************************************/
/*  Advance ptr to next word/number to read  */
/*********************************************/

char *vp_advance_ptr(char *ptr)
{
   char *ptr1;
   ptr1 = ptr;
   while (isgraph((int)*ptr1) == 0)           /*  Move pointer to next letter or digit  */
      ptr1++;
   while (isgraph((int)*ptr1) != 0)           /*  Skip all letters and numbers  */
      ptr1++;
   while (isgraph((int)*ptr1) == 0)           /*  Move pointer to next letter or digit  */
      ptr1++;
   return(ptr1);
}



/*********************************************************/
/*********************************************************/
/**  Read ATB_BIOMAGDATA header into vp info structure  **/
/*********************************************************/
/*********************************************************/

header640 vp_read_atb_header640(FILE *file)
{
   char          line[256], line1[256];
   char          *info_runfile, *ptr, *ptre, *ptc, *ptce, ch_list[256][64],
                 dataword[16384], unit_label[16];
   int           i, ich, nchan, number, nbyte_header, ndatapoints, 
                 tot_ref_packets, n_sens;
   long int      f_start_reference_data, f_start_data;
   float         cfact;
   header640     info;

   int           vp_parse_runfile(char *, char *, char *, ...);
   char          *vp_setpos_runfile(char *, char *);
   char          *vp_advance_ptr(char *);

   memset(&info, '\0', sizeof(header640));

/****************************/
/*  Find header dimensions  */
/****************************/

   rewind(file);
   f_start_data           = ftell(file);
   f_start_reference_data = 0;
   while( fgets(line, 80, file) != NULL && (f_start_data == 0))
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strcmp(line1, "START_DATA") == 0)
        f_start_data = ftell(file);
      if (strcmp(line1, "START_REFERENCE_DATA") == 0)
        f_start_reference_data = ftell(file);
   }

/*  Find header lenght  */
   nbyte_header = f_start_data;
   if ((f_start_reference_data < nbyte_header) && (f_start_reference_data > 0))
          nbyte_header = f_start_reference_data;

   info.start_data = f_start_data;

/*****************************************************************/
/*   First read some important info's directly from file.        */
/*   These infos need not to be placed before any data segment,  */
/*   other infos MUST be stored before data or reference_data.   */
/*****************************************************************/

/*  Read TOTAL_OUTPUT_PACKETS  */
   rewind(file);
   ndatapoints = 0;
   while( fgets(line, 80, file) != NULL && (ndatapoints == 0) )
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strncmp(line1, "TOTAL_NO_OF_PACKET:", 19) == 0)
         vp_parse_runfile(line, "TOTAL_NO_OF_PACKET:", "%d", &ndatapoints);
   }
   info.ntpdata = ndatapoints;

/*  Read TOTAL_REFERENCE_PACKETS  (if START_REFERENCE_DATA is found)  */
   if (f_start_reference_data > 0)
   {
      rewind(file);
      tot_ref_packets = 0;
      while( fgets(line, 80, file) != NULL && (tot_ref_packets == 0) )
      {
         sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
         if (strncmp(line1, "TOTAL_REFERENCE_PACKETS:", 24) == 0)
            vp_parse_runfile(line, "TOTAL_REFERENCE_PACKETS:", "%d", &tot_ref_packets);
      }
      info.ntpref = tot_ref_packets;
   }

/*********************/
/*  Allocate memory  */
/*********************/

   info_runfile = (char *)malloc(nbyte_header * sizeof(char));
   if (info_runfile == NULL)
   {
      fprintf(stderr, "\n ERROR in vp_read_runfile_header!  can't allocate memory");
      exit(-1);
   }

/*****************************/
/*  Read header as a string  */
/*****************************/

   rewind(file);
   fread(info_runfile, sizeof(char), nbyte_header, file);

/**********************************************/
/*  Interpret header into vp info structure   */
/**********************************************/

   info.header_size = (int)f_start_data;

   strcpy(info.last_name, "LastName");
   strcpy(info.first_name, "FirstName");
   vp_parse_runfile(info_runfile, "TIME:", "%s", &info.time[0]);
   vp_parse_runfile(info_runfile, "DATE:", "%s", line);
   strcpy(info.date, line);

   vp_parse_runfile(info_runfile, "STORED_SAMPLING_RATE:", "%f", &info.smpfq);
   vp_parse_runfile(info_runfile, "STORED_PKT_SIZE:", "%d", &info.nchan);
   vp_parse_runfile(info_runfile, "STORED_ELEC_CHANNELS:", "%d", &info.nelech);
   vp_parse_runfile(info_runfile, "STORED_MAG_CHANNELS:", "%d", &info.nmagch);
   vp_parse_runfile(info_runfile, "STORED_MAG_REF_CHANNELS:", "%d", &info.nmagrefch);
   vp_parse_runfile(info_runfile, "STORED_AUX_CHANNELS:", "%d", &info.nauxch);
   vp_parse_runfile(info_runfile, "STORED_DIGITAL_DATA:", "%d", &info.ndigitch);
   vp_parse_runfile(info_runfile, "STORED_FLAG_CHANNELS:", "%d", &info.nflagch);

   /*  These channel type are not defined in ATB header  */
   info.nelerefch = 0;
   info.nparamch  = 0;

   nchan = info.nelech + info.nelerefch + info.nmagch + info.nmagrefch +
           info.nauxch + info.nparamch + info.ndigitch + info.nflagch;
   if (info.nchan != nchan)
      fprintf(stderr, "\n WARNING! Total number of channels different from the sum of all ",
                    "channels of different kind");

/*  Find number of segments  */

   vp_parse_runfile(info_runfile, "NO_OF_SEGMENTS:", "%d", &info.no_segments);
   if (info.no_segments < 1)
   {
      fprintf(stderr, "\n ERROR! At least one data segment must be present %d", info.no_segments);
      return(info);
   }

   if (info.no_segments != 1)
   {
      fprintf(stderr, "\n ERROR! Only one data segment must be present %d", info.no_segments);
      return(info);
   }

/*  Identify data format  */
   vp_parse_runfile(info_runfile, "STORED_DATA_TYPE:", "%s", line);

   if ( strcmp(line, "PC16") == 0)
     info.data_type = 3;               /*  little endian short  */
   else if ( strcmp(line, "PC32") == 0)
     info.data_type = 4;               /*  little endian short  */
   else if ( strcmp(line, "HP16") == 0)
     info.data_type = 0;               /*  big endian short  */
   else if ( strcmp(line, "HP32") == 0)
     info.data_type = 1;               /*  big endian long  */
   else
   {
     fprintf(stderr, "\n ERROR! Unknown data format: %s", line);
     return(info);
   }

   /* DA FARE
   ptr = vp_setpos_runfile(info_runfile, "LOW_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.low_fr);
   ptr = vp_setpos_runfile(info_runfile, "HIGH_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.hig_fr;
   */

   info.rawfile          = TRUE;           /* Always a raw file  */
   info.multiplexed_data = TRUE;
   info.raw_header_type  = 31;
   info.header_type      = 31;

   info.isns = 55;                          /*  Default DA FARE  */
   if (info.nmagch > 100)
      info.isns   = 154;
   if (info.nmagch < 100 && info.nmagch > 40)
      info.isns   = 55;

/******************/
/*  Get slot map  */
/******************/

   i = 0;
   ptr = vp_setpos_runfile(info_runfile, "START_STORED_SLOT_MAP");
   while(TRUE)
   {
      sscanf(ptr, "%s", line);
      if (strcmp(line, "END_STORED_SLOT_MAP") == 0)
       break;

      strcpy(&ch_list[i][0], line);
      i++;
      ptr = vp_advance_ptr(ptr);
   }
   if (info.nchan != i)
      fprintf(stderr, "\n ERROR. Number of channels in slot map and packet size do not match");

/***************************************/
/*  Get magnetic channel informations  */
/***************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_MAGNETIC_SENSOR_DESCRIPTION");  /*  Find data start for mag channels   */
   ptre = vp_setpos_runfile(info_runfile, "END_MAGNETIC_SENSOR_DESCRIPTION");    /*  Find data end for mag channels     */

   vp_parse_runfile(ptr, "CALIBRATION_UNITS:", "%s", line);     /*  Find unit label  */
   strncpy(unit_label, line, 15);
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "MAG_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n WARNING! channel %s is not in stored slot map", line);  */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 2;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      vp_parse_runfile(dataword, "SENSOR_ORIENTATION:", "%f %f %f",
                      &info.ch[ich].pos[0].u_s.comp[0],
                      &info.ch[ich].pos[0].u_s.comp[1],
                      &info.ch[ich].pos[0].u_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Check orientation for unit vector */
      cfact = (float)sqrt( info.ch[ich].pos[0].u_s.comp[0]*info.ch[ich].pos[0].u_s.comp[0] +
                           info.ch[ich].pos[0].u_s.comp[1]*info.ch[ich].pos[0].u_s.comp[1] +
                           info.ch[ich].pos[0].u_s.comp[2]*info.ch[ich].pos[0].u_s.comp[2] );
      info.ch[ich].pos[0].u_s.comp[0] /= cfact;
      info.ch[ich].pos[0].u_s.comp[1] /= cfact;
      info.ch[ich].pos[0].u_s.comp[2] /= cfact;

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/*************************************************/
/*  Get magnetic reference channel informations  */
/*************************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_MAGNETIC_REFERENCE_DESCRIPTION");
   ptre = vp_setpos_runfile(info_runfile, "END_MAGNETIC_REFERENCE_DESCRIPTION");

   vp_parse_runfile(ptr, "CALIBRATION_UNITS:", "%s", line);     /*  Find unit label  */
   strncpy(unit_label, line, 15);
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "REF_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 8;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      vp_parse_runfile(dataword, "SENSOR_ORIENTATION:", "%f %f %f",
                      &info.ch[ich].pos[0].u_s.comp[0],
                      &info.ch[ich].pos[0].u_s.comp[1],
                      &info.ch[ich].pos[0].u_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Check orientation for unit vector */
      cfact = (float)sqrt( info.ch[ich].pos[0].u_s.comp[0]*info.ch[ich].pos[0].u_s.comp[0] +
                           info.ch[ich].pos[0].u_s.comp[1]*info.ch[ich].pos[0].u_s.comp[1] +
                           info.ch[ich].pos[0].u_s.comp[2]*info.ch[ich].pos[0].u_s.comp[2] );
      info.ch[ich].pos[0].u_s.comp[0] /= cfact;
      info.ch[ich].pos[0].u_s.comp[1] /= cfact;
      info.ch[ich].pos[0].u_s.comp[2] /= cfact;

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/***************************************/
/*  Get electric channel informations  */
/***************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_ELECTRIC_SENSOR_DESCRIPTION");
   ptre = vp_setpos_runfile(info_runfile, "END_ELECTRIC_SENSOR_DESCRIPTION");

   vp_parse_runfile(ptr, "CALIBRATION_UNITS:", "%s", line);     /*  Find unit label  */
   strncpy(unit_label, line, 15);
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "ELEC_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 1;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Convert position to mm  */
      info.ch[ich].pos[0].r_s.comp[0] *= 10.;
      info.ch[ich].pos[0].r_s.comp[1] *= 10.;
      info.ch[ich].pos[0].r_s.comp[2] *= 10.;

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/****************************************/
/*  Get auxiliary channel informations  */
/****************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_AUXILIARY_CHANNEL_DESCRIPTION");
   ptre = vp_setpos_runfile(info_runfile, "END_AUXILIARY_CHANNEL_DESCRIPTION");
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "AUX_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 16;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      vp_parse_runfile(dataword, "SENSOR_ORIENTATION:", "%f %f %f",
                      &info.ch[ich].pos[0].u_s.comp[0],
                      &info.ch[ich].pos[0].u_s.comp[1],
                      &info.ch[ich].pos[0].u_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Convert position to mm  */
      info.ch[ich].pos[0].r_s.comp[0] *= 10.;
      info.ch[ich].pos[0].r_s.comp[1] *= 10.;
      info.ch[ich].pos[0].r_s.comp[2] *= 10.;

/*  Check orientation for unit vector */
      cfact = (float)sqrt( info.ch[ich].pos[0].u_s.comp[0]*info.ch[ich].pos[0].u_s.comp[0] +
                           info.ch[ich].pos[0].u_s.comp[1]*info.ch[ich].pos[0].u_s.comp[1] +
                           info.ch[ich].pos[0].u_s.comp[2]*info.ch[ich].pos[0].u_s.comp[2] );
      info.ch[ich].pos[0].u_s.comp[0] /= cfact;
      info.ch[ich].pos[0].u_s.comp[1] /= cfact;
      info.ch[ich].pos[0].u_s.comp[2] /= cfact;

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }


/***************************************/
/*  Get digital channel informations   */
/***************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_DIGITAL_DATA_CHANNEL_DESCRIPTION");  /*  Find data start for dig channels   */
   ptre = vp_setpos_runfile(info_runfile, "END_DIGITAL_DATA_CHANNEL_DESCRIPTION");    /*  Find data end for dig channels     */
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc   = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptc  -= 25;
      if ( i<(n_sens-1) )
      {
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
         ptce -= 25;
      }
      else
      ptce = ptre;

/*  Copy string related to examined channel  */

      strncpy(dataword, ptc, (ptce-ptc));
      dataword[ptce-ptc] = '\0';

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%s", line);    /*  Build channel label  */
      if ((strcmp(line, "PACKET_ID_UPPER") != 0) && (strcmp(line, "PACKET_ID_LOWER") != 0))
      {
         vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);
         sprintf(line, "DIGDAT_%.3d", number);
      }

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 15);                /*  Find channel label            */
      if (strcmp(line, "PACKET_ID_UPPER") == 0)
      strcpy(info.ch[ich].label, "ID_UPPER");
      if (strcmp(line, "PACKET_ID_LOWER") == 0)
      strcpy(info.ch[ich].label, "ID_LOWER");
      info.ch[ich].type   = 64;
      info.ch[ich].number = number;

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/************************************/
/*  Get flag channel informations   */
/************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_FLAG_CHANNEL_DESCRIPTION");  /*  Find data start for dig channels   */
   ptre = vp_setpos_runfile(info_runfile, "END_FLAG_CHANNEL_DESCRIPTION");    /*  Find data end for dig channels     */
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc   = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptc  -= 25;
      if ( i<(n_sens-1) )
      {
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
         ptce -= 25;
      }
      else
      ptce = ptre;

/*  Copy string related to examined channel  */

      strncpy(dataword, ptc, (ptce-ptc));
      dataword[ptce-ptc] = '\0';

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%s", line);    /*  Build channel label  */

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 15);                /*  Find channel label   */
      info.ch[ich].type   = 128;
	  vp_parse_runfile(line, "FLG_", "%d", &number);        /*  Find channel number  */
      info.ch[ich].number = number;

	  if (number == 2)               /* Set FLG_002 as trigger channel  */
		  info.itri = ich + 1;
      info.ch[ich].flag   = 0;
	  info.ch[ich].calib  = 1;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }


/***********************************/
/*   Set global sensor position    */
/***********************************/

#if 0

/*  Read sensor position  */
   ptr = vp_setpos_runfile(info_runfile, "START_PATIENT_COORDINATE_SYSTEM");
   vp_parse_runfile(ptr, "POSITION:", "%f %f %f",
                                      &info.r_center.comp[0],
                                      &info.r_center.comp[1],
                                      &info.r_center.comp[2]);
   vp_parse_runfile(ptr, "ORIENTATION:", "%f %f %f",
                                        &info.u_center.comp[0],
                                        &info.u_center.comp[1],
                                        &info.u_center.comp[2]);
   vp_parse_runfile(ptr, "TWIST:", "%f", &info.rotation_angle);

#endif


/**********************************************************************************/
/*   Check NUMBER_OF_SEGMENTS. If more than one segment is present, identify the  */
/*   starting packet of each segment by looking at time stamp.                    */
/*   Alternativamente si puo' controllare il time stamp veloce e vedere quando    */
/*   il salto e' differente dal previsto. Il problema e' sul previsto.            */
/**********************************************************************************/

#if 0
   if (nsegments > 1)
   {
      ch_timestamp = 255;

      delta      = 10000 / info.smpfq;
      nsegm      = 0;
      offset     = 0;
      info.smpl[nsegm++].start = 0;              /* Set first segment  */

      while (offset < (info.ntpdata - 1))
      {
         ndatapoints = info.ntpdata - offset;
         if (ndatapoints > 16384)
            ndatapoints = 16384;
         vp_read_ch(buffer,  info, ch_timestamp, offset, ndatapoints, file);

         for(i=0; i<(ndatapoints-1); i++)
         {
            if ( fabs((buffer[i+1] - buffer[i]) > 1) )
               info.smpl[nsegm++].start = offset + i + 1;
         }

         offset += (ndatapoints - 1);
      }

      info.nsmpl = nsegm;
      if (nsegm != nsegments)
        fprintf(stderr, "\n ERROR! No. of segments found in data is not correct (found %d, defined %d)",
          nsegm, nsegments);
   }
#endif

/***********************************************/
/*  Free memory and return to calling program  */
/***********************************************/

   free(info_runfile);

   return(info);
}




/*************************************************/
/*************************************************/
/**  Read BMDSYS header into vp info structure  **/
/*************************************************/
/*************************************************/

header640 vp_read_bmdsys_header640(FILE *file)
{
   char          line[256], line1[256];
   char          *info_runfile, *ptr, *ptre, *ptc, *ptce, ch_list[256][64],
                 dataword[16384], unit_label[16];
   int           i, ich, nchan, number, nbyte_header, ndatapoints, 
                 tot_ref_packets, n_sens;
   long int      f_start_reference_data, f_start_data;
   float         cfact, pos_multiplier;
   header640     info;

   int           vp_parse_runfile(char *, char *, char *, ...);
   char          *vp_setpos_runfile(char *, char *);
   char          *vp_advance_ptr(char *);

   memset(&info, '\0', sizeof(header640));

/****************************/
/*  Find header dimensions  */
/****************************/

   rewind(file);
   f_start_data           = ftell(file);
   f_start_reference_data = 0;
   while( fgets(line, 80, file) != NULL && (f_start_data == 0))
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strcmp(line1, "START_DATA") == 0)
        f_start_data = ftell(file);
      if (strcmp(line1, "START_REFERENCE_DATA") == 0)
        f_start_reference_data = ftell(file);
   }

/*  Find header lenght  */
   nbyte_header = f_start_data;
   if ((f_start_reference_data < nbyte_header) && (f_start_reference_data > 0))
          nbyte_header = f_start_reference_data;

   info.start_data = f_start_data;

/*****************************************************************/
/*   First read some important info's directly from file.        */
/*   These infos need not to be placed before any data segment,  */
/*   other infos MUST be stored before data or reference_data.   */
/*****************************************************************/

/*  Read TOTAL_OUTPUT_PACKETS  */
   rewind(file);
   ndatapoints = 0;
   while( fgets(line, 80, file) != NULL && (ndatapoints == 0) )
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strncmp(line1, "TOTAL_NO_OF_PACKET:", 19) == 0)
         vp_parse_runfile(line, "TOTAL_NO_OF_PACKET:", "%d", &ndatapoints);
   }
   info.ntpdata = ndatapoints;

/*  Read TOTAL_REFERENCE_PACKETS  (if START_REFERENCE_DATA is found)  */
   if (f_start_reference_data > 0)
   {
      rewind(file);
      tot_ref_packets = 0;
      while( fgets(line, 80, file) != NULL && (tot_ref_packets == 0) )
      {
         sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
         if (strncmp(line1, "TOTAL_REFERENCE_PACKETS:", 24) == 0)
            vp_parse_runfile(line, "TOTAL_REFERENCE_PACKETS:", "%d", &tot_ref_packets);
      }
      info.ntpref = tot_ref_packets;
   }

/*********************/
/*  Allocate memory  */
/*********************/

   info_runfile = (char *)malloc(nbyte_header * sizeof(char));
   if (info_runfile == NULL)
   {
      fprintf(stderr, "\n ERROR in vp_read_runfile_header!  can't allocate memory");
      exit(-1);
   }

/*****************************/
/*  Read header as a string  */
/*****************************/

   rewind(file);
   fread(info_runfile, sizeof(char), nbyte_header, file);

/**********************************************/
/*  Interpret header into vp info structure   */
/**********************************************/

   info.header_size = (int)f_start_data;

   strcpy(info.last_name, "LastName");
   strcpy(info.first_name, "FirstName");
   vp_parse_runfile(info_runfile, "TIME:", "%s", &info.time[0]);
   vp_parse_runfile(info_runfile, "DATE:", "%s", line);
   strcpy(info.date, line);

   vp_parse_runfile(info_runfile, "START_PATIENT_COMMENT", "%s", line);  /* In realtà bisogna leggere fino alla fine */
   strcpy(info.notes, line);

   vp_parse_runfile(info_runfile, "STORED_SAMPLING_RATE:", "%f", &info.smpfq);
   vp_parse_runfile(info_runfile, "STORED_PKT_SIZE:", "%d", &info.nchan);
   vp_parse_runfile(info_runfile, "STORED_ELEC_CHANNELS:", "%d", &info.nelech);
   vp_parse_runfile(info_runfile, "STORED_MAG_CHANNELS:", "%d", &info.nmagch);
   vp_parse_runfile(info_runfile, "STORED_MAG_REF_CHANNELS:", "%d", &info.nmagrefch);
   vp_parse_runfile(info_runfile, "STORED_AUX_CHANNELS:", "%d", &info.nauxch);
   vp_parse_runfile(info_runfile, "STORED_DIGITAL_DATA:", "%d", &info.ndigitch);
   vp_parse_runfile(info_runfile, "STORED_FLAG_CHANNELS:", "%d", &info.nflagch);

   /*  These channel type are not defined in BMDSys header  */
   info.nelerefch = 0;
   info.nparamch  = 0;

   nchan = info.nelech + info.nelerefch + info.nmagch + info.nmagrefch +
           info.nauxch + info.nparamch + info.ndigitch + info.nflagch;
   if (info.nchan != nchan)
      fprintf(stderr, "\n WARNING! Total number of channels different from the sum of all ",
                    "channels of different kind");

/*  Find number of segments  */

   vp_parse_runfile(info_runfile, "NO_OF_SEGMENTS:", "%d", &info.no_segments);  // QUI BISOGNA GESTIRE LA PPU
   if (info.no_segments < 1)
   {
      fprintf(stderr, "\n ERROR! At least one data segment must be present %d", info.no_segments);
      return(info);
   }

   if (info.no_segments != 1)
   {
      fprintf(stderr, "\n ERROR! Only one data segment must be present %d", info.no_segments);
      return(info);
   }

/*  Identify data format  */
   vp_parse_runfile(info_runfile, "STORED_DATA_TYPE:", "%s", line);

   if ( strcmp(line, "PC16") == 0)
     info.data_type = 3;               /*  little endian short  */
   else if ( strcmp(line, "PC32") == 0)
     info.data_type = 4;               /*  little endian short  */
   else if ( strcmp(line, "HP16") == 0)
     info.data_type = 0;               /*  big endian short  */
   else if ( strcmp(line, "HP32") == 0)
     info.data_type = 1;               /*  big endian long  */
   else
   {
     fprintf(stderr, "\n ERROR! Unknown data format: %s", line);
     return(info);
   }

   /* DA FARE
   ptr = vp_setpos_runfile(info_runfile, "LOW_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.low_fr);
   ptr = vp_setpos_runfile(info_runfile, "HIGH_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.hig_fr;
   */

   info.rawfile          = TRUE;           /* Always a raw file  */
   info.multiplexed_data = TRUE;
   info.raw_header_type  = 51;
   info.header_type      = 51;

   info.isns = 45;                         /*  BMDSYS header may contain only 28-ch data */

/******************/
/*  Get slot map  */
/******************/

   i = 0;
   ptr = vp_setpos_runfile(info_runfile, "START_STORED_SLOT_MAP");
   while(TRUE)
   {
      sscanf(ptr, "%s", line);
      if (strcmp(line, "END_STORED_SLOT_MAP") == 0)
       break;

      strcpy(&ch_list[i][0], line);
      i++;
      ptr = vp_advance_ptr(ptr);
   }
   if (info.nchan != i)
      fprintf(stderr, "\n ERROR. Number of channels in slot map and packet size do not match");

/***************************************/
/*  Get magnetic channel informations  */
/***************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_MAGNETIC_SENSOR_DESCRIPTION");  /*  Find data start for mag channels   */
   ptre = vp_setpos_runfile(info_runfile, "END_MAGNETIC_SENSOR_DESCRIPTION");    /*  Find data end for mag channels     */

   pos_multiplier = 1;
   vp_parse_runfile(ptr, "COORDINATE_UNITS:", "%s", line);     /*  Find coordinate units  */
   if (strcmp(line, "mm") == 0) pos_multiplier = 1;
   if (strcmp(line, "cm") == 0) pos_multiplier = 10;           /*  If cm units, multiply by 10  */


   vp_parse_runfile(ptr, "CALIBRATION_UNITS:", "%s", line);     /*  Find unit label  */
   strncpy(unit_label, line, 15);
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "MAG_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n WARNING! channel %s is not in stored slot map", line);  */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 2;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

/*  Per ora configuro tutto come magnetometro (così è scritto nell'header) */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);

      info.ch[ich].pos[0].r_s.comp[0] *= pos_multiplier;
      info.ch[ich].pos[0].r_s.comp[1] *= pos_multiplier;
      info.ch[ich].pos[0].r_s.comp[2] *= pos_multiplier;

      vp_parse_runfile(dataword, "SENSOR_ORIENTATION:", "%f %f %f",
                      &info.ch[ich].pos[0].u_s.comp[0],
                      &info.ch[ich].pos[0].u_s.comp[1],
                      &info.ch[ich].pos[0].u_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Check orientation for unit vector */
      cfact = (float)sqrt( info.ch[ich].pos[0].u_s.comp[0]*info.ch[ich].pos[0].u_s.comp[0] +
                           info.ch[ich].pos[0].u_s.comp[1]*info.ch[ich].pos[0].u_s.comp[1] +
                           info.ch[ich].pos[0].u_s.comp[2]*info.ch[ich].pos[0].u_s.comp[2] );
      info.ch[ich].pos[0].u_s.comp[0] /= cfact;
      info.ch[ich].pos[0].u_s.comp[1] /= cfact;
      info.ch[ich].pos[0].u_s.comp[2] /= cfact;

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/*************************************************/
/*  Get magnetic reference channel informations  */
/*************************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_MAGNETIC_REFERENCE_DESCRIPTION");
   ptre = vp_setpos_runfile(info_runfile, "END_MAGNETIC_REFERENCE_DESCRIPTION");

   vp_parse_runfile(ptr, "CALIBRATION_UNITS:", "%s", line);     /*  Find unit label  */
   strncpy(unit_label, line, 15);
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "REF_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 8;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      vp_parse_runfile(dataword, "SENSOR_ORIENTATION:", "%f %f %f",
                      &info.ch[ich].pos[0].u_s.comp[0],
                      &info.ch[ich].pos[0].u_s.comp[1],
                      &info.ch[ich].pos[0].u_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Check orientation for unit vector */
      cfact = (float)sqrt( info.ch[ich].pos[0].u_s.comp[0]*info.ch[ich].pos[0].u_s.comp[0] +
                           info.ch[ich].pos[0].u_s.comp[1]*info.ch[ich].pos[0].u_s.comp[1] +
                           info.ch[ich].pos[0].u_s.comp[2]*info.ch[ich].pos[0].u_s.comp[2] );
      info.ch[ich].pos[0].u_s.comp[0] /= cfact;
      info.ch[ich].pos[0].u_s.comp[1] /= cfact;
      info.ch[ich].pos[0].u_s.comp[2] /= cfact;

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/***************************************/
/*  Get electric channel informations  */
/***************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_ELECTRIC_SENSOR_DESCRIPTION");
   ptre = vp_setpos_runfile(info_runfile, "END_ELECTRIC_SENSOR_DESCRIPTION");

   vp_parse_runfile(ptr, "CALIBRATION_UNITS:", "%s", line);     /*  Find unit label  */
   strncpy(unit_label, line, 15);
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "ELEC_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 1;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Convert position to mm  */
      info.ch[ich].pos[0].r_s.comp[0] *= 10.;
      info.ch[ich].pos[0].r_s.comp[1] *= 10.;
      info.ch[ich].pos[0].r_s.comp[2] *= 10.;

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/****************************************/
/*  Get auxiliary channel informations  */
/****************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_AUXILIARY_CHANNEL_DESCRIPTION");
   ptre = vp_setpos_runfile(info_runfile, "END_AUXILIARY_CHANNEL_DESCRIPTION");
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc  = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
      ptc  -= 25;
      ptce -= 25;

/*  Copy string related to examined channel  */
      strncpy(dataword, ptc, (ptce-ptc));

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);    /*  Build channel label  */
      sprintf(line, "AUX_%.3d", number);

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 16);                /*  Find channel label            */
      info.ch[ich].type   = 16;
      info.ch[ich].number = number;
      strcpy(info.ch[ich].unit, unit_label);

#if 0
/*  Per ora configuro tutto come magnetometro, da controllare anche la calibrazione  */
      info.ch[ich].ncoils = 1;
      vp_parse_runfile(dataword, "SENSOR_POSITION:", "%f %f %f",   /*  Find position and orientation  */
                      &info.ch[ich].pos[0].r_s.comp[0],
                      &info.ch[ich].pos[0].r_s.comp[1],
                      &info.ch[ich].pos[0].r_s.comp[2]);
      vp_parse_runfile(dataword, "SENSOR_ORIENTATION:", "%f %f %f",
                      &info.ch[ich].pos[0].u_s.comp[0],
                      &info.ch[ich].pos[0].u_s.comp[1],
                      &info.ch[ich].pos[0].u_s.comp[2]);
      info.ch[ich].wgt[0] = 1;

/*  Convert position to mm  */
      info.ch[ich].pos[0].r_s.comp[0] *= 10.;
      info.ch[ich].pos[0].r_s.comp[1] *= 10.;
      info.ch[ich].pos[0].r_s.comp[2] *= 10.;

/*  Check orientation for unit vector */
      cfact = (float)sqrt( info.ch[ich].pos[0].u_s.comp[0]*info.ch[ich].pos[0].u_s.comp[0] +
                           info.ch[ich].pos[0].u_s.comp[1]*info.ch[ich].pos[0].u_s.comp[1] +
                           info.ch[ich].pos[0].u_s.comp[2]*info.ch[ich].pos[0].u_s.comp[2] );
      info.ch[ich].pos[0].u_s.comp[0] /= cfact;
      info.ch[ich].pos[0].u_s.comp[1] /= cfact;
      info.ch[ich].pos[0].u_s.comp[2] /= cfact;
#endif

      cfact = 1.;                                                        /*  Find calibration  */
      vp_parse_runfile(dataword, "SENSOR_CALIBRATION:", "%f", &cfact);

      info.ch[ich].calib = (float)(1. / cfact);

      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }


/***************************************/
/*  Get digital channel informations   */
/***************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_DIGITAL_DATA_CHANNEL_DESCRIPTION");  /*  Find data start for dig channels   */
   ptre = vp_setpos_runfile(info_runfile, "END_DIGITAL_DATA_CHANNEL_DESCRIPTION");    /*  Find data end for dig channels     */
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc   = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptc  -= 25;
      if ( i<(n_sens-1) )
      {
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
         ptce -= 25;
      }
      else
      ptce = ptre;

/*  Copy string related to examined channel  */

      strncpy(dataword, ptc, (ptce-ptc));
      dataword[ptce-ptc] = '\0';

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%s", line);    /*  Build channel label  */
      if ((strcmp(line, "PACKET_ID_UPPER") != 0) && (strcmp(line, "PACKET_ID_LOWER") != 0))
      {
         vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%d", &number);
         sprintf(line, "DIGDAT_%.3d", number);
      }

      if (strcmp(line, "DIGDAT_001") == 0)   strcpy(line, "PACKET_ID_UPPER");
      if (strcmp(line, "DIGDAT_002") == 0)   strcpy(line, "PACKET_ID_LOWER");
      
      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
       fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line);
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 15);                /*  Find channel label            */
      if (strcmp(line, "PACKET_ID_UPPER") == 0)
      strcpy(info.ch[ich].label, "FLG_002");
      if (strcmp(line, "PACKET_ID_LOWER") == 0)
      strcpy(info.ch[ich].label, "ID_LOWER");
      info.ch[ich].type   = 64;
      info.ch[ich].number = number;

      info.ch[ich].calib  = (float)1.0;
      info.ch[ich].flag   = 0;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }

/************************************/
/*  Get flag channel informations   */
/************************************/

   ptr  = vp_setpos_runfile(info_runfile, "START_FLAG_CHANNEL_DESCRIPTION");  /*  Find data start for dig channels   */
   ptre = vp_setpos_runfile(info_runfile, "END_FLAG_CHANNEL_DESCRIPTION");    /*  Find data end for dig channels     */
   vp_parse_runfile(ptr, "NO_OF_SENSORS:", "%d", &n_sens);       /*  Find no of sensors described  */

   ptc = ptr;

   for (i=0; i<n_sens; i++)
   {
      ptc   = vp_setpos_runfile(ptc,   "START_DESCRIPTION_SENSOR");  /*  Find data start for next channel   */
      ptc  -= 25;
      if ( i<(n_sens-1) )
      {
      ptce = vp_setpos_runfile(ptc+5, "START_DESCRIPTION_SENSOR");  /*  Find data end for next channel     */
         ptce -= 25;
      }
      else
      ptce = ptre;

/*  Copy string related to examined channel  */

      strncpy(dataword, ptc, (ptce-ptc));
      dataword[ptce-ptc] = '\0';

      vp_parse_runfile(dataword, "START_DESCRIPTION_SENSOR:", "%s", line);    /*  Build channel label  */

      for (ich=0; ich<info.nchan; ich++)                 /*  Find selected channel in sequence    */
        if (strcmp(line, &ch_list[ich][0]) == 0)
             break;
      if (ich >= info.nchan)
      {
      /* fprintf(stderr, "\n ERROR! channel %s is not in stored slot map", line); */
       ptc = ptce;
       continue;
      }

      strncpy(info.ch[ich].label, line, 15);                /*  Find channel label   */
      info.ch[ich].type   = 128;
	  vp_parse_runfile(line, "FLG_", "%d", &number);        /*  Find channel number  */
      info.ch[ich].number = number;

	  if (number == 2)               /* Set FLG_002 as trigger channel  */
		  info.itri = ich + 1;
      info.ch[ich].flag   = 0;
	  info.ch[ich].calib  = 1;
      info.ch[ich].amvbit = 1;

      ptc = ptce;
   }


/***********************************/
/*   Set global sensor position    */
/***********************************/

#if 0

/*  Read sensor position  */
   ptr = vp_setpos_runfile(info_runfile, "START_PATIENT_COORDINATE_SYSTEM");
   vp_parse_runfile(ptr, "POSITION:", "%f %f %f",
                                      &info.r_center.comp[0],
                                      &info.r_center.comp[1],
                                      &info.r_center.comp[2]);
   vp_parse_runfile(ptr, "ORIENTATION:", "%f %f %f",
                                        &info.u_center.comp[0],
                                        &info.u_center.comp[1],
                                        &info.u_center.comp[2]);
   vp_parse_runfile(ptr, "TWIST:", "%f", &info.rotation_angle);

#endif


/**********************************************************************************/
/*   Check NUMBER_OF_SEGMENTS. If more than one segment is present, identify the  */
/*   starting packet of each segment by looking at time stamp.                    */
/*   Alternativamente si puo' controllare il time stamp veloce e vedere quando    */
/*   il salto e' differente dal previsto. Il problema e' sul previsto.            */
/**********************************************************************************/

#if 0
   if (nsegments > 1)
   {
      ch_timestamp = 255;

      delta      = 10000 / info.smpfq;
      nsegm      = 0;
      offset     = 0;
      info.smpl[nsegm++].start = 0;              /* Set first segment  */

      while (offset < (info.ntpdata - 1))
      {
         ndatapoints = info.ntpdata - offset;
         if (ndatapoints > 16384)
            ndatapoints = 16384;
         vp_read_ch(buffer,  info, ch_timestamp, offset, ndatapoints, file);

         for(i=0; i<(ndatapoints-1); i++)
         {
            if ( fabs((buffer[i+1] - buffer[i]) > 1) )
               info.smpl[nsegm++].start = offset + i + 1;
         }

         offset += (ndatapoints - 1);
      }

      info.nsmpl = nsegm;
      if (nsegm != nsegments)
        fprintf(stderr, "\n ERROR! No. of segments found in data is not correct (found %d, defined %d)",
          nsegm, nsegments);
   }
#endif

/***********************************************/
/*  Free memory and return to calling program  */
/***********************************************/

   free(info_runfile);

   return(info);
}





/**********************************************/
/**********************************************/
/**  Read IFN header into vp info structure  **/
/**********************************************/
/**********************************************/

header640 vp_read_ifn_header640(FILE *file)
{
   char        line[256], line1[80];
   char        *info_runfile,DataSection[16384],
               *pt_start, *pt_end, sinput[256];
   int         i, ich, nchan, number, nbyte_header, ndatapoints, nsegments,
               nbytes, amp1, amp2;
   long int    f_start_data, f_end_data;
   float       finput;
   header640   info;
   ch_info     ch_temp_info;

   int         vp_parse_runfile(char *, char *, char *, ...);
   char        *vp_setpos_runfile(char *, char *);
   char        *vp_advance_ptr(char *);
   int         vp_setchtype(char *);

   memset(&info, '\0', sizeof(header640));

/****************************/
/*  Find header dimensions  */
/****************************/

   rewind(file);
   f_start_data = ftell(file);
   while( fgets(line, 80, file) != NULL && (f_start_data == 0))
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strcmp(line1, "[DATA]") == 0)
        f_start_data = ftell(file);
   }

   nbyte_header = f_start_data;

   info.start_data = f_start_data;

/*********************/
/*  Allocate memory  */
/*********************/

   info_runfile = (char *)malloc(nbyte_header * sizeof(char) * 2);
   if (info_runfile == NULL)
   {
      fprintf(stderr, "\n ERROR in vp_read_runfile_header!  can't allocate memory");
      exit(-1);
   }

/*****************/
/*  Read header  */
/*****************/

   rewind(file);
   fread(info_runfile, sizeof(char), nbyte_header, file);

/**********************************************/
/*  Interpret header into vp info structure   */
/**********************************************/

   info.header_size = (int)f_start_data;

   strcpy(info.last_name, "LastName");
   strcpy(info.first_name, "FirstName");
   vp_parse_runfile(info_runfile, "Name=", "%s", info.first_name);
   vp_parse_runfile(info_runfile, "Surname=", "%s", info.last_name);

   vp_parse_runfile(info_runfile, "Time=", "%s", &info.time[0]);
   vp_parse_runfile(info_runfile, "Date=", "%s", line);
   strcpy(info.date, line);

   vp_parse_runfile(info_runfile, "SamplingRate=", "%f", &info.smpfq);

   vp_parse_runfile(info_runfile, "num_mag_channels=", "%d", &info.nmagch);
   vp_parse_runfile(info_runfile, "num_magref_channels=", "%d", &info.nmagrefch);
   vp_parse_runfile(info_runfile, "num_ele_channels=", "%d", &info.nelech);
   vp_parse_runfile(info_runfile, "num_eleref_channels=", "%d", &info.nelerefch);
   vp_parse_runfile(info_runfile, "num_aux_channels=", "%d", &info.nauxch);
   vp_parse_runfile(info_runfile, "num_param_channels=", "%d", &info.nparamch);
   vp_parse_runfile(info_runfile, "num_digit_channels=", "%d", &i);
   info.nparamch += i;                     /* Add digit channels to parametric channels  */
   vp_parse_runfile(info_runfile, "num_flag_channels=", "%d", &i);
   info.nparamch += i;                     /* Add flag channels to parametric channels  */
   vp_parse_runfile(info_runfile, "num_none_channels=", "%d", &i);
   info.nparamch += i;                     /* Add none channels to parametric channels  */

   nchan = info.nmagch + info.nmagrefch + info.nelech + info.nelerefch +
           info.nauxch + info.nparamch;
   info.nchan = nchan;

/*******************************************************************/
/*  Find total number of packets by looking for the ENDDATA token  */
/*******************************************************************/

   f_end_data = 0;
   while( fgets(line, 80, file) != NULL && (f_end_data == 0))
   {
      sscanf(line, "%s", line1);      /* leave out spaces and tabs from beginning and end of line */
      if (strcmp(line1, "[ENDDATA]") == 0)
        f_end_data = ftell(file);
   }

   nbytes = (f_end_data - f_start_data);

   ndatapoints = nbytes / 2 / info.nchan;

/*****************************************************/
/* Find number of segments. If only one segment is present data is just a continuous */
/* stream as in the standard 28 channel acquisition mode (info.acq_type = 0).        */
/* If more than one segment is present the stream is segmented (info.acq_type = 1)   */
/*****************************************************/

#if 0
   vp_parse_runfile(info_runfile, "NO_OF_SEGMENTS:", "%d", &nsegments);
   if (nsegments < 1)
   {
      fprintf(stderr, "\n ERROR! At least one data segment must be present %d", nsegments);
      return(info);
   }
   if (nsegments == 1)
      info.acq_type  = 0;
   else
      info.acq_type  = 1;
#endif

   nsegments      = 1;

/*  Identify data format  */
   vp_parse_runfile(info_runfile, "DataFormat=", "%s", line);
   if ( strcmp(line, "LE_SHORT") == 0)
       info.data_type = 2;
    else
       info.data_type = 0;

   info.data_type = 0;
   info.ntpdata  = ndatapoints;

   info.itri   = 0;

   /*
   ptr = vp_setpos_runfile(info_runfile, "LOW_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.low_fr);
   ptr = vp_setpos_runfile(info_runfile, "HIGH_PASS");
   vp_parse_runfile(ptr, "CUTOFF_FREQUENCY:", "%f", &info.hig_fr);
   */

   info.rawfile          = TRUE;         /* Always a raw file  */
   info.multiplexed_data = TRUE;
   info.raw_header_type  = 41;
   info.header_type      = 41;

   info.isns = 33;                                    /*  Default  */
   vp_parse_runfile(info_runfile, "SensorModel=", "%s", &line);
   if ( strcmp(line, "28Canali") == 0)
      info.isns = 36;

/******************************/
/*  Get channel informations  */
/******************************/

/*  Section AcquiredChannels  */

   pt_start  = vp_setpos_runfile(info_runfile, "[AcquiredChannels]");
   pt_end    = vp_setpos_runfile(pt_start, "[");

   strncpy(DataSection, pt_start, (pt_end-pt_start)); /*  Copy string related to examined section  */

   for (ich=0; ich<nchan; ich++)
   {
      sprintf(line, "Channel%d=", ich);
      vp_parse_runfile(DataSection, line, "%s", sinput);        /*  Find channel type    */
      info.ch[ich].type = vp_setchtype(sinput);

      sprintf(line, "Label%d=", ich);
      vp_parse_runfile(DataSection, line, "%s", sinput);       /*  Find channel label   */
      strcpy(info.ch[ich].label, sinput);

      sprintf(line, "Number%d=", ich);
      vp_parse_runfile(DataSection, line, "%d", &number);     /*  Find channel number  */
      info.ch[ich].number = number;

      sprintf(line, "Unit%d=", ich);
      vp_parse_runfile(DataSection, line, "%s", sinput);       /*  Find unit label      */
      strncpy(info.ch[ich].unit, sinput, 6);

      sprintf(line, "mV_to_Unit%d=", ich);
      vp_parse_runfile(DataSection, line, "%f", &finput);     /*  Find calibration     */
      info.ch[ich].calib = finput;
   }

   vp_parse_runfile(info_runfile, "LSB_to_mV=", "%f", &finput);  /*  Find LSB_to_mV factor  */
   for (ich=0; ich<nchan; ich++)
      info.ch[ich].amvbit = finput;


/*  Section Amplifiers  */

   pt_start  = vp_setpos_runfile(info_runfile, "[Amplifiers]");
   pt_end    = vp_setpos_runfile(pt_start, "[");

   strncpy(DataSection, pt_start, (pt_end-pt_start));  /*  Copy string related to examined section  */

   for (ich=0; ich<nchan; ich++)
   {
      sprintf(line, "AmpFirst%d=", ich);
      vp_parse_runfile(DataSection, line, "%d", &amp1);    /*  Find first amplifier    */

      sprintf(line, "AmpSecond%d=", ich);
      vp_parse_runfile(DataSection, line, "%d", &amp2);    /*  Find second amplifier   */

      info.ch[ich].calib = info.ch[ich].calib * amp1 * amp2;
      if (info.ch[ich].calib == 0)  info.ch[ich].calib = 1;       /*  Just in case  */

   }


/*  Set geometric properties of the sensor  */

   for (ich=0; ich<nchan; ich++)
   {
     if ((info.ch[ich].type == 2) || (info.ch[ich].type == 8))    /*  Magnetic  */
     {
     ch_temp_info = vp_get_ch_pos(ich+1, info.isns, info.date);
     info.ch[ich].ncoils = ch_temp_info.ncoils;
     for (i=0; i<info.ch[ich].ncoils; i++)
     {
        info.ch[ich].wgt[i] = ch_temp_info.wgt[i];
           info.ch[ich].pos[i].r_s.comp[0] = ch_temp_info.pos[i].r_s.comp[0];
           info.ch[ich].pos[i].r_s.comp[1] = ch_temp_info.pos[i].r_s.comp[1];
           info.ch[ich].pos[i].r_s.comp[2] = ch_temp_info.pos[i].r_s.comp[2];
           info.ch[ich].pos[i].u_s.comp[0] = ch_temp_info.pos[i].u_s.comp[0];
           info.ch[ich].pos[i].u_s.comp[1] = ch_temp_info.pos[i].u_s.comp[1];
           info.ch[ich].pos[i].u_s.comp[2] = ch_temp_info.pos[i].u_s.comp[2];
     }
     }
     else                                                         /*  Non - magnetic  */
     {
        info.ch[ich].ncoils = 1;
        info.ch[ich].pos[0].r_s.comp[0] = 0;
        info.ch[ich].pos[0].r_s.comp[0] = 0;
        info.ch[ich].pos[0].u_s.comp[0] = 0;
        info.ch[ich].pos[0].u_s.comp[0] = 0;
        info.ch[ich].pos[0].u_s.comp[0] = 1;
        info.ch[ich].wgt[0] = 1;
     }
   }

/***********************************************/
/*  Free memory and return to calling program  */
/***********************************************/

   free(info_runfile);

   return(info);
}



/*********************************************/
/*********************************************/
/**  Find channel type from standard label  **/
/*********************************************/
/*********************************************/

int vp_setchtype(char *line)
{
   char  *ps;

   ps = line;
   while(*ps != '\0')              /* Convert string to upper case  */
   {
      if ( ! isupper(*ps))
      *ps = toupper(*ps);
      *ps++;
   }

   if   (strcmp(line, "NONE") == 0)     /*  No channel type (disconnected or unknown channel) */
      return(0);
   if   (strcmp(line, "MAG") == 0)      /*  Magnetic channel, type 2 */
      return(2);
   if  ((strcmp(line, "ELE") == 0)      /*  Electric channel, type 1 */
     || (strcmp(line, "ELEC") == 0))
      return(1);
   if   (strcmp(line, "ELEREF") == 0)   /*  Electric reference channel, type 4 */
      return(4);
   if   (strcmp(line, "MAGREF") == 0)   /*  Magnetic reference channel, type 8 */
      return(8);
   if   (strcmp(line, "AUX") == 0)      /*  Auxiliary channel, type 16 */
      return(16);
   if   (strcmp(line, "PAR") == 0)      /*  parameter channel, type 32 */
      return(32);
   if   (strcmp(line, "DIG") == 0)      /*  Digit channel, type 64 */
      return(64);
   if   (strcmp(line, "FLAG") == 0)     /*  Flag channel, type 128 */
      return(128);

   /* Undefined channel type, return with error  */
   return(-1);
}



/***************************************/
/***************************************/
/**  Translate header into header640  **/
/***************************************/
/***************************************/

header640 vp_header_to_header640(header info256)
{
   int       i, year;
   header640 info;

/*  Clear structure  */
   memset(&info, '\0', sizeof(header640));

/*  Copy info256 into the new structure info640  */
   strcpy(info.stname, info256.stname);
   strcpy(info.stver, "2.0");
   strcpy(info.first_name, info256.first_name);
   strcpy(info.last_name, info256.last_name);
   strcpy(info.id, info256.id);
   strcpy(info.notes, info256.notes);

   strcpy(info.time, info256.time);
   strcpy(info.date, info256.date);

   info.nchan     = info256.nchan;
   info.nelech    = info256.nelech;
   info.nelerefch = info256.nelerefch;
   info.nmagch    = info256.nmagch;
   info.nmagrefch = info256.nmagrefch;
   info.nauxch    = info256.nauxch;
   info.nparamch  = info256.nparamch;
   info.ndigitch  = 0;
   info.nflagch   = 0;

   if ((info256.rawfile == TRUE) && (info.isns > 40))
      info.data_type = 0;             /*  raw data (short, big endian) */
   if ((info256.rawfile == TRUE) && (info.isns < 40))
      info.data_type = 6;             /*  raw data (short, big endian) */
   if (info256.rawfile == FALSE)
      info.data_type = 2;             /* averaged data (float, big endian) */

   info.smpfq        = info256.smpfq;
   info.hw_low_fr    = info256.low_fr;
   info.hw_hig_fr    = info256.hig_fr;
   info.hw_comb      = FALSE;
   info.sw_hig_tc    = 0;
   info.compensation = 0;

   info.ntpdata      = info256.ntpdata;
   info.no_segments  = 1;

   info.sgmt[0].start      = info256.header_size;
   info.sgmt[0].ntptot     = info256.ntpdata;
   info.sgmt[0].type       = 0;
   info.sgmt[0].no_samples = info256.nsmpl;
   info.sgmt[0].st_sample  = 0;
   info.nsmpl              = info256.nsmpl;
   if (info.nsmpl>4096) {
	   memset(&info, '\0', sizeof(header640));
	   return info; 
   }
   for (i=0; i<info256.nsmpl; i++)
      info.smpl[i] = info256.smpl[i];

   info.nrefchan = info.nrefchan;               /*  number of reference channels        */
   for (i=0; i<256; i++)
      info.ref_ch[i] = info256.ref_ch[i];
   info.ntpref = info256.ntpref;

/*  Find raw header type by looking at various header characteristics   */
/*  (of course if the file is not a rawfile itself).                    */
/*  I trust that if:                                                    */
/*    info.ch[0].label == MAG_REF   -->  raw_header_type = 3   (GE)     */
/*    info.ch[0].label == MAG_000   -->  raw_header_type = 31  (ATB)    */
/*    nmagch < 30  e  data < 2003   -->  raw_header_type = 2   (A900)   */
/*    nmagch < 30  e  data = 2003   -->  raw_header_type = 41  (IFN)    */

   i = strlen(info256.date);
   sscanf(info.date+(i-5), "%d", &year);
   if (year < 1000)
   {
      sscanf(info.date+(i-3), "%d", &year);
      year = 2003;                               /*  ATTENZIONE  */
   }

   if ((info256.header_type == 0) || (info256.header_type == 1))
   {
      if (info256.nmagch < 30)
      {
         if (year < 2003)
            info.raw_header_type = 2;
         else
            info.raw_header_type = 41;
      }   
      else if (strncmp(info256.ch[0].label, "MAG_REF",7) == 0)
         info.raw_header_type = 3;
      else if (strcmp(info256.ch[0].label, "MAG_000") == 0)
         info.raw_header_type = 31;
   }
   if (info256.header_type == 2)  info.raw_header_type = 2;
   if (info256.header_type == 3)  info.raw_header_type = 3;
   if (info256.header_type == 4)  info.raw_header_type = 31;

   if (info256.header_type == 0)  info.header_type = 10;
   if (info256.header_type == 1)  info.header_type = 11;
   if (info256.header_type == 2)  info.header_type =  2;
   if (info256.header_type == 3)  info.header_type =  3;
   if (info256.header_type == 4)  info.header_type = 31;

   info.header_size     = info256.header_size;
   info.start_reference = info256.start_reference;
   info.start_data      = info256.start_data;

   info.rawfile          = info256.rawfile;
   info.multiplexed_data = info256.rawfile;       /*  Only rawfile are multiplexed  */

   info.isns = info256.isns;
   for (i=0; i<256; i++)
      info.ch[i] = info256.ch[i];

   info.r_center       = info256.r_center;
   info.u_center       = info256.u_center;
   info.th_center      = info256.th_center;
   info.fi_center      = info256.fi_center;
   info.rotation_angle = info256.rotation_angle;
   info.cosdir[0]      = info256.cosdir[0];
   info.cosdir[1]      = info256.cosdir[1];
   info.cosdir[2]      = info256.cosdir[2];
   info.irefsys        = info256.irefsys;

   info.num_markers  = info256.num_markers;
   for (i=0; i<64; i++)
      info.i_coil[i] = info256.i_coil[i];
   for (i=0; i<64; i++)
      info.marker[i] = info256.marker[i];
   info.best_chi     = info256.best_chi;

   info.cup_vertex_center   = info256.cup_vertex_center;
   info.cup_fi_center       = info256.cup_fi_center;
   info.cup_rotation_angle  = info256.cup_rotation_angle;
   info.dist_a1_a2          = info256.dist_a1_a2;
   info.dist_inion_nasion   = info256.dist_inion_nasion;
   info.max_circ            = info256.max_circ;
   info.nasion_vertex_inion = info256.nasion_vertex_inion;

   info.security       = info256.security;
   info.ave_alignement = TRUE;
   info.itri           = info256.itri;
   info.ntpch          = info256.ntpch;
   info.ntppre         = info256.ntppre;
   info.navrg          = info256.navrg;
   info.nover          = info256.nover;

   info.nave_filt      = 0;
   info.stdev          = info256.stdev;
   info.bas_start      = info256.bas_start;
   info.bas_end        = info256.bas_end;

   for (i=0; i<32; i++)
      info.source_files[i] = info256.source_files[i];

   info.ichtpl   = info256.ichtpl;
   info.ntptpl   = info256.ntptpl;
   info.ifitpl   = info256.ifitpl;
   info.corlim   = info256.corlim;

   return(info);
}


#if 0

header640 *vp_read_header_pointer(FILE *file, char *fname)
{
   char        info_rtea[1536], line[256], line_1[256], line_2[256];
   header      info256;
   header640   info640, info_mhd;
   short       rtea_test;
   int         header_type, le_data;

/********************/
/*  Clear headers   */
/********************/
   memset(&info256, '\0', sizeof(header));
   memset(&info640, '\0', sizeof(header640));

/**********************/
/*  Find header type  */
/**********************/

   rewind(file);
   fread(info_rtea, sizeof(char), 1536, file);
   rewind(file);

   if (lc_parse(info_rtea,1536,"sSs",line,line_1,line_2)) printf("Errore nel parsing dell'header...");

   rtea_test = *(short *)(info_rtea+148);
   le_data = TRUE;                                    /*  Default little endian  */
   if (LE_CPU)
      rtea_test = vp_swap_short(rtea_test);

   if (strcmp(line, "BIOMAG_RUNFILE") == 0)
      header_type = 3;
   else if ( (strcmp(line, "FORMAT:") == 0) && (strcmp(line_1, "ATB-BIOMAGDATA") == 0) )
      header_type = 31;
   else if ( (strcmp(line, "[HeaderType]") == 0) && (strcmp(line_1, "FORMAT=DM1.0") == 0) )
      header_type = 41;
   else if (strcmp(line, "VP_BIOMAG") == 0)
   {
      if (strcmp(line_1, "2.0") != 0)
      {
         header_type = 10;                             /*  256ch header  */
         le_data = FALSE;
      }
      else
      {
         header_type = 20;                             /*  640ch header  */
         le_data = TRUE;
         if (strcmp(line_2, "BE") == 0)
           le_data = FALSE;
      }
   }
   else if (rtea_test == 768)
   {
      header_type = 2;
      le_data = FALSE;
   }
   else
      header_type = 1;

/**********************************/
/*  Read VP_BIOMAG header 640 ch  */
/**********************************/

   if ((header_type == 20) || (header_type == 21))
   {
      fread(&info640, sizeof(header640), 1, file);   /*  read data            */
      if ((info640.nchan > 1024) || (info640.nchan < 0))
         info640 = vp_swap_header640(info640);       /*  swap if needed       */
   }

/**********************************/
/*  Read VP_BIOMAG header 256 ch  */
/**********************************/

   if ((header_type == 10) || (header_type == 11))
   {
      fread(&info256, sizeof(header), 1, file);      /*  read data            */
      if ((info256.nchan > 1024) || (info256.nchan < 0))
         info256 = vp_swap_header256(info256);       /*  swap if needed       */
      info256.start_data = info256.header_size;      /*  on 256ch header force start_data to be equal to header_size  */ 
	  info640 = vp_header_to_header640(info256);     /*  convert to info640   */
      strcpy(info640.stendian, "LE");                /*  update some info's   */
   }

/*****************************/
/*  Read IFN header (ASCII)  */
/*****************************/

   if (header_type == 41)
      info640 = vp_read_ifn_header640(file);

/****************************/
/*  Read GE header (ASCII)  */
/****************************/

   if (header_type == 3)
      info640 = vp_read_ge_header640(file);

/*****************************************/
/*  Read ATB-BIOMAGDATA header (ASCII)   */
/*****************************************/

   if (header_type == 31)
      info640 = vp_read_atb_header640(file);

/**********************/
/*  Read old_header   */
/**********************/

   if (header_type == 1)
      info640 = vp_read_old_header640(file);

/***********************/
/*  Read rte_a header  */
/***********************/

   if (header_type == 2)
   {
      info640 = vp_read_rtea_header640(file);
      info640.raw_header_type = 2;
      strcpy(info640.stendian, "LE");
   }

/*********************************************************/
/*  Check if raw file, if yes try to read master header  */
/*********************************************************/

   if ((info640.rawfile == TRUE) && ((info640.header_type != 11) || (info640.header_type != 21)) )
   {

      info_mhd = vp_read_mhd(fname);

/*  Master header found. Check if compatible with raw file header  */
      if (strcmp(info_mhd.stname, "VP_BIOMAG") == 0)
      {

         if ( (info_mhd.nchan      == info640.nchan    ) &&
              (info_mhd.nelech     == info640.nelech   ) &&
              (info_mhd.nmagch     == info640.nmagch   ) &&
              (info_mhd.nmagrefch  == info640.nmagrefch) &&
              (info_mhd.ntpdata/(int)4096 == info640.ntpdata/(int)4096) ) 
            return(&info_mhd);
         else
           fprintf(stderr, "\n ERROR ! Master header is not compatible with raw file. Returning header from raw file.");
      }
      else
         fprintf(stderr, "\n WARNING ! No master header found. \n");
   }

   strcpy(info640.stver, "2.0");
   strcpy(info640.stname, "VP_BIOMAG");
   return(&info640);
}


/* This function is to be used only in browser  */

header640 vp_read_header_raw(FILE *file, char *fname)
{
   char        info_rtea[1536], line[256], line_1[256], line_2[256];
   header      info256;
   header640   info640;
   short       rtea_test;
   int         header_type, le_data;

/********************/
/*  Clear headers   */
/********************/
   memset(&info256, '\0', sizeof(header));
   memset(&info640, '\0', sizeof(header640));

/**********************/
/*  Find header type  */
/**********************/

   rewind(file);
   fread(info_rtea, sizeof(char), 1536, file);
   rewind(file);

   if (lc_parse(info_rtea,1536,"sSs",line,line_1,line_2)) 
	   printf("Errore nel parsing dell'header...");

   rtea_test = *(short *)(info_rtea+148);
   le_data = TRUE;                                    /*  Default little endian  */
   if (LE_CPU)
      rtea_test = vp_swap_short(rtea_test);

   if (strcmp(line, "BIOMAG_RUNFILE") == 0)
      header_type = 3;
   else if ( (strcmp(line, "FORMAT:") == 0) && (strcmp(line_1, "ATB-BIOMAGDATA") == 0) )
      header_type = 31;
   else if ( (strcmp(line, "[HeaderType]") == 0) && (strcmp(line_1, "FORMAT=DM1.0") == 0) )
      header_type = 41;
   else if (strcmp(line, "VP_BIOMAG") == 0)
   {
      if (strcmp(line_1, "2.0") != 0)
      {
         header_type = 10;                             /*  256ch header  */
         le_data = FALSE;
      }
      else
      {
         header_type = 20;                             /*  640ch header  */
         le_data = TRUE;
         if (strcmp(line_2, "BE") == 0)
           le_data = FALSE;
      }
   }
   else {
		if (rtea_test == 768)
   {
      header_type = 2;
      le_data = FALSE;
   }
   else
      header_type = 1;

      return(info640);

   }
/**********************************/
/*  Read VP_BIOMAG header 640 ch  */
/**********************************/

   if ((header_type == 20) || (header_type == 21))
   {
      fread(&info640, sizeof(header640), 1, file);   /*  read data            */
      if ((info640.nchan > 1024) || (info640.nchan < 0))
         info640 = vp_swap_header640(info640);       /*  swap if needed       */
   }

/**********************************/
/*  Read VP_BIOMAG header 256 ch  */
/**********************************/

   if ((header_type == 10) || (header_type == 11))
   {
      fread(&info256, sizeof(header), 1, file);      /*  read data            */
      if ((info256.nchan > 1024) || (info256.nchan < 0))
         info256 = vp_swap_header256(info256);       /*  swap if needed       */
      info256.start_data = info256.header_size;      /*  on 256ch header force start_data to be equal to header_size  */ 
	  info640 = vp_header_to_header640(info256);     /*  convert to info640   */
      strcpy(info640.stendian, "LE");                /*  update some info's   */
   }

/*****************************/
/*  Read IFN header (ASCII)  */
/*****************************/

   if (header_type == 41)
      info640 = vp_read_ifn_header640(file);

/****************************/
/*  Read GE header (ASCII)  */
/****************************/

   if (header_type == 3)
      info640 = vp_read_ge_header640(file);

/*****************************************/
/*  Read ATB-BIOMAGDATA header (ASCII)   */
/*****************************************/

   if (header_type == 31)
      info640 = vp_read_atb_header640(file);

/**********************/
/*  Read old_header   */
/**********************/

   if (header_type == 1)
      info640 = vp_read_old_header640(file);

/***********************/
/*  Read rte_a header  */
/***********************/

   if (header_type == 2)
   {
      info640 = vp_read_rtea_header640(file);
      info640.raw_header_type = 2;
      strcpy(info640.stendian, "LE");
   }


   strcpy(info640.stver, "2.0");
   strcpy(info640.stname, "VP_BIOMAG");
   return(info640);
}
#endif