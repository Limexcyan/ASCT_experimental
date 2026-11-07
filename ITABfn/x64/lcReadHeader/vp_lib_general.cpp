/****************************************************************************/
/*  ViP library - General utilities                                         */
/*                                                                          */
/*  by Vittorio Pizzella                                                    */
/*                                                                          */
/*  May 24, 2003 - 14.0.1                                                   */
/*  Feb 12, 2008 - 14.0.2    vp_get_ch_pos: if everything is OK do not      */
/*                           print used filename                            */
/*  Feb 13, 2009 - 14.1.0    Added support for new 31-ch system at FbF      */
/*  Jun 02, 2009 - 14.2.0    Fixed vp_get_ch_pos for new 31-ch system       */
/*  Aug 28, 2009 - 14.3.0    Correct identification of gradiometers and     */
/*                           magnetometers for the 31-ch system             */
/*                                                                          */
/****************************************************************************/

/******************************************************************************/
/*  Library for biomag programs                                               */
/*                                                                            */
/*  ch_info vp_get_ch_info(int, int, int)             Find channel info       */
/*  ch_info vp_get_ch_pos(int, int)                   Find channel position   */
/*  int     vp_get_channel_number(header640, int *, int) Get number and list  */
/*                                                    of selected channels    */
/*  int     vp_label2number(header640, char *)        Find channel number     */
/*                                                    from label              */
/*  float   vp_round       (float, float)             Round a number          */
/*  void    vp_round_scale (float *, float *)         Round scale values      */
/*                                                                            */
/******************************************************************************/

#include <stdio.h>
#include <math.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
// #include "vp_biomag.h" Riccardo Navarra (test)
#include "lc_support.h"


/**********************************************************************/
/**********************************************************************/
/**  Get channel info's. Position is set in sensor reference frame.  **/
/**  All values are in mm.                                           **/
/**********************************************************************/
/**********************************************************************/

ch_info vp_get_ch_info(int number, int type, int isns, char *date)
{
   char          line [80];
   ch_info       chinfo;

/**********************************************************/
/*  Set channel position (including weight of the coils)  */
/**********************************************************/

   chinfo = vp_get_ch_pos(number, isns, date);

/******************************************/
/*  Set all other available informations  */
/******************************************/

   chinfo.type      = type;
   chinfo.number    = number;
   chinfo.label[16] = NULL;
   chinfo.flag      = 0;
   chinfo.amvbit    = 0;
   chinfo.calib     = 0;
   chinfo.unit[6]   = NULL;

   if (type == 2)                            /* Handle magnetic channels */
   {
      chinfo.number = number;
      strcpy(chinfo.label, "MAG_");
      sprintf(line, "%d", number);
      strcat(chinfo.label, line);
      strcpy(chinfo.unit, "fT");
      if ( (number == 19)  && (isns>28 && isns<40) )
      {
         chinfo.type   = 8;
         strcpy(chinfo.label, "MAG_REF_");
         sprintf(line, "%d", number);
         strcat(chinfo.label, line);
         chinfo.flag   = 2;
      }
      if ( ((number == 23) || (number == 27)) && (isns>28 && isns<34) )
      {
         chinfo.type   = 8;
         strcpy(chinfo.label, "MAG_REF_");
         sprintf(line, "%d", number);
         strcat(chinfo.label, line);
         chinfo.flag   = 2;
      }
   }
   if (type == 1)                            /* Handle electric channels */
   {
      chinfo.number = number;
      strcpy(chinfo.label, "ELE_");
      sprintf(line, "%d", number);
      strcat(chinfo.label, line);
      strcpy(chinfo.unit, "uV");
   }

   return(chinfo);
}



/*****************************************************************************/
/*****************************************************************************/
/**  Get channel position in sensor reference frame. All values are in mm.  **/
/*****************************************************************************/
/*****************************************************************************/


