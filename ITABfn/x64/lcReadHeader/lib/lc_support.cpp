/**************************************************************


	lc_support.cpp

   *Implementation*

   ANSI C
   ------

   Coded by Luca Ciancetta
	Version 1.0

   Date: march-19, 2003

   ------------------------------------------
   Updated: june-4, 2003

   added ini support:
   
   iniFileStruct *lc_iniOpen(char *fname,iniOpenType ot) // open ini file
   void lc_iniClose(iniFileStruct *ifs)                  // close ini file

   char *lc_iniGetSection(char *string)                  // extract section name
   char *lc_iniGetKey(char *string,                      // extract key name
                     void *value, iniTypeKey tk)

   void *lc_iniReadValue(iniFileStruct *fo,              // read a key value
      char* section,char *key,iniTypeKey tk,void *value)
   int lc_iniWriteValue(iniFileStruct *fo,               // write a key value
      char* section,char *key,iniTypeKey tk,void *value)


***************************************************************/
#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#include <conio.h>

/* #if 0
#include "../../include/vp_biomag.h"
#include "../../include/lc_support.h"
#endif */

// #include "vp_biomag.h" // Riccardo Navarra (test)
#include "lc_support.h"

//#include "fourier_transform.h"
//#include "lc_math.h"

#if WIN_32
#include <time.h>
/* #else
#include <sys/types.h>
#include <dirent.h> */ // Riccardo Navarra: tolto l'"else".
#endif


void quit(int code){
	printf("Hit RETURN to quit!");

#ifndef MATLAB_MEX_FILE
	getch();
#endif

	exit(code);
}

bool checkDir(char ch){
	if ((ch=='/')||(ch=='\\')) return true;
	return false;
}

char *strlower(char *string){
   int i;
   if (string == NULL) return NULL;

  for (i=0;(unsigned)i<strlen(string);i++){
  	if ((string[i]>64)&&(string[i]<91)) string[i] += (char)32;
   }
  return string;
}

char * strhigher(char *string){
   int i;
   if (string == NULL) return NULL;

  for (i=0;(unsigned)i<strlen(string);i++){
  	if ((string[i]>96)&&(string[i]<123)) string[i] -= (char)32;
   }
  return string;
}

int lc_parse(const char* string,int str_dim,char* arguments,...){

   int i;
   char *arg_string, temp[255], *temp2, *temp3; /* temp3 contiene l'header 
aggiustare la dimensione */
   va_list marker;
   /* int arg_int; // need for the 'case i:' */

   if((arguments==NULL)||
      (str_dim==0)||
      (string==NULL)) {
      return LC_ERROR;
   }

   va_start(marker, arguments);

#if WIN_32
   temp3 = new char[str_dim];
#else
   temp3 = (char *)malloc(str_dim*sizeof(char));
#endif

   if (temp3==NULL) return LC_NOMEM;

   memcpy(temp3,string,str_dim);
   temp2 = temp;
   strcpy(temp,arguments);
   strlower(temp);

   while(temp2[0]!=NULL){
      i = 0;
      switch(temp2[0]) {

      case 's': /* stringa */
         arg_string = va_arg(marker,char*);
         while((string[0]&(~128))<33) string++; /* salta caratteri marker */

         while((string[0]&(~128))>=33) {
            arg_string[i] = string[0];
            string++; i++;
         }

         arg_string[i] = '\0';
         break;

      case 'i': /* integer */
         /* to do... */
         /* arg_int = va_arg(marker,int); */
         break;
      }
      temp2++;
   }

#if WIN_32
   delete temp3;
#else
   free(temp3);
#endif

   if(strlen(temp2)>0) return LC_NARGS;
   return LC_OK;
}



char *lc_strTrim(char *string)
{
   int i;
   
   while((string[0]<20)||(string[0]==32))
   {
      if (strlen(string)==0) return string;
      string++;
   }

   for (i=strlen(string)-1;i>0;i--)
   {
      if ((string[i]<20)||(string[i]==32)) continue;
      string[i+1] = 0;
      return string;
   }

   return string;
}


char *lc_iniGetSection(char *string)
{
   if (lc_strTrim(string) == NULL) return NULL;

   /* checks the length of section string */
   if (strlen(string)<3) return NULL;

   /* checks the brackets */
   if (string[0]!='[') return NULL;
   if (string[strlen(string)-1] != ']') return NULL;

   /* return the section name */
   string[strlen(string)-1] = 0;
   return ++string;
}

