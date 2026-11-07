/****************************************************************************/
/*                                                                          */
/*  Define constants, structures and functions for vp biomagnetic programs  */
/*                                                                          */
/*  Language : ANSI C                                                       */
/*  Author   : Vittorio Pizzella                                            */
/*                                                                          */
/*  Feb 18, 2002 - 13.0.0     First version                                 */
/*  Jan 27, 2003 - 14.0.0     First little endian/big endian version        */
/*                            Up to 640 channels                            */
/*  Jun 29, 2003 - 14.0.1     Updated defaults                              */
/*  Apr 29, 2004 - 14.0.4     Increased MAXBUFFER                           */
/*  Feb  5, 2008 - 14.1.0     Added trig_sel structure                      */
/*  Mar  8, 2009 - 14.2.0     Added BMDSYS function prototyping             */
/*                                                                          */
/****************************************************************************/




#ifndef _VP_BIOMAG_INCLUDED
#define _VP_BIOMAG_INCLUDED
#endif

/*******************************/
/*  User definable parameters  */
/*******************************/

#ifndef  MAXBUFFER
#define  MAXBUFFER       48          /* Maximum buffer size in Mbytes */ 
#endif

#ifndef  LE_CPU
#define  LE_CPU          TRUE
#endif

#ifndef  WIN_32
#define  WIN_32          TRUE
#endif

#ifndef  SB_HW
#define  SB_HW           FALSE
#endif

/* Programs & libraries ROOT */
#ifndef _ROOT
#define _ROOT "c:/biomag640/"
#endif

/* Data ROOT */
#ifndef _DATA_ROOT
#define _DATA_ROOT "c:/data/"
#endif

/* Data RAW */
#ifndef _DATA_RAW
#define _DATA_RAW "c:/data/rawdata/"
#endif

/* Data CALIBRATION */
#ifndef _DATA_CAL
#define _DATA_CAL "c:/biomag640/config/"
#endif

/**********************/
/*  Define constants  */
/**********************/

#ifndef  VP_LIB_VERSION
#define  VP_LIB_VERSION  144
#endif

#ifndef  PI
#define  PI  3.14159265
#endif

#ifndef  _DPI
#define  _DPI  3.1415926536
#endif

#ifndef  TRUE
#define  TRUE  1
#endif

#ifndef  FALSE
#define  FALSE 0
#endif

/***********************/
/*  Define structures  */
/***********************/

typedef struct
{
   float comp[3];
} vp_vector;

typedef struct
{
   double comp[3];
} vp_dvector;

typedef struct
{
   float x;
   float y;
   float z;
} xpos;

typedef struct
{
   float th;
   float fi;
   float rd;
} apos;

typedef struct
{
   vp_vector  r_s;
   vp_vector  u_s;
   float      angle_s;
   float      baseline;
} ch_position;

typedef struct
{
   vp_vector  r_s;
   vp_vector  u_s;
} position;


typedef struct
{
   int    type;                 /* type   0 - no filter                            */
                                /*        1 - bandpass  - param[0]: highpass freq  */
                                /*                      - param[1]: lowpass freq   */    
                                /*        2 - notch     - param[0]: notch freq 1   */
                                /*                        param[1]: notch freq 2   */    
                                /*                        param[2]: notch freq 3   */    
                                /*                        param[3]: notch freq 4   */    
                                /*                        param[4]: span           */    
                                /*        3 - artifact  - param[0]: True/False     */    
                                /*        4 - adaptive  - param[0]: True/False     */    
                                /*        5 - rectifier - param[0]: True/False     */    
                                /*        6 - heart     - param[0]: True/False     */    
                                /*        7 - evoked    - param[0]: True/False     */    
                                /*        8 - derivate  - param[0]: True/False     */    
                                /*        9 - polarity  - param[0]: True/False     */    
   float  param[5];             /* up to 5 filter parameters                       */
} gen_flt;