ch_info vp_get_ch_pos(int number, int isns, char *date)
{
	int           i, j, k;
	float         orient, baseline, thc, fic;
	char          file_in[128],inidir[256],env_path_chpos[256];
	ch_info       chinfo, temp;
	FILE          *fp_in;
	iniFileStruct *ifs;
	
	static char tempFileName[256];
	
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
	
	if (ifs==NULL){
		
		/* search in global dir */
		
		strcpy(inidir,_ROOT);
		strcat(inidir,"config");
		ifs = lc_iniOpen(strcat(inidir,"/browser.ini"),INI_READ);
		
		if (ifs==NULL){
			fprintf(stderr, "\n ERROR !  Configuration file not found.");
			chinfo.number = -1;
			return chinfo;
		}
		
	}
	
	if (lc_iniReadValue(ifs,"paths","cal_data",INI_STRING,env_path_chpos)==NULL)
		strcpy(env_path_chpos,_DATA_CAL);
	
	lc_iniClose(ifs);
	
	if (checkDir(env_path_chpos[strlen(env_path_chpos)-1])) env_path_chpos[strlen(env_path_chpos)-1] = 0;
	
	
	
	/**************************/
	/*  Initialize variables  */
	/**************************/
	
	chinfo.ncoils = 0;
	for (i=0; i<10; i++)
		chinfo.wgt[i] = 0;
	
	i = number - 1;
	if (isns > 40)
		i++;          /*  Put back the +1, since on large systems channel number is already  */
	                  /*  starting from from 0.                                              */
	
	/*********************************************/
	/*  Switch table over the different sensors  */
	/*********************************************/
	
	switch(isns)
	{
		
		/***********************************************************/
		/*  Original 28-channel sensor (with planar gradiometers)  */
		/***********************************************************/
		
		case 28:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i < 16)                           /*  First order axial gradiometers  */
			{
				if (i == 0)
				{
					thc  = 0.;
					fic  = 0.;
				}
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = 79.5;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(135. * sin(thc) * cos(fic));           /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(135. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(135. * cos(thc) - 135.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			else                                                                 /* First order planar */
			{                                                                    /* gradiometers       */
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				baseline      = 15;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(135. * sin(thc) * cos(fic-7.5/66.));
				chinfo.pos[0].r_s.comp[1] = (float)(135. * sin(thc) * sin(fic-7.5/66.));
				chinfo.pos[0].r_s.comp[2] = (float)(135. * cos(thc) - 135.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = (float)(135. * sin(thc) * cos(fic+7.5/66.));
				chinfo.pos[1].r_s.comp[1] = (float)(135. * sin(thc) * sin(fic+7.5/66.));
				chinfo.pos[1].r_s.comp[2] = (float)(135. * cos(thc) - 135.);
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
		}
		break;
		
		/***********************************************************************/
		/*  Modified 28-channel sensor with magnetometers, compensation coils  */
		/*  and with more accurate position of sensors. Data is compensated.   */
		/***********************************************************************/
		
		case 29:
		case 30:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i < 16)                           /*  First order axial gradiometers  */
			{
				if (i == 0)
				{
					thc  = 0.;
					fic  = 0.;
				}
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = (float)79.6;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));  /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			else                                                                 /* Magnetometers */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				baseline = 150.;
				if (i == 20) baseline = 190.;
				if (i == 21) baseline = 190.;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc - 0.1) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc - 0.1) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc - 0.1));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc - 0.1) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc - 0.1) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc - 0.1));
			}
			
		}
		break;
		
		/***************************************************************************/
		/*  Modified 28-channel sensor with magnetometers, compensation coils and  */
		/*  with more accurate position of sensors. Data is not compensated.       */
		/***************************************************************************/
		
		case 31:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i < 16)                           /*  First order axial gradiometers  */
			{
				if (i == 0)
				{
					thc  = 0.;
					fic  = 0.;
				}
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = (float)79.6;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));  /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			else                                                                 /* Magnetometers */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				chinfo.ncoils = 1;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc - 0.1) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc - 0.1) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc - 0.1));
			}
			
		}
		break;
		
		/***********************************************************************/
		/*  Modified 28-channel sensor with magnetometers, compensation coils  */
		/*  and with more accurate position of sensors. Data is compensated.   */
		/***********************************************************************/
		
		case 32:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i < 16)                           /*  First order axial gradiometers  */
			{
				if (i == 0)
				{
					thc  = 0.;
					fic  = 0.;
				}
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = (float)79.6;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic)); /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			else                                                                 /* Magnetometers */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				baseline = 150.;
				if (i == 20) baseline = 190.;
				if (i == 21) baseline = 190.;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc - 0.1) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc - 0.1) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc - 0.1));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc - 0.1) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc - 0.1) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc - 0.1));
			}
			
		}
		break;
		
		
		/***********************************************************************/
		/*  Modified 28-channel sensor with magnetometers, compensation coils  */
		/*  and with more accurate position of sensors. Data is compensated.   */
		/*  Channel 1 is positioned on channel 19.                             */
		/***********************************************************************/
		
		case 33:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i == 0)          /* channel 1 is actually positioned like channel 19  */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (18-16) / 12.) * (2.*PI));
				
				baseline = 150.;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
				
				chinfo.pos[0].r_s.comp[2] += 1.0;     /*  Special correction  */
			}
			
			if (i < 16)                           /*  First order axial gradiometers  */
			{
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = (float)79.6;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));  /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			else                                                                 /* Magnetometers */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				baseline = 150.;
				if (i == 20) baseline = 190.;
				if (i == 21) baseline = 190.;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
				
				if (i==18)
				{
					chinfo.pos[0].r_s.comp[0] = (float)27.49;
					chinfo.pos[0].r_s.comp[1] = (float)11.83;
					chinfo.pos[0].r_s.comp[2] = (float)123.60;
					chinfo.pos[0].u_s.comp[0] = (float)-0.0805;
					chinfo.pos[0].u_s.comp[1] = (float)0.1359;
					chinfo.pos[0].u_s.comp[2] = (float)-0.9874;
				}
				if (i==22)
				{
					chinfo.pos[0].r_s.comp[0] = (float)18.66;
					chinfo.pos[0].r_s.comp[1] = (float)6.37;
					chinfo.pos[0].r_s.comp[2] = (float)99.38;
					chinfo.pos[0].u_s.comp[0] = (float)0.7492;
					chinfo.pos[0].u_s.comp[1] = (float)0.6422;
					chinfo.pos[0].u_s.comp[2] = (float)-0.1623;
				}
				if (i==26)
				{
					chinfo.pos[0].r_s.comp[0] = (float)19.99;
					chinfo.pos[0].r_s.comp[1] = (float)22.66;
					chinfo.pos[0].r_s.comp[2] = (float)109.40;
					chinfo.pos[0].u_s.comp[0] = (float)0.6496;
					chinfo.pos[0].u_s.comp[1] = (float)-0.7534;
					chinfo.pos[0].u_s.comp[2] = (float)-0.1023;
				}
			}
			
		}
		break;
		
		
		/***********************************************************************/
		/*  Modified 28-channel sensor with magnetometers, compensation coils  */
		/*  and with more accurate position of sensors.                        */
		/*  Channel 1 is positioned on channel 19.                             */
		/*  Data is not compensated.                                           */
		/***********************************************************************/
		
		case 34:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i == 0)          /* channel 1 is actually positioned like channel 19  */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (18-16) / 12.) * (2.*PI));
				
				chinfo.ncoils = 1;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				
				chinfo.pos[0].r_s.comp[2] += 1.0;     /*  Special correction  */
			}
			
			if (i < 16)                           /*  First order axial gradiometers  */
			{
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = (float)79.6;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));  /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			else                                                                 /* Magnetometers */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				chinfo.ncoils = 1;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				
				if (i==18)
				{
					chinfo.pos[0].r_s.comp[0] = (float)27.49;
					chinfo.pos[0].r_s.comp[1] = (float)11.83;
					chinfo.pos[0].r_s.comp[2] = (float)123.60;
					chinfo.pos[0].u_s.comp[0] = (float)-0.0805;
					chinfo.pos[0].u_s.comp[1] = (float)0.1359;
					chinfo.pos[0].u_s.comp[2] = (float)-0.9874;
				}
				if (i==22)
				{
					chinfo.pos[0].r_s.comp[0] = (float)18.66;
					chinfo.pos[0].r_s.comp[1] = (float)6.37;
					chinfo.pos[0].r_s.comp[2] = (float)99.38;
					chinfo.pos[0].u_s.comp[0] = (float)0.7492;
					chinfo.pos[0].u_s.comp[1] = (float)0.6422;
					chinfo.pos[0].u_s.comp[2] = (float)-0.1623;
				}
				if (i==26)
				{
					chinfo.pos[0].r_s.comp[0] = (float)19.99;
					chinfo.pos[0].r_s.comp[1] = (float)22.66;
					chinfo.pos[0].r_s.comp[2] = (float)109.40;
					chinfo.pos[0].u_s.comp[0] = (float)0.6496;
					chinfo.pos[0].u_s.comp[1] = (float)-0.7534;
					chinfo.pos[0].u_s.comp[2] = (float)-0.1023;
				}
			}
			
		}
		break;
		
		
		
		/***********************************************************************/
		/*  Modified 28-channel sensor with magnetometers, compensation coils  */
		/*  and with more accurate position of sensors. Data is compensated.   */
		/*  Channel 1 is positioned on channel 19.                             */
		/*  Channel 23 and 27 are positioned on channel 23 and 27.             */
		/*  August 27, 2001                                                    */
		/***********************************************************************/
		
		case 35:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i == 0)          /* channel 1 is actually positioned like channel 19  */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (18-16) / 12.) * (2.*PI));
				
				baseline = 150.;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
				
				chinfo.pos[0].r_s.comp[2] += 1.0;     /*  Special correction  */
			}
			
			if ( i>=1 && i<16 )                              /*  First order axial gradiometers  */
			{
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = (float)79.6;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));  /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			
			if ( i>=16 && i<28 )                                                 /* Magnetometers */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				baseline = 150.;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
				
				if (i==18)
				{
					chinfo.pos[0].r_s.comp[0] = (float)27.49;
					chinfo.pos[0].r_s.comp[1] = (float)11.83;
					chinfo.pos[0].r_s.comp[2] = (float)123.60;
					chinfo.pos[0].u_s.comp[0] = (float)-0.0805;
					chinfo.pos[0].u_s.comp[1] = (float)0.1359;
					chinfo.pos[0].u_s.comp[2] = (float)-0.9874;
				}
			}
			
		}
		break;
		
		
		/*************************************************************************/
		/*  Modified 28-channel sensor with magnetometers, compensation coils    */
		/*  and with more accurate position of sensors. Data is not compensated. */
		/*  Channel 1 is positioned on channel 19.                               */
		/*  Channel 23 and 27 are positioned on channel 23 and 27.               */
		/*  August 27, 2001                                                      */
		/*************************************************************************/
		
		case 36:
		{
			if ((i < 0) || (i > 27))
				return(chinfo);
			
			if (i == 0)          /* channel 1 is actually positioned like channel 19  */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (18-16) / 12.) * (2.*PI));
				
				chinfo.ncoils = 1;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				
				chinfo.pos[0].r_s.comp[2] += 1.0;     /*  Special correction  */
			}
			
			if ( i>=1 && i<16 )                              /*  First order axial gradiometers  */
			{
				if (i>=1 && i<=5)
				{
					thc  = (float)(23. / 135.);
					fic  = (float)((- (i-1) / 5.)  * (2.*PI));
				}
				if (i>=6 && i<=15)
				{
					thc  = (float)(44. / 135.);
					fic  = (float)(( -18./360. - (i-6) / 10.) * (2.*PI));
				}
				
				baseline      = (float)79.6;
				chinfo.ncoils = 2;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));  /* Pick-up coil */
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				chinfo.wgt[1] = -1;
				chinfo.pos[1].r_s.comp[0] = chinfo.pos[0].r_s.comp[0]             /* Compensation coil */
				+ baseline * chinfo.pos[0].u_s.comp[0];
				chinfo.pos[1].r_s.comp[1] = chinfo.pos[0].r_s.comp[1]
				+ baseline * chinfo.pos[0].u_s.comp[1];
				chinfo.pos[1].r_s.comp[2] = chinfo.pos[0].r_s.comp[2]
				+ baseline * chinfo.pos[0].u_s.comp[2];
				chinfo.pos[1].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[1].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[1].u_s.comp[2] = (float)(cos(thc));
			}
			
			if ( i>=16 && i<28 )                                                 /* Magnetometers */
			{
				thc  = (float)(66. / 135.);
				fic  = (float)((- (i-16) / 12.) * (2.*PI));
				
				chinfo.ncoils = 1;
				chinfo.wgt[0] = 1;
				chinfo.pos[0].r_s.comp[0] = (float)(136. * sin(thc) * cos(fic));
				chinfo.pos[0].r_s.comp[1] = (float)(136. * sin(thc) * sin(fic));
				chinfo.pos[0].r_s.comp[2] = (float)(136. * cos(thc) - 136.);
				chinfo.pos[0].u_s.comp[0] = (float)(sin(thc) * cos(fic));
				chinfo.pos[0].u_s.comp[1] = (float)(sin(thc) * sin(fic));
				chinfo.pos[0].u_s.comp[2] = (float)(cos(thc));
				
				if (i==18)
				{
					chinfo.pos[0].r_s.comp[0] = (float)27.49;
					chinfo.pos[0].r_s.comp[1] = (float)11.83;
					chinfo.pos[0].r_s.comp[2] = (float)123.60;
					chinfo.pos[0].u_s.comp[0] = (float)-0.0805;
					chinfo.pos[0].u_s.comp[1] = (float)0.1359;
					chinfo.pos[0].u_s.comp[2] = (float)-0.9874;
				}
			}
			
		}
		break;

		
		/*****************************************************************/
		/*  New 31-channel sensor (16 gradiometers, 12 magnetometers,    */
		/*  3 magnetometers mounted as a vector compensation coil).      */
		/*  Channel 1-28 are positioned as the original 28-channel with  */
		/*  magnetometers in the outer ring.                             */
		/*  February 13, 2009                                            */
		/*****************************************************************/
		
		case 45:
		{
			strcpy(file_in,"pos045");
			
			if (!lc_selectFile(env_path_chpos, file_in, date))
			{
				fprintf(stderr, "\n WARNING! Position file not found!\n");
				exit(-1);
			}
			
			if (strcmp(tempFileName,file_in) != 0)
			{
//				fprintf(stderr, "\n WARNING! Using sensor position file %s\n", file_in);
				strcpy(tempFileName,file_in);
			}

			fp_in = fopen(file_in, "rb");
			
			if (fp_in == NULL)
			{
				fprintf(stderr, "\n ERROR ! Can't open file %s\n", file_in);
				return(chinfo);
			}
			

			k =  0;
			j = -1;
			
			while ((i != j) && (k<256))
			{
				fscanf(fp_in, "%d %f %f %f %f %f %f", &j,
				&temp.pos[0].r_s.comp[0], &temp.pos[0].r_s.comp[1], &temp.pos[0].r_s.comp[2],
				&temp.pos[0].u_s.comp[0], &temp.pos[0].u_s.comp[1], &temp.pos[0].u_s.comp[2]);
				k++;
			}
			
			if (k<256)
			{
                orient = (   temp.pos[0].u_s.comp[0] * temp.pos[0].u_s.comp[0]  /*  Check for unit orientation */
                           + temp.pos[0].u_s.comp[1] * temp.pos[0].u_s.comp[1]
						   + temp.pos[0].u_s.comp[2] * temp.pos[0].u_s.comp[2]);

				chinfo.pos[0].r_s.comp[0] = temp.pos[0].r_s.comp[0];
				chinfo.pos[0].r_s.comp[1] = temp.pos[0].r_s.comp[1];
				chinfo.pos[0].r_s.comp[2] = temp.pos[0].r_s.comp[2];
				chinfo.pos[0].u_s.comp[0] = temp.pos[0].u_s.comp[0] / orient;
				chinfo.pos[0].u_s.comp[1] = temp.pos[0].u_s.comp[1] / orient;
				chinfo.pos[0].u_s.comp[2] = temp.pos[0].u_s.comp[2] / orient;
								
			    if (j<16)                         /*  Gradiometers   */
				{
				   chinfo.ncoils = 2;
			       chinfo.wgt[0] = 1;
				   baseline      = (float)79.6;
			       chinfo.wgt[1] = -1;
				   chinfo.pos[1].r_s.comp[0] = temp.pos[0].r_s.comp[0] + baseline * chinfo.pos[0].u_s.comp[0];
				   chinfo.pos[1].r_s.comp[1] = temp.pos[0].r_s.comp[1] + baseline * chinfo.pos[0].u_s.comp[1];
				   chinfo.pos[1].r_s.comp[2] = temp.pos[0].r_s.comp[2] + baseline * chinfo.pos[0].u_s.comp[2];
				   chinfo.pos[1].u_s.comp[0] = temp.pos[0].u_s.comp[0];
				   chinfo.pos[1].u_s.comp[1] = temp.pos[0].u_s.comp[1];
				   chinfo.pos[1].u_s.comp[2] = temp.pos[0].u_s.comp[2];
				}
				else                              /*  Magnetometers  */
				{
				   chinfo.ncoils = 1;
			       chinfo.wgt[0] = 1;
				}

			}
			else
				fprintf(stderr, "\n ERROR ! Channel no. %d not found in file.\n", i+1);
			
			fclose(fp_in);
			
		}
		break;

		
		/***************************************************************************/
		/*  Flat 55-channel sensor  -  estimated positions                         */
		/***************************************************************************/
		
		case 55:
		{
			
			strcpy(file_in,"pos55");
			
			if (!lc_selectFile(env_path_chpos,file_in,date)){
				fprintf(stderr, "\n WARNING! Position file not found!\n");
				exit(-1);
			}
			
			if (strcmp(tempFileName,file_in)!= 0 ){
				fprintf(stderr, "\n WARNING! Using sensor position file %s\n", file_in);
				strcpy(tempFileName,file_in);
			}
			
			fp_in = fopen(file_in, "rb");
			
			if (fp_in == NULL)
			{
				strcpy(file_in, env_path_chpos);
				strcat(file_in, "/chpos_55.dat");
				
				if (strcmp(tempFileName,file_in)!= 0 ){
					fprintf(stderr, "\n WARNING! Using OLD sensor position file %s\n", file_in);
					strcpy(tempFileName,file_in);
				}

				fp_in = fopen(file_in, "rb");
			}

			
			if (fp_in == NULL)
			{
				fprintf(stderr, "\n ERROR ! Can't open file %s\n", file_in);
				return(chinfo);
			}
			
	
			k =  0;
			j = -1;
			while ((i != j) && (k<256))
			{
				fscanf(fp_in, "%d %f %f %f %f %f %f", &j,
				&temp.pos[0].r_s.comp[0], &temp.pos[0].r_s.comp[1], &temp.pos[0].r_s.comp[2],
				&temp.pos[0].u_s.comp[0], &temp.pos[0].u_s.comp[1], &temp.pos[0].u_s.comp[2]);
				k++;
			}
			
			if (k<256)
			{
				chinfo.pos[0].r_s.comp[0] = temp.pos[0].r_s.comp[0] * (float)10.;
				chinfo.pos[0].r_s.comp[1] = temp.pos[0].r_s.comp[1] * (float)10.;
				chinfo.pos[0].r_s.comp[2] = temp.pos[0].r_s.comp[2] * (float)10.;
				chinfo.pos[0].u_s.comp[0] = temp.pos[0].u_s.comp[0];
				chinfo.pos[0].u_s.comp[1] = temp.pos[0].u_s.comp[1];
				chinfo.pos[0].u_s.comp[2] = temp.pos[0].u_s.comp[2];
			}
			else
				fprintf(stderr, "\n ERROR ! Channel no. %d not found in file.\n", i+1);
			
			fclose(fp_in);
			
			chinfo.ncoils = 1;
			chinfo.wgt[0] = 1;
		}
		break;
		
		/*****************************************************/
		/*  153-channel sensor  -  estimated positions       */
		/*****************************************************/
		
		case 153:
		{
			
			strcpy(file_in,"pos153");
			
			if (!lc_selectFile(env_path_chpos,file_in,date)){
				fprintf(stderr, "\n WARNING! Position file not found!\n");
				exit(-1);
			}
			
			if (strcmp(tempFileName,file_in)!= 0 ){
				fprintf(stderr, "\n WARNING! Using sensor position file %s\n", file_in);
				strcpy(tempFileName,file_in);
			}

			fp_in = fopen(file_in, "rb");
			
			if (fp_in == NULL)
			{
				strcpy(file_in, env_path_chpos);
				strcat(file_in, "/chpos_153.dat");
				
				if (strcmp(tempFileName,file_in)!= 0 ){
					fprintf(stderr, "\n WARNING! Using OLD sensor position file %s\n", file_in);
					strcpy(tempFileName,file_in);
				}
				
				fp_in = fopen(file_in, "rb");
			}
			
			if (fp_in == NULL)
			{
				fprintf(stderr, "\n ERROR ! Can't open file %s\n", file_in);
				return(chinfo);
			}
			

			k =  0;
			j = -1;
			
			while ((i != j) && (k<256))
			{
				fscanf(fp_in, "%d %f %f %f %f %f %f", &j,
				&temp.pos[0].r_s.comp[0], &temp.pos[0].r_s.comp[1], &temp.pos[0].r_s.comp[2],
				&temp.pos[0].u_s.comp[0], &temp.pos[0].u_s.comp[1], &temp.pos[0].u_s.comp[2]);
				k++;
			}
			
			if (k<256)
			{
				chinfo.pos[0].r_s.comp[0] = temp.pos[0].r_s.comp[0];
				chinfo.pos[0].r_s.comp[1] = temp.pos[0].r_s.comp[1];
				chinfo.pos[0].r_s.comp[2] = temp.pos[0].r_s.comp[2];
				chinfo.pos[0].u_s.comp[0] = temp.pos[0].u_s.comp[0];
				chinfo.pos[0].u_s.comp[1] = temp.pos[0].u_s.comp[1];
				chinfo.pos[0].u_s.comp[2] = temp.pos[0].u_s.comp[2];
			}
			else
				fprintf(stderr, "\n ERROR ! Channel no. %d not found in file.\n", i+1);
			
			fclose(fp_in);
			
			chinfo.ncoils = 1;
			chinfo.wgt[0] = 1;
		}
		break;
		
		
		/*********************************************************/
		/*  153-channel sensor  -  estimated positions           */
		/*                      -  positions after Jan 1, 2002   */
		/*********************************************************/
		
		case 154:
		{
			
			strcpy(file_in,"pos154");
			
			if (!lc_selectFile(env_path_chpos,file_in,date))
			{
				fprintf(stderr, "\n WARNING! Position file not found!\n");
				exit(-1);
			}
			
			if (strcmp(tempFileName,file_in) != 0)
			{
//				fprintf(stderr, "\n WARNING! Using sensor position file %s\n", file_in);
				strcpy(tempFileName,file_in);
			}

			fp_in = fopen(file_in, "rb");
			
			if (fp_in == NULL)
			{
				strcpy(file_in, env_path_chpos);
				strcat(file_in, "/chpos_154.dat");
				
				if (strcmp(tempFileName,file_in) != 0)
				{
					fprintf(stderr, "\n WARNING! Using OLD sensor position file %s\n", file_in);
					strcpy(tempFileName,file_in);
				}
				
				fp_in = fopen(file_in, "rb");
			}
			
			if (fp_in == NULL)
			{
				fprintf(stderr, "\n ERROR ! Can't open file %s\n", file_in);
				return(chinfo);
			}
			

			k =  0;
			j = -1;
			
			while ((i != j) && (k<256))
			{
				fscanf(fp_in, "%d %f %f %f %f %f %f", &j,
				&temp.pos[0].r_s.comp[0], &temp.pos[0].r_s.comp[1], &temp.pos[0].r_s.comp[2],
				&temp.pos[0].u_s.comp[0], &temp.pos[0].u_s.comp[1], &temp.pos[0].u_s.comp[2]);
				k++;
			}
			
			if (k<256)
			{
				chinfo.pos[0].r_s.comp[0] = temp.pos[0].r_s.comp[0];
				chinfo.pos[0].r_s.comp[1] = temp.pos[0].r_s.comp[1];
				chinfo.pos[0].r_s.comp[2] = temp.pos[0].r_s.comp[2];
				chinfo.pos[0].u_s.comp[0] = temp.pos[0].u_s.comp[0];
				chinfo.pos[0].u_s.comp[1] = temp.pos[0].u_s.comp[1];
				chinfo.pos[0].u_s.comp[2] = temp.pos[0].u_s.comp[2];
			}
			else
				fprintf(stderr, "\n ERROR ! Channel no. %d not found in file.\n", i+1);
			
			fclose(fp_in);
			
			chinfo.ncoils = 1;
			chinfo.wgt[0] = 1;
		}
		break;
		
		
		/***********************************/
		/*  Error. Instrument not defined  */
		/***********************************/
		
		default:
		{
			fprintf(stderr, "\n ERROR!  Instrument not defined. Sensor code %d\n", isns);
			return(chinfo);
		}
		
	}
	
	
	
	/*****************/
	/*  Normal exit  */
	/*****************/
	
	return(chinfo);
}