char *lc_iniGetKey(char *string,void *value, iniTypeKey tk)
{
   char *temp,*strValue;

   if (lc_strTrim(string) == NULL) return NULL;

   /* checks the length of section string */
   if (strlen(string)<3) {
      value = NULL; /* return a NULL value */
      return (char*)value;
   }

   /* isolate comments */
   temp = strchr(string,'#');
   if (temp!=NULL) temp[0] = 0;

   /* checks the equal sign */
   temp = strchr(string,'=');
   if (temp==NULL) {
      value = NULL; /* return a NULL value */
      return (char*)value;
   }
   strValue = temp;
   strValue++;
   *temp = 0;

   lc_strTrim(string);
   strValue = lc_strTrim(strValue);

   switch(tk){
   case INI_INTEGER:
      *((int*)value) = atoi(strValue);
      break;
   case INI_DOUBLE:
      *((double*)value) = atof(strValue);
      break;
   case INI_FLOAT:
      *((float*)value) = (float)atof(strValue);
      break;
   case INI_BOOL:
      if (atoi(strValue) == 0) *((bool*)value) = false;
      else *((bool*)value) = true;
      break;
   case INI_STRING:
      strcpy((char*)value,strValue);
      break;
   }

   return string++;
}

void *lc_iniReadValue(iniFileStruct *fo,char* section,char *key,iniTypeKey 
tk,void *value)
{
   char line[256];
   char *secname, *keyname;

   fseek( fo->fpointer, 0L, SEEK_SET );

   /* gets the next line in the file   */
   /* looking for a section            */
   fgets(line,256,fo->fpointer);
   while(!feof(fo->fpointer)) /* search the section */
   {
      /* checks if there is a line */
      if (line == NULL) {
         fgets(line,256,fo->fpointer);
         continue;
      }

      /* checks if it's a section title */
      secname=lc_iniGetSection(line);
      if (secname == NULL) {
         fgets(line,256,fo->fpointer);
         continue;
      }

      /* checks if it's the needed section */
      if (strcmp(secname,section)!=0) {
         fgets(line,256,fo->fpointer);
         continue;
      }

      /*                                           */
      /* Section found, now searching for the key  */
      /*                                           */

      /* gets the next line in the file   */
      /* looking for a key                */
      fgets(line,256,fo->fpointer);
	  secname = lc_iniGetSection(line);
      while ((secname == NULL)&&(!feof(fo->fpointer)))
      {

         /* checks if there is a line */
         if (line == NULL) {
            fgets(line,256,fo->fpointer);
            secname = lc_iniGetSection(line);
            continue;
         }

         /* checks if it's a key name */
         keyname = lc_iniGetKey(line,value,tk);
         if (keyname == NULL) {
            fgets(line,256,fo->fpointer);
            secname = lc_iniGetSection(line);
            continue;
         }

         /* checks if it's the needed key */
         if (strcmp(keyname,key)!=0) {
            fgets(line,256,fo->fpointer);
            secname = lc_iniGetSection(line);
            continue;
         }

         /*             */
         /* Key found   */
         /*             */

         return value;
      }

   }

   return NULL;
}

int lc_iniWriteValue(iniFileStruct *fo,char* section,char *key,iniTypeKey 
tk,void *value)
{
   char v2s[256],line[256];
   char *secname, *keyname;
   void *temp;
   int i,secpos;

   i=0;

   switch(tk){
   case INI_INTEGER:
      #if WIN_32
         temp = new int;
      #else
         temp = (int*)malloc(sizeof(int));
      #endif
      break;
   case INI_DOUBLE:
      #if WIN_32
         temp = new double;
      #else
         temp = (double*)malloc(sizeof(double));
      #endif
      break;
   case INI_FLOAT:
      #if WIN_32
         temp = new float;
      #else
         temp = (double*)malloc(sizeof(float));
      #endif
      break;
   case INI_BOOL:
      #if WIN_32
         temp = new bool;
      #else
         temp = (double*)malloc(sizeof(bool));
      #endif
      break;
   case INI_STRING:
      #if WIN_32
         temp = new char[256];
      #else
         temp = (char*)malloc(256*sizeof(char));
      #endif
      break;
   }

   while(TRUE){
      while(i<fo->size) /* search the section */
      {

         /* checks if current line is a section title */
         strcpy(line,fo->mpointer[i]);
         secname = lc_iniGetSection(line);
         if (secname == NULL) {
           i++;
           continue;
         }

         /* checks if it's the needed section */
         if (strcmp(secname,section)!=0) {
            i++;
            continue;
         }


         /*                                           */
         /* Section found, now searching for the key  */
         /*                                           */

         /* gets the next line in the file   */
         /* looking for a key                */
         secpos = i;
         if (i==10000-1) {
            #if WIN_32
               delete temp;
            #else
               free(temp);
            #endif
            return 0;
         }
         strcpy(line,fo->mpointer[++i]);
         secname = lc_iniGetSection(line);
         while ((secname == NULL)&&(i<fo->size))
         {

            /* checks if the line is a key name */
            keyname=lc_iniGetKey(line,temp,tk);
            if (keyname == NULL) {
               strcpy(line,fo->mpointer[++i]);
               secname = lc_iniGetSection(line);
               continue;
            }

            /* checks if it's the needed key */
            if (strcmp(keyname,key)!=0) {
               strcpy(line,fo->mpointer[++i]);
               secname = lc_iniGetSection(line);
               continue;
            }

            /*             */
            /* Key found   */
            /*             */

            strcat(keyname,"=");
            switch(tk){
            case INI_INTEGER:
               sprintf(v2s,"%i",*(int*)value);
	            strcat(keyname,v2s);
               break;
            case INI_DOUBLE:
               sprintf(v2s,"%.3f",*(double*)value);
	            strcat(keyname,v2s);
               break;
            case INI_FLOAT:
               sprintf(v2s,"%.3f",*(float*)value);
	            strcat(keyname,v2s);
               break;
            case INI_BOOL:
               sprintf(v2s,"%i",*(bool*)value);
	            strcat(keyname,v2s);
               break;
            case INI_STRING:
               strcat(keyname,(char*)value);
               break;
            }
            strcat(keyname,"\n");
            #if WIN_32
               delete temp;
            #else
               free(temp);
            #endif
            strcpy(fo->mpointer[i],keyname);
            return 1;
         }

         if ((fo->size)==10000) {
            #if WIN_32
               delete temp;
            #else
               free(temp);
            #endif
            return 0;
         }
         /* create the new key */
         for(i=fo->size-1;i>secpos;i--) strcpy(fo->mpointer[i+1],fo->mpointer[i]);
         strcpy(fo->mpointer[secpos+1],key);
         strcat(fo->mpointer[secpos+1],"=");
         strcat(fo->mpointer[secpos+1],"0\n");
         fo->size++;
         i=0;
      }
      /* create the new section */
      strcpy(fo->mpointer[fo->size],"[");
      strcat(fo->mpointer[fo->size],section);
      strcat(fo->mpointer[fo->size],"]\n");
      fo->size++;
      i=0;
   }

}