typedef struct
{
   int     apply_filter;         /*  do filtering     0 - FALSE   1 - TRUE  */
   int     invert_polarity;         
   float   lowpass;         
   float   highpass;        
   gen_flt filt[10];             /*  generic filter                         */
} vp_filter;


typedef struct
{
   unsigned char   type;           /*  type      0 - unknown             */
                                   /*            1 - ele                 */
                                   /*            2 - mag                 */
                                   /*            4 - ele ref             */
                                   /*            8 - mag ref             */
                                   /*           16 - aux                 */
                                   /*           32 - param               */
                                   /*           64 - digit               */
                                   /*          128 - flag                */
   int             number;         /*  number                            */
   char            label[16];      /*  label                             */
   unsigned char   flag;           /*  on/off flag 0 - working channel   */
                                   /*              1 - noisy channel     */
                                   /*              2 - very noisy channel*/
                                   /*              3 - broken channel    */
   float           amvbit;         /*  calibration from LSB to mV        */
   float           calib;          /*  calibration from mV to unit       */
   char            unit[6];        /*  unit label  (fT, uV, ...)         */
   int             ncoils;         /*  number of coils building up one channel */
   float           wgt[10];        /*  weight of coils                   */
   position        pos[10];        /*  position and orientation of coils */
} ch_info;



typedef struct
{
   int             start;     /*  Starting time point from beginning of data       */
   int             ntptot;    /*  Total number of time points                      */
   int             ntppre;    /*  Number of points in pretrigger                   */
   int             type;
   int             quality;
} sample_info;



typedef struct
{
   int    digital_trigger;    /*  digital trigger           0-FALSE  1-TRUE (Chieti)
                                                                     2-TRUE (Rome)   */
   int    tri_chan;           /*  trigger channel                                    */
                              /*  used only if analog trigger:                       */

   int    optic_sensor;       /*  use optic sensor          0-FALSE  1-TRUE          */
   int    code_id;            /*  code identification       0-FALSE  1-TRUE          */
   int    invert_tri;         /*  trigger inversion         0-FALSE  1-TRUE          */
} trig_sel;



typedef struct
{
   char    sex;         /*  Sex (M or F)           */
   char    notes[256];  /*  Notes on subject       */
   float   height;      /*  Height in cm           */
   float   weight;      /*  Weight in kg           */
   int     birthday;    /*  Birtday (1-31)         */
   int     birthmonth;  /*  Birthmonth (1-12)      */
   int     birthyear;   /*  Birthyear (1900-2002)  */
} subj;



typedef struct
{
   int     start;       /*  Starting time point from beginning of data       */
   int     ntptot;      /*  Total number of time points                      */
   int     type;
   int     no_samples;
   int     st_sample;
} segment_info;