/***************************************************************/
/***************************************************************/
/**  Find and store in channel_list all selected channels     **/
/**  numbers. The function returns the number of success-     **/
/**  fully identified channels.                               **/
/**  Code works as follows:                                   **/
/**                                                           **/
/**    Code:  1 - identify all enabled electric channels      **/
/**    Code:  2 - identify all enabled magnetic channels      **/
/**    Code:  4 - identify all enabled electric ref channels  **/
/**    Code:  8 - identify all enabled magnetic ref channels  **/
/**    Code: 16 - identify all enabled auxiliary channels     **/
/**    Code: 32 - identify all enabled parameter channels     **/
/**    Code: 64 - identify all enabled digital channels       **/
/**                                                           **/
/**  To identify more than one type add codes: e.g. to        **/
/**  identify all magnetic and magnetic reference channels    **/
/**  use code 10=2+8. To identify channels regardless of      **/
/**  info.ch[].flag on/off status add 256 to code.            **/
/**                                                           **/
/***************************************************************/
/***************************************************************/

int vp_get_ch_number(header640 info, int *channel_list, int code)
{
   int i, nch;

   nch = 0;
   for (i=0; i<info.nchan; i++)
      if ( ((code & info.ch[i].type) != 0) && ((code>256) || (info.ch[i].flag != 1)) )
      {
         channel_list[nch] = i + 1;
         nch++;
      }
   return(nch);
}