iniFileStruct *lc_iniOpen(char *fname, iniOpenType ot){

   FILE *fo;
   char line[256];
   int i;
   iniFileStruct *ifs;   

   i = 0;

   #if WIN_32
      ifs = new iniFileStruct;
   #else
      ifs = (iniFileStruct *)malloc(sizeof(iniFileStruct));
   #endif
   ifs->mode = ot;
   ifs->path[0] = 0;
   ifs->masterProgPath = false;

   /* reading mode */
   
   if (ot==INI_READ){
      if ((fname==NULL)||(strlen(fname)==0)){
         #if WIN_32
            delete ifs;
         #else
            free(ifs);
         #endif
         return NULL;
      }
      fo = fopen(fname,"rt");
      if (fo==NULL){
         #if WIN_32
            delete ifs;
         #else
            free(ifs);
         #endif
         return NULL;
      }
      ifs->fpointer = fo;
      return ifs;
   }

   /* writing mode */

   memset(ifs->mpointer,0,10000*256);
   if ((fname!=NULL)&&(strlen(fname)>0)){
     strcpy(ifs->fname,fname);
     fo = fopen(fname,"rt");
      if (fo!=NULL){
         fgets(line,256,fo);
         while((!feof(fo))&&(i<10000)){
            strcpy(ifs->mpointer[i],line);
            fgets(line,256,fo);
            i++;
         }
         fclose(fo);
         if (i>10000){
            #if WIN_32
               delete ifs;
            #else
               free(ifs);
            #endif
            return NULL;
         }
         ifs->size = i;
      } else ifs->size = 0;
   } else {
      ifs->size = 0;
      strcpy(ifs->fname,"/browser.ini"); /* default ini name */
   }

   return ifs;
}

void lc_iniClose(iniFileStruct *ifs){

   FILE *fo;
   int i,pl;
   char inidir[256];

   /* reading mode */

   if (ifs->mode==INI_READ){
      fclose(ifs->fpointer);
      #if WIN_32
         delete ifs;
      #else
         free(ifs);
      #endif
      return;
   }

   /* writing mode */

   /* write local ini */
#if WIN_32
      if (getenv("HOME")!=NULL)
         strcpy(inidir,getenv("HOME"));
      else if (getenv("USERPROFILE")!=NULL)
         strcpy(inidir,getenv("USERPROFILE"));
      else if ((getenv("HOMEDRIVE")!=NULL) && (getenv("HOMEPATH")!=NULL))
         strcpy(inidir,getenv("USERPROFILE"));
      else strcpy(inidir,"c:/");
#else
      if (getenv("HOME")!=NULL)
         strcpy(inidir,getenv("HOME"));
      else strcpy(inidir,"/");
#endif

   if (checkDir(inidir[strlen(inidir)-1])) inidir[strlen(inidir)-1] = 0;
   if (strrchr(ifs->fname,'/')!=NULL) strcat(inidir,strrchr(ifs->fname,'/'));
	else if (strrchr(ifs->fname,'\\')!=NULL) strcat(inidir,strrchr(ifs->fname,'\\'));
	   else{
		  strcat(inidir,"/");
		strcat(inidir,ifs->fname);
		}

   if (ifs->mode==INI_WRITE_LOCAL){
      strcpy(inidir,ifs->fname);
   }

   if(!ifs->masterProgPath){
   		if(ifs->path[0] != 0){
   			pl = strlen(ifs->path);
	    	if((ifs->path[pl-1]=='/')||(ifs->path[pl-1]=='\\')) ifs->path[pl-1] = 0;
			strcpy(inidir,ifs->path);
			strcat(inidir,"/");
			strcat(inidir,ifs->fname);
   		}
	}else{
	      strcpy(inidir,ifs->fname);
	}		
   
   
   fo = fopen(inidir,"wt"); // 1st try
   if (fo==NULL) {
      strcpy(inidir,ifs->fname);
      fo = fopen(inidir,"wt");   // 2nd try
   }
   if (fo!=NULL){
      for(i=0;i<ifs->size;i++) fputs(ifs->mpointer[i],fo);
      fclose(fo);
   }

   #if WIN_32
      delete ifs;
   #else
      free(ifs);
   #endif
}