typedef struct
{
/*  Name of structure  */
   char    stname[10];           /*  Header identifier  (VP_BIOMAG)                */
   char    stver[8];             /*  Header version                                */
   char    stendian[4];          /*  LE (little endian) or BE (big endian) format  */
   
/*  Subject's INFOs  */
   char    first_name[32];       /*  Subject's first name   */
   char    last_name[32];        /*  Subject's family name  */
   char    id[32];               /*  Subject's id           */
   char    notes[256];           /*  Notes on measurement   */
   subj    sub_info;             /*  Other subj infos       */
   
/*  Data acquisition INFOs  */
   char    time[12];             /*  time (ascii)  */
   char    date[16];             /*  date (ascii)  */

   int     nchan;                /*  total number of channels               */
   int     nelech;               /*  number of electric channels            */
   int     nelerefch;            /*  number of electric reference channels  */
   int     nmagch;               /*  number of magnetic channels            */
   int     nmagrefch;            /*  number of magnetic reference channels  */
   int     nauxch;               /*  number of auxiliary channels           */
   int     nparamch;             /*  number of parameter channels           */
   int     ndigitch;             /*  number of digit channels               */
   int     nflagch;              /*  number of flag channels                */

   int     data_type;            /*  0 - BE_SHORT      (HP-PA, big endian)     */
                                 /*  1 - BE_LONG       (HP-PA, big endian)     */
                                 /*  2 - BE_FLOAT      (HP-PA, big endian)     */
                                 /*  3 - LE_SHORT      (Intel, little endian)  */
                                 /*  4 - LE_LONG       (Intel, little endian)  */
                                 /*  5 - LE_FLOAT      (Intel, little endian)  */
                                 /*  6 - RTE_A_SHORT   (HP-A900, big endian)   */
                                 /*  7 - RTE_A_FLOAT   (HP-A900, big endian)   */
                                 /*  8 - ASCII                                 */
   
   float   smpfq;                /*  sampling frequency in Hz                     */
   float   hw_low_fr;            /*  hw data acquisition low pass filter          */
   float   hw_hig_fr;            /*  hw data acquisition high pass filter         */
   int     hw_comb;              /*  hw data acquisition 50 Hz filter  (1-TRUE)   */
   float   sw_hig_tc;            /*  sw data acquisition high pass time constant  */
   int     compensation;         /*  0 - no compensation    1 - compensation  */
   int     ntpdata;              /*  total number of time points in data      */

   int     no_segments;          /*  Number of segments described in the segment structure   */
   segment_info  sgmt[5];        /*  INFOs on different segments  */
   int     nsmpl;                /*  Overall number of samples    */
   sample_info  smpl[4096];      /*  INFOs on different samples   */

   int     nrefchan;             /*  number of reference channels              */
   int     ref_ch[640];          /*  reference channel list                    */
   int     ntpref;               /*  total number of time points in reference  */

/*  Header INFOs  */
   int     raw_header_type;      /*  0  - Unknown header                       */
                                 /*  2  - rawfile (A900)                       */
                                 /*  3  - GE runfile header                    */
                                 /*  31 - ATB runfile header version 1.0       */
                                 /*  41 - IFN runfile header version 1.0       */
                                 /*  51 - BMDSys runfile header version 1.0    */
   
   int     header_type;          /*  0  - Unknown header                       */
                                 /*  2  - rawfile (A900)                       */
                                 /*  3  - GE runfile header                    */
                                 /*  4  - old header                           */
                                 /*  10 - 256ch normal header                  */
                                 /*  11 - 256ch master header                  */
                                 /*  20 - 640ch normal header                  */
                                 /*  21 - 640ch master header                  */
                                 /*  31 - ATB runfile header version 1.0       */
                                 /*  41 - IFN runfile header version 1.0       */
                                 /*  51 - BMDSys runfile header version 1.0    */

   char    conf_file[64];        /*  Filename used for data acquisition configuration  */
     
   int     header_size;          /*  sizeof(header) at the time of file creation  */   
   int     start_reference;      /*  start reference   */
   int     start_data;           /*  start data        */
        
   int     rawfile;              /*  0 - not a rawfile      1 - rawfile     */
   int     multiplexed_data;     /*  0 - FALSE              1 - TRUE        */
   
   int     isns;              /*  sensor code   1 - Single channel                        */  
                              /*               28 - Original Rome 28 ch.                  */
                              /*               29 -  ..............                       */
                              /*               .. -  ..............                       */
                              /*               45 - Updated Rome 28 ch. (spring 2009)     */
                              /*               .. -  ..............                       */
                              /*               .. -  ..............                       */
                              /*               55 - Original Chieti 55 ch. flat           */
                              /*              153 - Original Chieti 153 ch. helmet        */
                              /*              154 - Chieti 153 ch. helmet from Jan 2002   */


   ch_info    ch[640];           /*  Channel's INFOs  */

/*  Sensor position INFOs  */

   vp_vector  r_center;          /*  sensor position in convenient format */
   vp_vector  u_center;
   float      th_center;         /*  sensor orientation as from markers fit */
   float      fi_center;
   float      rotation_angle;
   vp_vector  cosdir[3];         /*  for compatibility only */
   int        irefsys;           /*  reference system   0 - sensor reference system  */
                                 /*                     1 - Polhemus                 */
                                 /*                     2 - head3                    */
                                 /*                     3 - MEG                      */

/*  Marker positions for MRI integration  */
   int          num_markers;     /*  Total number of markers                        */
   int          i_coil[64];      /*  Markers to be used to find sensor position     */
   position     marker[64];      /*  Position of all the markers                    */
   float        best_chi;        /*  Best chi_square value obtained in finding sensor position */

   float   cup_vertex_center;    /*  distance of sensor center from vertex  (as entered */
                                 /*  from keyboard)                                     */
   float   cup_fi_center;        /*  fi angle of sensor center             */
   float   cup_rotation_angle;   /*  rotation angle of sensor center axis  */

   float   dist_a1_a2;           /*  head informations  */
                                 /*  (used to find subject's head dimensions) */
   float   dist_inion_nasion;
   float   max_circ;
   float   nasion_vertex_inion;

/*  Data analysis INFOs  */
   int     security;          /*  security flag                      */
   int     ave_alignement;    /*  average data alignement 0 - FALSE  */
                              /*                          1 - TRUE   */
   
   int     itri;              /*  trigger channel number             */
   int     ntpch;             /*  no. of time points per channel     */
   int     ntppre;            /*  no. of time points of pretrigger   */
   int     navrg;             /*  no. of averages                    */
   int     nover;             /*  no. of discarded averages          */
   int     nave_filt;         /*  no. of applied filters             */
   gen_flt ave_filt[15];      /*  Filters used before average        */

   int     stdev;             /*  0 - not present                    */
   int     bas_start;         /*  starting data points for baseline  */
   int     bas_end;           /*  ending data points for baseline    */

   int     source_files[32];  /*  Progressive number of files (if more than one)  */

/*  template INFOs  */
   int     ichtpl;
   int     ntptpl;
   int     ifitpl;
   float   corlim;
   gen_flt tpl_filt[15];      /*  Filters used before template       */

/*  Just in case info  */
   int dummy[64];

} header640;



