/**************************************************************


	LC_SUPPORT: various support functions



   Coded by Luca Ciancetta
	Version 1.0

   Date: march-19, 2003

***************************************************************/

#if !defined( LC_SUPPORT_H )
#define LC_SUPPORT_H

#include "vp_biomag.h"
#include "lcmat_matrix.h"

#define LC_DLL_FUNCTION

/*********************************

   LC library response constants

*********************************/

#define LC_OK     0
#define LC_ERROR  1
#define LC_NOMEM  2
#define LC_NARGS  3

/*******************************

  General

*******************************/

void quit(int code=0);
bool checkDir(char );

/*******************************

  Parses an array of chars

*******************************/
LC_DLL_FUNCTION int lc_parse(const char*,int,char*,...);
char * strlower(char *);
char * strhigher(char *);

typedef enum {
   INI_INTEGER = 0,
   INI_DOUBLE,
   INI_FLOAT,
   INI_BOOL,
   INI_STRING
}iniTypeKey;

typedef enum {
   INI_READ = 0,
   INI_WRITE,
   INI_WRITE_LOCAL
}iniOpenType;

typedef struct {
   char fname[256];
   char path[256];
   bool masterProgPath;
   FILE *fpointer;
   char mpointer[10000][256];
   int size;
   iniOpenType mode;
}iniFileStruct;

typedef struct {
	char name[256];
	char dir[256];
	char ext[256];
}filename_split_struct;


iniFileStruct *lc_iniOpen(char *fname, iniOpenType ot);
void lc_iniClose(iniFileStruct *fo);
char *lc_strTrim(char *string);
char *lc_iniGetSection(char *string);
bool lc_iniRemoveSection(char *string);
bool lc_iniRemoveKey(char *string,void *value, iniTypeKey tk);
char *lc_iniGetKey(char *string,void *value, iniTypeKey tk);
void *lc_iniReadValue(iniFileStruct *fo,char* section,char *key,iniTypeKey tk,void *value);
int lc_iniWriteValue(iniFileStruct *fo,char* section,char *key,iniTypeKey tk,void *value);
header vp_header640_to_header(header640 info640);

char* lc_reverseDate(char *string);

int lc_readMonth(char *month);
bool lc_readDate(char *date, int *day, int *month, int *year);


void fnsplit(char *fname, filename_split_struct *strsplt);
char *subChar(char* string, char from, char to);

/*****************************************************


	class to manage dated file list


******************************************************/

class DFLM{

public:
	struct datafilelist;
	struct datafilelist{
		char filename[250];
		int year;
		int month;
		int day;

		bool status;

		datafilelist *prev;
		datafilelist *next;
	};

private:
	datafilelist *filelist;

   datafilelist *cursor;

   unsigned int counter;
   
	bool sortSingle(datafilelist *e1, datafilelist *e2);
	
	public:

	DFLM(){ filelist=NULL; cursor = NULL; counter = 0;};
	~DFLM(){ clear(); };

	void add(char *fname){
	   char filedate[256];
		datafilelist *temp;

		if (filelist==NULL){
			filelist = new datafilelist;
			filelist->prev = NULL;
			filelist->next = NULL;
			temp = filelist;
		} else {
			temp = filelist;
			while(temp->next!=NULL){
				temp = temp->next;
			}
			temp->next = new datafilelist;
			temp->next->prev = temp;
			temp->next->next = NULL;
			temp = temp->next;
		}

		
		strcpy(temp->filename,fname);
		
 	    strncpy(filedate,&fname[7],8);
		filedate[8] = 0;
		lc_reverseDate(filedate);

	   temp->status = lc_readDate(filedate,&(temp->day),&(temp->month),&(temp->year));

      counter++;
	}

	void clear(){
		datafilelist *temp;
		temp = filelist;
		while(filelist != NULL){
			temp = filelist->next;
			delete filelist;
			filelist = temp;
		}

      cursor = NULL;
      counter = 0;
	}

	void sort();

	char *search(int day,int month, int year);

   unsigned int searchn(int day,int month, int year);

   datafilelist *first() {
      cursor = filelist;
      return cursor;
   };

   datafilelist *last(){ 
      datafilelist *temp , *temp2;
      temp = filelist;
      temp2 = filelist;
      while(temp!=NULL){
         temp2 = temp;
         temp = temp->next;
      }
      cursor = temp2;
      return cursor;
   };


   datafilelist *next() {
      if (cursor==NULL) return NULL;
      if (cursor->next == NULL) return NULL;
      cursor = cursor->next;
      return cursor;
   }

   datafilelist *prev() {
      if (cursor==NULL) return NULL;
      if (cursor->prev == NULL) return NULL;
      cursor = cursor->prev;
      return cursor;
   }

   unsigned int count() {return counter;};
};

/*******************************************************************************


/************************************************


   
     BIOMAG640 FUNCTIONS
   


***********************************************/

bool lc_selectFile(char *path,char *name,char *date, bool showselected=false);
bool lc_getDataPath(char *path,int type = 0); // return MEG/RAW data path


/************************************************

   
     LIST of ITEMS


***********************************************/

template <class T> struct lc_item{
		lc_item *prec;
		lc_item *next;
		int index;
		T value;
};