/***************************************/
/***************************************/
/**  Translate header640 into header  **/
/***************************************/
/***************************************/
#if 0
header vp_header640_to_header(header640 info640)
{
   int       i;
   header info;

/*  Clear structure  */
   memset(&info, '\0', sizeof(header));

/*  Copy info256 into the new structure info640  */
   strcpy(info.stname, info640.stname);

   strcpy(info.first_name, info640.first_name);
   strcpy(info.last_name, info640.last_name);
   strcpy(info.id, info640.id);
   strcpy(info.notes, info640.notes);

   strcpy(info.time, info640.time);
   strcpy(info.date, info640.date);

   info.nchan     = info640.nchan;
   info.nelech    = info640.nelech;
   info.nelerefch = info640.nelerefch;
   info.nmagch    = info640.nmagch;
   info.nmagrefch = info640.nmagrefch;
   info.nauxch    = info640.nauxch;
   info.nparamch  = info640.nparamch;


   if ((info640.data_type == 0)||(info640.data_type == 6))info.rawfile = TRUE;
   if (info640.data_type == 2) info.rawfile = FALSE;


   info.smpfq        = info640.smpfq;
   info.low_fr    = info640.hw_low_fr;
   info.hig_fr    = info640.hw_hig_fr;

   info.ntpdata      = info640.ntpdata;

   info.nsmpl              = info640.nsmpl;
   for (i=0; i<info640.nsmpl; i++)
      info.smpl[i] = info640.smpl[i];

   info.nrefchan = info640.nrefchan;               /*  number of reference 
channels        */
   for (i=0; i<256; i++)
      info.ref_ch[i] = info640.ref_ch[i];
   info.ntpref = info640.ntpref;

   if (info640.raw_header_type == 2)  info.header_type = 2;
   if (info640.raw_header_type == 3)  info.header_type = 3;
   if (info640.raw_header_type == 31)  info.header_type = 4;

   if (info640.header_type == 10)  info.header_type = 0;
   if (info640.header_type == 11)  info.header_type = 1;
   if (info640.header_type == 2)  info.header_type =  2;
   if (info640.header_type == 3)  info.header_type =  3;
   if (info640.header_type == 31) info.header_type = 4;

   info.header_size     = info640.header_size;
   info.start_reference = info640.start_reference;
   info.start_data      = info640.start_data;

   info.rawfile          = info640.rawfile;
   //info.multiplexed_data = info256.rawfile;       /*  Only rawfile are 
multiplexed  */

   info.isns = info640.isns;
   for (i=0; i<256; i++)
      info.ch[i] = info640.ch[i];

   info.r_center       = info640.r_center;
   info.u_center       = info640.u_center;
   info.th_center      = info640.th_center;
   info.fi_center      = info640.fi_center;
   info.rotation_angle = info640.rotation_angle;
   info.cosdir[0]      = info640.cosdir[0];
   info.cosdir[1]      = info640.cosdir[1];
   info.cosdir[2]      = info640.cosdir[2];
   info.irefsys        = info640.irefsys;

   info.num_markers  = info640.num_markers;
   for (i=0; i<64; i++)
      info.i_coil[i] = info640.i_coil[i];
   for (i=0; i<64; i++)
      info.marker[i] = info640.marker[i];
   info.best_chi     = info640.best_chi;

   info.cup_vertex_center   = info640.cup_vertex_center;
   info.cup_fi_center       = info640.cup_fi_center;
   info.cup_rotation_angle  = info640.cup_rotation_angle;
   info.dist_a1_a2          = info640.dist_a1_a2;
   info.dist_inion_nasion   = info640.dist_inion_nasion;
   info.max_circ            = info640.max_circ;
   info.nasion_vertex_inion = info640.nasion_vertex_inion;

   info.security       = info640.security;
   info.itri           = info640.itri;
   info.ntpch          = info640.ntpch;
   info.ntppre         = info640.ntppre;
   info.navrg          = info640.navrg;
   info.nover          = info640.nover;

   info.stdev          = info640.stdev;
   info.bas_start      = info640.bas_start;
   info.bas_end        = info640.bas_end;

   for (i=0; i<32; i++)
      info.source_files[i] = info640.source_files[i];

   info.ichtpl   = info640.ichtpl;
   info.ntptpl   = info640.ntptpl;
   info.ifitpl   = info640.ifitpl;
   info.corlim   = info640.corlim;

   return(info);
}
#endif