typedef struct
{
/*  Name of structure  */
   char    stname[10];           /*  Header identifier  */

/*  Subject's INFOs  */
   char    first_name[32];       /*  Subject's first name   */
   char    last_name[32];        /*  Subject's family name  */
   char    id[32];               /*  Subject's id           */
   char    notes[256];           /*  Notes on subject       */

/*  Data acquisition INFOs  */
   char    time[12];             /*  time (ascii)  */
   char    date[16];             /*  date (ascii)  */

   int     nchan;                /*  number of channels            */
   int     nelech;               /*  number of electric channels   */
   int     nelerefch;            /*  number of electric reference channels   */
   int     nmagch;               /*  number of magnetic channels   */
   int     nmagrefch;            /*  number of magnetic reference channels   */
   int     nauxch;               /*  number of auxiliary channels  */
   int     nparamch;             /*  number of parameter channels  */

   int     data_type;            /*  0 - IEEE_SHORT  */
                                 /*  1 - IEEE_FLOAT  */
                                 /*  2 - PC_SHORT    */
                                 /*  3 - PC_FLOAT    */
   int     acq_type;             /*  0 - Continuous data acquisition */
                                 /*  1 - Segmented data acquisition  */
   float   smpfq;                /*  sampling frequency in Hz        */
   float   low_fr;               /*  low pass frequency at data acquisition   */
   float   hig_fr;               /*  high pass frequency at data acquisition  */

   int     nsamp;                /*  number of samples                        */
   int     ntpsmp;               /*  no. of time points per sample            */
   int     ntpdata;              /*  total number of time points in data      */
   int     nrefchan;             /*  number of reference channels             */
   int     ref_ch[256];          /*  reference channel list                   */
   int     ntpref;               /*  total number of time points in reference */

   int     header_size;          /*  sizeof(header) at the time of file creation  */
   int     header_type;          /*  0 - normal                                   */
                                 /*  1 - master header (mhd)                      */
                                 /*  2 - rawfile (A900)                           */
                                 /*  3 - GE runfile header                        */
                                 /*  4 - ATB runfile header version 1.0           */

   int     start_reference;      /*  start reference   */
   int     start_data;           /*  start data        */

   int     irev;                 /*  release code  */
   int     iftyp;                /*  file type    0 - raw   int*2    multipl.   rte_a header */
                                 /*  file type    1 - ave   float*4  demultipl. old header   */
                                 /*  file type    2 - cov   float*4  demultipl. old header   */
                                 /*  file type    5 - tpl   float*4  demultipl. old header   */
                                 /*  file type    6 - pre   float*4  multipl.   old header   */
                                 /*  file type    7 - rpc   int*2    multipl.   old header   */
                                 /*  file type   10 -       int*2    multipl. runfile header */
                                 /*  file type   20 -       int*2    multipl.   new header   */                                    /*  file type   21 -       float*4  demultipl. new header   */
   int     rawfile;              /*  0 - not a rawfile      1 - rawfile     */

   int        isns;              /*  sensor code   1 - Single channel                  */
                                 /*               28 - Original Rome 28 ch.            */
                                 /*               29 -  ..............                 */
                                 /*               .. -  ..............                 */
                                 /*               .. -  ..............                 */
                                 /*               .. -  ..............                 */
                                 /*               55 - Original Chieti 55 ch. flat     */
                                 /*              153 - Original Chieti 153 ch. helmet  */
                                 /*              154 - Chieti 153 ch. helmet from Jan 2002 */
   
   ch_info    ch[256];           /*  Channel's INFOs  */

   vp_vector  r_center;          /*  sensor position in convenient format */
   vp_vector  u_center;
   float      th_center;         /*  sensor orientation as from markers fit */
   float      fi_center;
   float      rotation_angle;
   vp_vector  cosdir[3];         /*  for compatibility only */
   int        irefsys;           /*  reference system   0 - sensor reference system  */
                                 /*                     1 - kheops                   */
                                 /*                     2 - head3                    */
                                 /*                     3 - MEG                      */

/*  Marker positions for MRI integration  */
   int          num_markers;     /*  Total number of markers                        */
   int          i_coil[64];      /*  Markers to be used to find sensor position     */
   position     marker[64];      /*  Position of all the markers                    */
   float        best_chi;        /*  Best chi_square value obtained in finding sensor position */
   float        zpos_nasion;     /*  z position of the first coil (nasion) + 20 mm  */

   float   cup_vertex_center;      /*  distance of sensor center from vertex  (as entered */
                                   /*  from keyboard)                                     */
   float   cup_fi_center;          /*  fi angle of sensor center             */
   float   cup_rotation_angle;     /*  rotation angle of sensor center axis  */

   float   dist_a1_a2;             /*  head informations  */
                    /*  (used to find subject's head dimensions) */
   float   dist_inion_nasion;
   float   max_circ;
   float   nasion_vertex_inion;

/*  Data analysis INFOs  */
   int     security;             /*  security flag                      */

   int        itri;              /*  trigger channel number             */
   int        ntpch;             /*  no. of time points per channel     */
   int        ntppre;            /*  no. of time points of pretrigger   */
   int        navrg;             /*  no. of averages                    */
   int        nover;             /*  no. of overflows                   */
   vp_filter  ave_filt;          /*  Filters used before average        */

   int     stdev;                /*  0 - not present                    */
   int     bas_start;            /*  starting data points for baseline  */
   int     bas_end;              /*  ending data points for baseline    */

   int     nsmpl;                /*  Number of samples described in the smpl structure   */
   sample_info   smpl[4096];     /*  INFOs on different samples (most like an extended
                                                      trigger list)  */
   char    raw_path[128];        /*  Path of the raw file at time of data analysis  */
   char    raw_name[64];         /*  Raw file name                                  */

   int     source_files[32];     /*  Progressive number of files (if more than one)  */

/*  template INFOs  */
   int          ichtpl;
   int          ntptpl;
   int          ifitpl;
   float        corlim;
   vp_filter    tpl_filt;        /*  Template filter   */
} header;
 