/**************************************************************/
/**  Find and store in channel_list all selected channels.   **/
/**  Version used for header256.                             **/
/**************************************************************/

int vp_get_channel_number(header info, int *channel_list, int code)
{
   int i, nch;

   nch = 0;
   for (i=0; i<info.nchan; i++)
      if ( ((code & info.ch[i].type) != 0) && ((code>256) || (info.ch[i].flag != 1)) )
      {
         channel_list[nch] = i + 1;
         nch++;
      }
   return(nch);
}


/***************************************************************/
/***************************************************************/
/**  Return channel number from channel label. If label is    **/
/**  not found return -1.                                     **/
/**  Case is NOT sensitive.                                   **/
/***************************************************************/
/***************************************************************/

int vp_label2number(header640 info, char *label)
{
   int   i;
   char  *ptr;

/* Change to upper case */
   ptr = label;
   while (*ptr != '\0')
   {
      if ( islower(*ptr) )
      *ptr = toupper(*ptr);
      *ptr++;
   }

/* Find channel number */
   for (i=0; i<info.nchan; i++)
   {
      if (strcmp(label, info.ch[i].label) == 0)
        return (i+1);
   }

/* Return with error */
   return (-1);
}



/***************************************/
/*  Round the number a with module b.  */
/***************************************/
float vp_round(float a, float b)
{
   float c;

   if (a>0.)
   {
      a = (float)(a + b/2.);
      c = (float)(a - fmod(a, b));
   }
   else
   {
      a = (float)(a - b/2.);
      c = (float)(a - fmod(a, b));
   }
   return c;
}



/********************************/
/*   Find rounded delta values  */
/********************************/

void vp_round_scale(float *xmin, float *xmax)
{
   int    delta_power = 0;
   float  min, max, delta, step;

   min = *xmin;
   max = *xmax;
   delta = max - min;
   if (delta==0.)  delta = 1.;
   if (delta<0.)   delta = -delta;
   while(delta<1.)
   {
      delta *= 10.;
      delta_power--;
   }

   while(delta>10.)
   {
      delta /= 10.;
      delta_power++;
   }

   delta_power--;
   step = 1.;
   if (delta > 1.) step = 2.;
   if (delta > 2.) step = 5.;
   if (delta > 5.) step = 10.;

   step *= (float)pow(10., delta_power);

   *xmin = vp_round(min, step);
   if (*xmin > min)  *xmin -= step;

   *xmax = vp_round(max, step);
   if (*xmax < max)  *xmax += step;

   return;
}