template <class T> class lc_itemsList{

	
	public:
		// constructor
		lc_itemsList(){
			list = NULL;
			this->current = NULL;
			itemCount = 0;
		}
	
		// destructor
		~lc_itemsList(){
			clear();
		}

		bool set(int index, T value){
			lc_item<T> *current;
			
			current = getItemIndex(index);
			if(current==NULL) return false;

			current->value = value;

			return true;
		}

		bool add(T value, int index){

			lc_item<T> *current;

			// item existent
			if(getItemIndex(index)!=NULL) return false; 

			add(value);
			current = getLastItem();
			current->index = index;

			return true;

		}

		int add(T value){
			lc_item<T> *current;
			int newindex;

			current = getLastItem();

			if(current==NULL){
				current = new lc_item<T>;
				current->index = 0;
				current->value = value;
				current->prec = NULL;
				current->next = NULL;
				list = current;
				itemCount++;
				return current->index;
			}

			newindex = current->index + 1;

			// search for a not existent index
			while(getItemIndex(newindex)!=NULL) newindex++;
		
			current->next = new lc_item<T>;
			current->next->index = newindex;
			current->next->value = value;
			current->next->prec = current;
			current->next->next = NULL;

			itemCount++;

			return current->next->index;
		}

		void clear(){
			lc_item<T> *current, *pre;
			if(list==NULL) return;
			current = getLastItem();
			while(current!=NULL){
				pre = current->prec;
				delete current;
				current = pre;
			}
			list = NULL;
			this->current = NULL;
			itemCount =0;
		}

		bool getValue(int index, T* result){
			lc_item<T> *current;
			
			current = getItemIndex(index);
			if(current==NULL) {
				return false;
			}

			*result = current->value;
			return true;
		}

		int count(){
//			if(list==NULL) return 0;
//			return (getLastItem()->index + 1);
			return itemCount;
		}

		bool getLastValue(T* result){
			if((this->current = getLastItem()) == NULL) {
				result = NULL;
				return false;
			}
			*result = (this->current->value);
			return true;
		}

		bool getFirstValue(T* result){
			if((this->current = getFirstItem()) == NULL) {
				result = NULL;
				return false;
			}
			*result = (this->current->value);
			return true;
		}

		bool getNextValue(T* result){
			if((this->current = this->current->next) == NULL)  {
				result = NULL;
				return false;
			}
			*result = (this->current->value);
			return true;
		}

	private:
		lc_item<T> *getItemIndex(int index){
			lc_item<T> *current;
			
			current = list;
			while(current != NULL)
				if(current->index == index) return current;
				else current = current->next;

			return NULL;
		}

		lc_item<T> *getLastItem(){
			lc_item<T> *current;
			
			if(list==NULL) return NULL;
			current = list;
			while(current->next != NULL) current = current->next;

			return current;
		}

		lc_item<T> *getFirstItem(){
			this->current = list;
			return list;
		}



		lc_item<T> *current;
		lc_item<T> *list;
		int itemCount;

};




/************************************************

   
     MATHEMATICS


***********************************************/

int round(double value);

//Prevent Float Errors with Cos and Sin
double lc_cos(double Degrees);

double lc_sin(double Degrees);

void lc_projection(double *referenceMatrix,double *orig_vector,double *proj_vector );
int lc_antiprojection(double *referenceMatrix,double *orig_vector,double *proj_vector );

bool lc_logFileAppend(char *logname, char info[][256], int nlines);

#endif // LC_SUPPORT_H


/************************************************

   
     VP Library support


***********************************************/

#ifndef FILE_ACTION

#define FILE_ACTION

typedef struct
{
	int             tri_chan;        /*  trigger_channel           0-Do not compute  */
	int             ttl_type;        /*  ttl trigger               0-FALSE  1-TRUE   */
	int             invert_tri;      /*  invert trigger polarity   0-FALSE  1-TRUE   */
	int             hrt_file;        /*  generate .hrt file        0-FALSE  1-TRUE   */
	int             hrt_chan;        /*  heart channel */
	int             eye_file;        /*  generate .eye file        0-FALSE  1-TRUE   */
	int             v_eye_chan;        /*  Vertical EOG channel */
	int             h_eye_chan;        /*  Horizontal EOG channel */
} file_action;

#endif

int lc_findTriggerList(FILE *fp_in, header640 *info,int nnotch, float *rejfreq,float *notch_window, file_action fl,bool, char);
bool lc_tgTypeAnaAna(header640 *info, int nch, float **rdata,int ndatapoints, int nnotch, float *rejfreq,float *notch_window, file_action fl,int offset);
bool lc_tgTypeAnaDig(header640 *info,  float **rdata,int ndatapoints, int nnotch, float *rejfreq,float *notch_window, file_action fl,int offset);
bool lc_tgTypeDigDig(header640 *info,  float **rdata,int ndatapoints, file_action fl, int offset,bool mtEncoded, char mtConfirm);
bool lc_tgTypeDigDig_safe1(header640 *info,  float **rdata,int ndatapoints, file_action fl, int offset);
//int	 lc_readData(double **data,header640 *info,int nchan,int ch_list,long startData,long widthData,char *fname);