typedef struct
{
   char    lname[16];            /*  first name  */
   char    fname[16];            /*  family name  */
   int     age;                  /*  age  */
   char    date[24];             /*  time and date  (ascii)  */

   int     nchan;                /*  number of channels  */
   int     nelech;               /*  number of electric channels */
   int     nmagch;               /*  number of magnetic channels  */
   int     itri;                 /*  trigger channel number  */
   int     iaqty;                /*  acquisition type  */
   int     ismpfq;               /*  sampling frequency  */
   int     nsamp;                /*  number of samples  */
   int     ntpsmp;               /*  no. of time points per sample  */
   float   amvbit;               /*       mV / bit                  */
   int     nsbit;                /*  no. of significant bits        */
   float   low_fr;               /*  low pass frequency at data acquisition  */
   float   hig_fr;               /*  high pass frequency at data acquisition  */

   int     ntpch;                /*  no. of time points per channel */
   int     ntppre;               /*  no. of time points of pretrigger */
   int     navrg;                /*  no. of averages */
   int     nover;                /*  no. of overflows */

   int     header_size;          /*  sizeof(header) at the time of file creation  */

   int     irev;                 /*  release code */
   int     iftyp;                /*  file type    0 - raw   int*2    multipl.   old header      */
                                 /*  file type    1 - ave   float*4  demultipl. new header      */
                                 /*  file type    2 - cov   float*4  demultipl. new header      */
                                 /*  file type    5 - tpl   float*4  demultipl. new header      */
                                 /*  file type    6 - pre   float*4  multipl.   new header      */
                                 /*  file type    7 - rpc   int*2    multipl.   new header      */
                                 /*  file type   10 -       int*2    multipl.   runfile header  */

   int     isns;                 /*  sensor type  */

   int            ch_type[256];  /*  channel type  */
   ch_position    ch_pos[256];   /*  channel position and orientation */
   float          ch_calb[256];  /*  calibration   */
   unsigned char  ch_flag[256];  /*  0 - channel OK             */
                                 /*  1 - channel NOT OK         */
                                 /*  2 - compensation channel   */

   float   cup_vertex_center;    /*  distance of sensor center from vertex  (as entered */
                                 /*  from keyboard) */
   float   cup_fi_center;        /*  fi angle of sensor center  */
   float   cup_rotation_angle;   /*  rotation angle of sensor center axis  */

   float   dist_a1_a2;           /*  head informations  */
                                 /*  (used to find subject's head dimensions) */
   float   dist_inion_nasion;
   float   max_circ;
   float   nasion_vertex_inion;
   char    head_file_name[128];

   vp_vector  r_center;          /*  sensor position in convenient format */
   vp_vector  u_center;
   float      rotation_angle;
   vp_vector  cosdir[3];         /*  coseni direttori del sistema S' */

/*  template INFOs  */
   int     ichtpl;
   int     ntptpl;
   int     ifitpl;
   float   corlim;

/*  source file numbers  */
   int     source_files[100];

/*  marker positions */
   int          num_markers;    /*  Total number of markers  */
   int          i_coil[20];     /*  Markers to be used to find sensor position  */
   ch_position  marker[20];     /*  Position of all the markers  */
   int          dummy0[342];    /*  reserved for future expansion  */
   float        best_chi;       /*  Best chi_square value obtained in finding sensor position */

/*  other INFOs  */
   int          stdev;          /*  0 - not present   */
   int          bas_start;      /*  starting data points for baseline  */
   int          bas_end;        /*  ending data points for baseline    */
   float        zpos_nasion;    /*  z position of the first coil (nasion) + 20 mm  */
   vp_filter    tpl_filt;       /*  Template filter   */

   int          dummy1[425];       /*  reserved for future expansion  */

}old_header;