/************************

   lc_selectFile

   path: calibration/position data path
   name: data suffix (output)
   date: date of acquisition file
   initialdate: starting data

************************/

bool lc_selectFile(char *path,char *name,char *date, bool showselected){

	DFLM datalist;

   long search;
#if WIN_32
   _finddata_t data;
#else
	DIR *data;
	struct dirent *file_entity;
#endif
   char fullpath[256];
   char filedate2[256];

   int fday,fmonth,fyear;
   int c1day,c1month,c1year;

   //if (!lc_readDate(initialdate,&tempday,&tempmonth,&tempyear)) return false;
   if (!lc_readDate(date,&fday,&fmonth,&fyear)) return false;

   strcpy(fullpath,path);
   strcat(fullpath,"/");

   
   if (strlen(name)<4){ // default number code if no given
      name[3] = 0;
      strcat(name,"153");
   }

   strcat(fullpath,name);
   strcat(fullpath,"*.*");

   
   // read entries
#if WIN_32
   search = _findfirst( fullpath, &data );
   if (search<0) return false;
   // strncpy(filedate,&data.name[7],8);
#else
   data = opendir(path);
   if(data == NULL) return false;
   file_entity = readdir(data);
   if(file_entity==NULL) {
	   closedir(data);
	   return false;
   }
   //strncpy(filedate,&file_entity->d_name[7],8);
#endif
/*
   filedate[8] = 0;
   lc_reverseDate(filedate);

   if (!lc_readDate(filedate,&c1day,&c1month,&c1year))  return false;
*/

   datalist.add(data.name);
	
/*

   tempday = 0;
   tempmonth = 0;
   tempyear = 0;

   name[0] = 0;

   int ycount=0, mcount=0, dcount=0;

   // check year
   if ((c1year<fyear)&&(c1year>=tempyear)){
      tempday = c1day;
      tempmonth = c1month;
      tempyear = c1year;
#if WIN_32
      strcpy(name,data.name);
#else
	  strcpy(name,file_entity->d_name);
#endif
   } else if (c1year==fyear){
      // check month
	  if (tempyear!=c1year) tempmonth = 0;
      if ((c1month<fmonth)&&(c1month>=tempmonth)){
         tempday = c1day;
         tempmonth = c1month;
         tempyear = c1year;
#if WIN_32
		 strcpy(name,data.name);
#else
		 strcpy(name,file_entity->d_name);
#endif
      } else if (c1month==fmonth){
         // check day
		  if ((tempmonth!=c1month)||(tempyear!=c1year)) tempday = 0;
		  if ((c1day<=fday)&&(c1day>=tempday)){
            tempday = c1day;
            tempmonth = c1month;
            tempyear = c1year;
#if WIN_32
			strcpy(name,data.name);
#else
			strcpy(name,file_entity->d_name);
#endif
         }
      }
   }
*/

#if WIN_32
#else
   file_entity = readdir(data);
#endif

#if WIN_32
   while(_findnext(search,&data)==0) {
      // strncpy(filedate,&data.name[7],8);
      datalist.add(data.name);
#else
   while(file_entity!=NULL) {
	  strncpy(filedate,&file_entity->d_name[7],8);
#endif
#if 0
	  filedate[8] = 0;
      lc_reverseDate(filedate);
      if (lc_readDate(filedate,&c1day,&c1month,&c1year)) {

      
   // check year
   if ((c1year<fyear)&&(c1year>=tempyear)){
      tempday = c1day;
      tempmonth = c1month;
      tempyear = c1year;
#if WIN_32
		 strcpy(name,data.name);
#else
		 strcpy(name,file_entity->d_name);
#endif
   } else if (c1year==fyear){
      // check month
	  if (tempyear!=c1year) tempmonth = 0;
      if ((c1month<fmonth)&&(c1month>=tempmonth)){
         tempday = c1day;
         tempmonth = c1month;
         tempyear = c1year;
#if WIN_32
		 strcpy(name,data.name);
#else
		 strcpy(name,file_entity->d_name);
#endif
      } else if (c1month==fmonth){
         // check day
		  if ((tempmonth!=c1month)||(tempyear!=c1year)) tempday = 0;
         if ((c1day<=fday)&&(c1day>=tempday)){
            tempday = c1day;
            tempmonth = c1month;
            tempyear = c1year;
#if WIN_32
		 strcpy(name,data.name);
#else
		 strcpy(name,file_entity->d_name);
#endif
         }
      }
   }
      /*
         if (wyear>fyear){
            ayear = fyear;
            amonth = fmonth;
            aday = wday;
         } else if(wyear==fyear){
            if (wmonth>fmonth){
               ayear = fyear;
               amonth = fmonth;
               aday = wday;
            } else if(wmonth == wyear){
               if (wday>fday){
                  ayear = fyear;
                  amonth = fmonth;
                  aday = wday;
               }
            }
         }
      
      /*
         if ((fyear<=wyear)&&(fyear>=ayear)){ // check year
            if (fyear==wyear){
               if ((fmonth<=wmonth)&&(fmonth>=amonth)){ // check month
                  if (fmonth==wmonth){
                     if ((fday<=wday)&&(fday>=aday)){ // check day
                        aday = fday;
                        amonth = fmonth;
                        ayear = fyear;
                        strcpy(name,data.name);
                     }
                  }
               }
            }
         }
*/
  
    }
#endif

   }

#if WIN_32
   _findclose(search);
#else
   closedir(data);
#endif

	datalist.sort();
	strcpy(name,datalist.search(fday,fmonth,fyear));

   DFLM::datafilelist *datefile;

   datefile = datalist.first();
   
   int k1,k2;
   if(showselected){
      printf("\n\nFiles disponible and selected:\n\n");
      
      k1 = 0;
      k2 = datalist.searchn(fday,fmonth,fyear);

      while(datefile!=NULL){
         k1++;


	  strncpy(filedate2,&datefile->filename[7],8);
	  filedate2[8] = 0;
      lc_reverseDate(filedate2);
      lc_readDate(filedate2,&c1day,&c1month,&c1year);

         if (k1==k2) {
			 printf("\n>>>>> SELECTED >>>>> ");
             printf("%s  --> calibration date: %i/%i/%i\n\n",strhigher(datefile->filename),c1day,c1month,c1year);
		 }
		 else {
			 printf("                     ");
			printf("%s  --> calibration date: %i/%i/%i\n",datefile->filename,c1day,c1month,c1year);
		 }
         
         datefile = datalist.next();
      }
   }


   if (strlen(name)>0){
	   strcpy(fullpath,path);
	   strcat(fullpath,"/");
	   strcat(fullpath,name);
	   strcpy(name,fullpath);
	   return true;
   }
   return false;
}

int lc_readMonth(char *month){
   int len,i,result;
   char *trimmed;
   bool done;

   done = false;
   
   trimmed = lc_strTrim(month);
   strhigher(trimmed);

   // take only month name 
   while(!done) {
      len = strlen(trimmed);
      for (i=0;i<len;i++){
         if ((trimmed[i] < 48)||((trimmed[i] > 57)&&(trimmed[i] < 65))||(trimmed[i] > 90)) {
            if (i==0) trimmed++;
            else trimmed[i] = 0;
            break;
         }
      }
      if (i==len) done = true;
      if (len<=0) return 0;
   }

   // check for numerical name 
   switch (trimmed[0]){
   case 48:
      result = trimmed[1]-48;
      break;
   case 49:
      result = trimmed[1]-48 + 10;
      break;
   default:
      done = false;
   }
   
   if (done) return result;

   // check for string name
   if ((strcmp(trimmed,"JAN") &&
       strcmp(trimmed,"GEN") &&
       strcmp(trimmed,"JANUARY") &&
       strcmp(trimmed,"GENNAIO")) == 0   
       ) return 1;
   if ((strcmp(trimmed,"FEB") &&
       strcmp(trimmed,"FEBRUARY") &&
       strcmp(trimmed,"FEBBRAIO")) == 0   
       ) return 2;
   if ((strcmp(trimmed,"MAR") &&
       strcmp(trimmed,"MARCH") &&
       strcmp(trimmed,"MARZO")) == 0   
       ) return 3;
   if ((strcmp(trimmed,"APR") &&
       strcmp(trimmed,"APRIL") &&
       strcmp(trimmed,"APRILE")) == 0   
       ) return 4;
   if ((strcmp(trimmed,"MAY") &&
       strcmp(trimmed,"MAG") &&
       strcmp(trimmed,"MAGGIO")) == 0   
       ) return 5;
   if ((strcmp(trimmed,"JUN") &&
       strcmp(trimmed,"GIU") &&
       strcmp(trimmed,"JUNE") &&
       strcmp(trimmed,"GIUGNO")) == 0   
       ) return 6;
   if ((strcmp(trimmed,"JUL") &&
       strcmp(trimmed,"LUG") &&
       strcmp(trimmed,"JULY") &&
       strcmp(trimmed,"LUGLIO")) == 0   
       ) return 7;
   if ((strcmp(trimmed,"AUG") &&
       strcmp(trimmed,"AGO") &&
       strcmp(trimmed,"AUGUST") &&
       strcmp(trimmed,"AGOSTO")) == 0   
       ) return 8;
   if ((strcmp(trimmed,"SEP") &&
       strcmp(trimmed,"SET") &&
       strcmp(trimmed,"SEPTEMBER") &&
       strcmp(trimmed,"SETTEMBRE")) == 0   
       ) return 9;
   if ((strcmp(trimmed,"OCT") &&
       strcmp(trimmed,"OTT") &&
       strcmp(trimmed,"OCTOBER") &&
       strcmp(trimmed,"OTTOBRE")) == 0   
       ) return 10;
   if ((strcmp(trimmed,"NOV") &&
       strcmp(trimmed,"NOVEMBER") &&
       strcmp(trimmed,"NOVEMBRE")) == 0   
       ) return 11;
   if ((strcmp(trimmed,"DEC") &&
       strcmp(trimmed,"DIC") &&
       strcmp(trimmed,"DECEMBER") &&
       strcmp(trimmed,"DICEMBRE")) == 0   
       ) return 12;

   return 0;
}

bool lc_readDate(char *date, int *day, int *month, int *year){

   char temp[256];
   int len;

   strcpy(temp,date);
   len  = strlen(temp);
   sscanf(&temp[len-4], "%i", year);
   temp[2] = 0;
   sscanf(temp, "%i", day);
   temp[len-4] = 0;
   temp[2] = date[2];
   *month = lc_readMonth(&temp[2]);
   if (*month==0) return false;
   return true;
}

char *lc_reverseDate(char *string){
   char temp[256];

   strcpy(temp,&string[6]);
   string[6] = 0;
   strcat(temp,&string[4]);
   string[4] = 0;
   strcat(temp,string);

   strcpy(string,temp);

   return string;
}

bool DFLM::sortSingle(DFLM::datafilelist *e1, DFLM::datafilelist *e2){

	datafilelist *tempp, *tempc, *A, *B;
	tempp = e1;
	tempc = e2;
	bool inversion = false;

	bool change = false;

	if (tempp->year > tempc->year) change = true;
	if ((tempp->year==tempc->year)&&(tempp->month > tempc->month)) change = true;
	if (((tempp->year==tempc->year)&&(tempp->month == tempc->month))&&(tempp->day > tempc->day)) change = true;

   A = tempp->prev;
   B = tempc->next;
   
	if (change){
		if (tempp == filelist){

         filelist = tempc;

         B->prev = tempp;
         tempp->prev = tempc;
         tempp->next = B;
         tempc->prev = A;
         tempc->next = tempp;

         return true;
		}
		A->next = tempc;
      if (B!=NULL) B->prev = tempp;
      tempp->prev = tempc;
      tempp->next = B;
      tempc->prev = A;
      tempc->next = tempp;

      sortSingle(A, tempc);
		inversion = true;
	}
	return inversion;
}



void DFLM::sort(){
	datafilelist *tempp, *tempc;
	bool inversion;
		
	tempp = filelist;
	if (tempp==NULL) return;
	tempc = filelist->next;
	while(tempc != NULL){

		inversion = sortSingle(tempp,tempc);

		if(!inversion){
			tempp = tempc;
			tempc = tempc->next;
		} else tempc = tempp->next;
	}

}

char *DFLM::search(int day,int month, int year){
	datafilelist *temp;
	bool found = false;
	temp = filelist;

   if (temp==NULL) return NULL;

	while(temp->next != NULL) temp = temp->next;

	while((temp != NULL)&&(!found)){
		if (temp->year > year) {
			temp = temp->prev;
         continue;
		}
		if ( (temp->year == year)&&(temp->month > month)) {
			temp = temp->prev;
         continue;
		}

		if ( ( (temp->year == year)&&(temp->month == month)) &&(temp->day > day)) {
			temp = temp->prev;
			continue;
		}
		found = true;
	}
	
	if (!found) return NULL;

	return temp->filename;

}

unsigned int DFLM::searchn(int day,int month, int year){
	datafilelist *temp;
	bool found = false;
	temp = filelist;
   unsigned int k;

   k = 1;

   if (temp==NULL) return 0;

   while(temp->next != NULL) {
      temp = temp->next;
      k++;
   }

	while((temp != NULL)&&(!found)){
		if (temp->year > year) {
			temp = temp->prev;
         k--;
			continue;
		}
		if ( (temp->year == year)&&(temp->month > month)) {
			temp = temp->prev;
         k--;
			continue;
		}

		if ( ( (temp->year == year)&&(temp->month == month)) &&(temp->day > day)) {
			temp = temp->prev;
         k--;
			continue;
		}
		found = true;
	}
	
	if (!found) return 0;

	return k;

}


bool lc_getDataPath(char *path,int type){
	char inidir[256],env_path_root[256], env_path_raw[256], env_path_cal[256];
	iniFileStruct *ifs;
	
	/*******************************/
	/*  Get environment variables  */
	/*******************************/
	
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
			return false;
		}
		
	}
	
	if (lc_iniReadValue(ifs,"paths","data_root",INI_STRING,env_path_root)==NULL)
		strcpy(env_path_root,_DATA_ROOT);
	
	if (lc_iniReadValue(ifs,"paths","raw_data",INI_STRING,env_path_raw) == NULL)
		strcpy(env_path_raw,_DATA_RAW);
	
	if (lc_iniReadValue(ifs,"paths","cal_data",INI_STRING,env_path_cal)==NULL)
		strcpy(env_path_cal,_DATA_CAL);
	
	lc_iniClose(ifs);
	
	if (checkDir(env_path_root[strlen(env_path_root)-1])) env_path_root[strlen(env_path_root)-1] = 0;
	if (checkDir(env_path_raw[strlen(env_path_raw)-1])) env_path_raw[strlen(env_path_raw)-1] = 0;
	if (checkDir(env_path_cal[strlen(env_path_cal)-1])) env_path_cal[strlen(env_path_cal)-1] = 0;
	
	switch(type){
	case 0:	// MEG data path
		strcpy(path,env_path_root);
		break;
	case 1:	// RAW data path
		strcpy(path,env_path_raw);
		break;
	case 2:	// CALIBRATION data path
		strcpy(path,env_path_cal);
		break;
	}

	return true;

}




int round(double value){
	int val;

	if(value>0){
		val = (int)floor(value);
		if((value - val)>0.5) return (int)ceil(value);
		return val;
	}else{
		val = (int)floor(value);
		if((value - val)>0.5) return (int)ceil(value);
		return val;
	}
}

double lc_cos(double Degrees)
{
    double ret;
    double off = (Degrees / 30 - round(Degrees / 30));
    if (off < .0000001 && off > -.0000001)
    {
        int iDegrees = (int)round(Degrees);
        iDegrees = (iDegrees < 0) ? (360 - (-iDegrees % 360))  : (iDegrees % 360);
        switch (iDegrees)
        {
            case 0: ret=1.0; break;
            case 30: ret=0.866025403784439; break;
            case 60: ret=0.5; break;
            case 90: ret=0.0; break;
            case 120: ret=-0.5; break;
            case 150: ret=-0.866025403784439; break;
            case 180: ret=-1.0; break;
            case 210: ret=-0.866025403784439; break;
            case 240: ret=-0.5; break;
            case 270: ret=0.0; break;
            case 300: ret=0.5; break;
            case 330: ret=0.866025403784439; break;
            case 360: ret=1.0; break;
            default: ret=cos(Degrees * 3.14159265358979 / 180);  // it shouldn't get here
        }
        return ret;
    }
    else
        return cos(Degrees * 3.14159265358979 / 180);
}