/*************************/
/*  function prototypes  */
/*************************/


/*  File functions - vp_lib_file   */

void  vp_find_filename(char *, char *, char *, char *, int, char *, int);
int   vp_file_exist(char *);       
void  vp_get_filename(char *, char *);     
void  vp_get_filepath(char *, char *);
int   vp_get_filenumber(char *);
void  vp_get_filename_noext(char *, char *);
int   vp_read_data(float **, header640, int, int *, int, int, FILE *);
int   vp_read_ch(float *, header640, int, int, int, FILE *);
int   vp_read_data_flag(int *, header640, int, int, int, FILE *);
int   vp_read_data_short(float **, header640, int, int *, int, int, FILE *); 
int   vp_read_data_int(float **, header640, int, int *, int, int, FILE *);
int   vp_read_data_float (float **, header640, int, int *, int, int, FILE *);


/*  Header functions - vp_lib_header   */

header    vp_read_info(FILE *, char *);
header    vp_header640_to_header(header640);
header640 vp_read_header(FILE *, char *);
header640 *vp_read_header_pointer(FILE *, char *);    /* Added May,25 2005 */
header640 vp_read_header_raw(FILE *, char *);
header640 vp_read_old_header640(FILE *);
header640 vp_read_ge_header640(FILE *);
header640 vp_read_atb_header640(FILE *);
header640 vp_read_bmdsys_header640(FILE *);
header640 vp_read_ifn_header640(FILE *);
header640 vp_header_to_header640(header);
header640 vp_read_rtea_header640(FILE *);
header640 vp_read_mhd(char *);
int       vp_setchtype(char *);
int       vp_rnf2header(char *, int *);


/*  Conversion utilities - vp_lib_conv   */

header640  vp_swap_header640(header640);     /*  Swap header                 */
header     vp_swap_header256(header);       
old_header vp_swap_old_header(old_header);         
float      float_rtea2ieee(char *);          /*  Float rtea --> ieee         */
unsigned int float_ieee2rtea(float);         /*  Float ieee --> rtea         */
short      vp_swap_short(short);             /*  Swap single word            */
int        vp_swap_int(int);                                     
float      vp_swap_float(float);                                  
void       vp_swap_array4(void *, int);      /*  Swap array of 4bytes word   */
void       vp_swap_array2(void *, int);      /*  Swap array of 2bytes word   */
short      short_pc2ieee(char *);            /*  short int pc --> ieee       */
void       vp_swapw(char *, char *, int);     
void       vp_swapb(char *, char *, int);

/*  Filter functions - vp_lib_filter   */

void  ii_correlation_flt (float *, float *, int, int);         /*  Correlation    */
void  vp_correlation_flt (float *, float *, int, int);         /*  Correlation    */
void  vp_rectifier_flt   (float *, int, int);                  /*  Rectifier      */
void  vp_artefact_filter (float *, int, int);                  /*  Artefact       */
void  vp_bandpass_filter (float *, int, float, float, float);  /*  Bandpass pass  */
void  vp_fltlp           (float *, float, float, float, int);  /*  Low pass       */
void  vp_flthp           (float *, float, float, float, int);  /*  High pass      */
void  sc_notch_filter    (float *, int, float, float, float);  /*  Notch SC       */
void  sc_four1           (float *, int, int);                  /*  FFT SC         */
void  lm_heart_filter    (float **, char *, int, int, ch_info *, int); /*  Heart filter */     
void  vp_derivate_flt    (float buffer[], int npt);            /*  Derivate       */


/*  General functions - vp_lib_general  */