double lc_sin(double Degrees)
{
    return lc_cos(Degrees+90);
}

void fnsplit(char *importedfname, filename_split_struct *strsplt){
	char *temp;
	char fname[256];

	strcpy(fname,importedfname);


	temp = strrchr(fname,'.');
	if(temp==NULL) strsplt->ext[0] = 0;
	else {
		strcpy(strsplt->ext,temp);
		temp--;
		if(temp[0] != '.') temp++;
		temp[0] = 0;
	}

	temp = strrchr(fname,'/');
	if(temp==NULL) temp = strrchr(fname,'\\');
	if(temp==NULL) {
		strcpy(strsplt->name,fname);
		strsplt->dir[0] = 0;
		return;
	}
	
	strcpy(strsplt->name,++temp);
	temp--;

	temp[0] = 0;

	strcpy(strsplt->dir,fname);
}


bool lc_logFileAppend(char *logname, char info[][256], int nlines){

	FILE *fp;
	int i;
    char tmpbuf[128],time[256];

    /* Display operating system-style date and time. */
#if WIN_32
    _strdate( tmpbuf );
	strcpy(time,"//   Date: ");
	strcat(time,tmpbuf);
    _strtime( tmpbuf );
	strcat(time," - Time: ");
	strcat(time,tmpbuf);
#endif

	fp = fopen(logname,"at");

	if(fp==NULL) return false;

	fprintf(fp,"\n%s\n",time);
	for(i=0;i<nlines;i++){
		fprintf(fp,"%s\n",info[i]);
	}

	fclose(fp);

	return true;

}

char *subChar(char* string, char from, char to){
	char *temp;

	temp = string;

	while(temp!=NULL){
		temp = strchr(string,from);
		if(temp!=NULL) temp[0] = to;
	}

	return string;
}

/*
int lc_readData(double **data,header640 *info,int nchan,int *ch_list,long startData,long widthData,char *fname){

	const elabPoints = 100;
	FILE *fp;
	int npt;
	long totAddedPoints = 0;
	float **DATA;
	
	

	fp = fopen(fname,"rb");
	if(fp==NULL) return -1;

	

	if( (startData-elabPoints)>=0 ) {
		startData -= elabPoints;
		totAddedPoints += elabPoints;
	}

	if( (startData + widthData + elabPoints + totAddedPoints) < info->ntpdata  ) {
		totAddedPoints += elabPoints;
		widthData += totAddedPoints;
	}


	npt = vp_read_data(DATA,*info,nchan,ch_list,startData,widthData,fp);
	
	




}
*/