ch_info  vp_get_ch_info (int, int, int, char*);                /*   Find channel info       */
ch_info  vp_get_ch_pos (int, int, char*);                      /*   Find channel position   */
int      vp_get_channel_number(header, int *, int);  
int      vp_get_ch_number(header640, int *, int);  
int   vp_label2number(header640, char *);       /*   Find channel number from label */
float vp_sum      (float *, int, int);          /*   Find SUM(a(i)) i=1..n) */
float vp_dot      (float *, float *, int);      /*   Find SUM[a(i)*b(i)]    */
float vp_min      (float *, int);              /*   Find minimum           */
float vp_max      (float *, int);              /*   Find maximum           */
float vp_round    (float, float);              /*   Round a number         */
void  vp_meanzero   (float *, int);              /*   Subtract mean          */
void  vp_round_scale(float *, float *);          /*   Round scale values     */

int   vp_findTriggerList(FILE *, header640, trig_sel, sample_info *);


/*  Localization functions - vp_lib_local  */

int        coil_expander_9(position *);
                                        /* split coil into 9 parts to improve flux accuracy */
int        coil_expander_5(float, position *);
                                        /* split coil into 5 parts to improve flux accuracy */
vp_dvector vp_find_G_Element_Mag(vp_dvector, vp_dvector, vp_dvector);
                                        /* find lead field element for a magnetic source    */
vp_dvector vp_find_G_Element_Cur(vp_dvector, vp_dvector, vp_dvector);
                                        /* find lead field element for a current source     */


/*  Graphic functions - vp_lib_graphics  */

void  axes(int, float, float *, float, float, char *, float, float, char *, int);
void  axes_nosb(int, float, float *, float, float, char *, float, float, char *, int);
                                                     /*  Draw axis                  */
void  vp_line_color_index(int, int);                 /*  Set line color index       */
void  vp_text_color_index(int, int);                 /*  Set text color index       */
void  vp_marker_color_index(int, int);               /*  Set marker color index     */


/*  Head utility functions - vp_lib_head  */

void       vp_get_ellipsoid            (ch_position *, float *, float *l, float *);
float      rd_given_th_and_fi          (vp_vector *, float, float);
float      distance_given_th_and_fi    (vp_vector *, float, float);
vp_vector  point_given_fi_and_distance (vp_vector *, float, float);
vp_vector  normal_given_point          (vp_vector *, vp_vector);


/*  Transformation functions - vp_lib_trasf   */
vp_vector  vp_car2sph(vp_vector);
vp_vector  vp_sph2car(vp_vector);
vp_vector  vp_Sp2S(vp_vector, float, float, float, float, float, float);
vp_vector  vp_S2Sp(vp_vector, float, float, float, float, float, float);
vp_vector  vp_rotate(float, float, vp_vector);
vp_vector  vp_inrotate(float, float, vp_vector);
void       vp_polhemus_megasi(int, position *);
void       vp_nmr_meg(int, float, position *, vp_vector *);
void       vp_nmr_dati(int, ch_position *, vp_vector *);
float      vp_arc      (float, float, float);           /*   Find elliptic arc      */
float      vp_angle    (float, float, float);           /*   Find elliptic angle    */

apos       vp_car_sph  (xpos);                       /*   Cartesian --> Spher.   */
xpos       vp_sph_car  (apos);                       /*   Spher. --> Cartesian   */
apos       vp_rot      (float, float, apos);         /*   Rotate point           */
apos       vp_inrot    (float, float, apos);         /*   Inverse of vp_rot      */
xpos       vp_xrot     (float, float, xpos);         /*   Rotate point           */
xpos       vp_inxrot   (float, float, xpos);         /*   Inverse of vp_xrot     */

/*  Old functions   */

void   vp_kheops_nmr(int, float, position *);
char   *vp_handle_filename(char *, char *, char *, int, char *, int);
                                               /*   Handle file name              */
int    vp_file_exist(char *file);              /*   Test if a file already exists */
char   *vp_get_name(char *);                   /*   Isolate file name             */
char   *vp_get_path(char *);                   /*   Isolate file path             */
int    vp_unselech (float *, float *, int *, float *, int);
                                               /*   Unselect channels             */

// #endif
