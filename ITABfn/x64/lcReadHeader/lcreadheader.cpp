#include "mex.h"
#include "matrix.h"
#include <stdio.h>
#include <string.h>
#include "vp_biomag.h"

int biomagreader(header640 *hd,char *fname)
{
   FILE *fp;

   fp = fopen(fname,"rb");
   if (fp==NULL) return -1;
   *hd = vp_read_header(fp,fname);
   fclose(fp);

   return 0;
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{

  int i,l,k;
  header640 info;
  char fname[256];
  int dims1x1[] = {1,1};
  int dims3x1[] = {3,1};
  int dims5x1[] = {5,1};
  int dims10x1[] = {10,1};
  int dims15x1[] = {15,1};
  int dims64x1[] = {64,1};
  int dims640x1[] = {640,1};
  int dims4096x1[] = {4096,1};
  double *ptr;

  /* convert a char into 1 element string */
  char charToString[2];
  charToString[1] = 0;

  /* mix data */
  mxArray *ref_ch;
  mxArray *wgt;
  mxArray *pos;
  mxArray *r_s;
  mxArray *u_s;
  mxArray *comp;


  /*****************************/
  /*                           */
  /*                           */
  /* declare needed structures */
  /*                           */
  /*                           */
  /*****************************/

  
  /* matlab version of header640 (81 fields) */
  const char *fieldsName[]={
                     "stname",
                     "stver",
                     "stendian",
                     "first_name",
                     "last_name",
                     "id",
                     "notes",
                     "sub_info",
                     "time",
                     "date",
                     "nchan",
                     "nelech",
                     "nelerefch",
                     "nmagch",
                     "nmagrefch",
                     "nauxch",
                     "nparamch",
                     "ndigitch",
                     "nflagch",
                     "data_type",
                     "smpfq",
                     "hw_low_fr",
                     "hw_hig_fr",
                     "hw_comb",
                     "sw_hig_tc",
                     "compensation",
                     "ntpdata",
                     "no_segments",
                     "sgmt",
                     "nsmpl",
                     "smpl",
                     "nrefchan",
                     "ref_ch",
                     "ntpref",
                     "raw_header_type",
                     "header_type",
                     "conf_file",
                     "header_size",
                     "start_reference",
                     "start_data",
                     "rawfile",
                     "multiplexed_data",
                     "isns",
                     "ch",
                     "r_center",
                     "u_center",
                     "th_center",
                     "fi_center",
                     "rotation_angle",
                     "cosdir",
                     "irefsys",
                     "num_markers",
                     "i_coil",
                     "marker",
                     "best_chi",
                     "cup_vertex_center",
                     "cup_fi_center",
                     "cup_rotation_angle",
                     "dist_a1_a2",
                     "dist_inion_nasion",
                     "max_circ",
                     "nasion_vertex_inion",
                     "security",
                     "ave_alignement",
                     "itri",
                     "ntpch",
                     "ntppre",
                     "navrg",
                     "nover",
                     "nave_filt",
                     "ave_filt",
                     "stdev",
                     "bas_start",
                     "bas_end",
                     "source_files",
                     "ichtpl",
                     "ntptpl",
                     "ifitpl",
                     "corlim",
                     "tpl_filt",
                     "dummy"
  };

  
  /* structure subj  (7 fields) */
  const char *subjFieldsName[] = {
                                    "sex",
                                    "notes",
                                    "height",
                                    "weight",
                                    "birthday",
                                    "birthmonth",
                                    "birthyear"
  };
  mxArray *sub_info;
  
  /* structure segment_info  (5 fields) */
  const char *segment_infoFieldsName[] = {
                                          "start",
                                          "ntptot",
                                          "type",
                                          "no_samples",
                                          "st_sample"
  };
  mxArray *sgmt;
  
  /* structure sample_info  (5 fields) */
  const char *sample_infoFieldsName[] = {
                                          "start",
                                          "ntptot",
                                          "ntppre",
                                          "type",
                                          "quality"
  };
  mxArray *smpl;

  /* structure ch_info  (10 fields) */
  const char *ch_infoFieldsName[] = {
                                          "type",
                                          "number",
                                          "label",
                                          "flag",
                                          "amvbit",
                                          "calib",
                                          "unit",
                                          "ncoils",
                                          "wgt",
                                          "pos"
  };
  mxArray *ch;

  /* structure vp_vector  (1 field) */
  const char *vp_vectorFieldsName[] = {
                                          "comp"
  };
  mxArray *r_center;
  mxArray *u_center;
  mxArray *cosdir;
 
  /* structure position  (2 fields) */
  const char *positionFieldsName[] = {
                                          "r_s",
                                          "u_s"
  };
  mxArray *marker;

  /* structure gen_flt  (2 fields) */
  const char *gen_fltFieldsName[] = {
                                          "type",
                                          "param"
  };
  mxArray *ave_filt;
  mxArray *tpl_filt;

  
  /* Check for proper number of arguments. */
  if(nrhs < 1) {
      mexPrintf("\nlcReadHeader v2.0\n\n");
      mexPrintf("Reader of biomagnetic data header.\n\n");
      mexPrintf("june 2003 - Luca Ciancetta & Vittorio Pizzella - ITAB institute\n\n");
      mexPrintf("Usage:\n\n");
      mexPrintf("lcreadheader( [path +]file name  )\n\n\n");
      mexPrintf("Example:\n\n");
      mexPrintf("a = lcreadheader('e:/raw/albr01/albr0101.raw')\n\n\n");
      mexPrintf("Result is a struct with header fields.\n\n\n\n");

      mexErrMsgTxt("One input required.");
      return;
  } else if(nlhs > 1) {
      mexPrintf("\nlcReadHeader v2.0\n\n");
      mexPrintf("Reader of biomagnetic data header.\n\n");
      mexPrintf("june 2003 - Luca Ciancetta & Vittorio Pizzella - ITAB institute\n\n");
      mexPrintf("Usage:\n\n");
      mexPrintf("lcreadheader( [path +]file name  )\n\n\n");
      mexPrintf("Example:\n\n");
      mexPrintf("a = lcreadheader('e:/raw/albr01/albr0101.raw')\n\n\n");
      mexPrintf("Result is a struct with header fields.\n\n\n\n");

      mexErrMsgTxt("Too many output arguments");
    
      return;
  }


  /*****************************/
  /*                           */
  /*                           */
  /* create needed structures  */
  /*                           */
  /*                           */
  /*****************************/
  
  /* structure returned */
  plhs[0] = mxCreateStructArray(2,dims1x1,81,fieldsName);
  
  sub_info = mxCreateStructArray(2,dims1x1,7,subjFieldsName);
  sgmt = mxCreateStructArray(2,dims5x1,5,segment_infoFieldsName);
  smpl = mxCreateStructArray(2,dims4096x1,5,sample_infoFieldsName);
  ch = mxCreateStructArray(2,dims640x1,10,ch_infoFieldsName);
  r_center = mxCreateStructArray(2,dims1x1,1,vp_vectorFieldsName);
  u_center = mxCreateStructArray(2,dims1x1,1,vp_vectorFieldsName);
  cosdir = mxCreateStructArray(2,dims3x1,1,vp_vectorFieldsName);
  marker = mxCreateStructArray(2,dims64x1,2,positionFieldsName);
  ave_filt = mxCreateStructArray(2,dims15x1,2,gen_fltFieldsName);
  tpl_filt = mxCreateStructArray(2,dims15x1,2,gen_fltFieldsName);
  
  
  /****************************/
  /*                          */
  /*                          */
  /* Read header              */  
  /*                          */
  /*                          */
  /****************************/


  /* get the file name to read header from*/
  mxGetString(prhs[0],fname,256);
  /* read header */
  if (biomagreader(&info,fname)==-1) {
     mexErrMsgTxt("File not found.");
     return;
  }

  
  
  
  /****************************/
  /*                          */
  /*                          */
  /* Assign header values to  */  
  /* matlab structures        */
  /*                          */
  /*                          */
  /****************************/
  
  mxSetField(plhs[0],0,"stname",mxCreateString(info.stname));
  mxSetField(plhs[0],0,"stver",mxCreateString(info.stver));
  mxSetField(plhs[0],0,"stendian",mxCreateString(info.stendian));
  mxSetField(plhs[0],0,"first_name",mxCreateString(info.first_name));
  mxSetField(plhs[0],0,"last_name",mxCreateString(info.last_name));
  mxSetField(plhs[0],0,"id",mxCreateString(info.id));
  mxSetField(plhs[0],0,"notes",mxCreateString(info.notes));

  charToString[0] = info.sub_info.sex;
  mxSetField(sub_info,0,"sex",mxCreateString(charToString));
  mxSetField(sub_info,0,"notes",mxCreateString(info.sub_info.notes));
  mxSetField(sub_info,0,"height",mxCreateScalarDouble(info.sub_info.height));
  mxSetField(sub_info,0,"weight",mxCreateScalarDouble(info.sub_info.weight));
  mxSetField(sub_info,0,"birthday",mxCreateScalarDouble(info.sub_info.birthday));
  mxSetField(sub_info,0,"birthmonth",mxCreateScalarDouble(info.sub_info.birthmonth));
  mxSetField(sub_info,0,"birthyear",mxCreateScalarDouble(info.sub_info.birthyear));
  mxSetField(plhs[0],0,"sub_info",sub_info);
  
  mxSetField(plhs[0],0,"time",mxCreateString(info.time));
  mxSetField(plhs[0],0,"date",mxCreateString(info.date));
  mxSetField(plhs[0],0,"nchan",mxCreateScalarDouble(info.nchan));
  mxSetField(plhs[0],0,"nelech",mxCreateScalarDouble(info.nelech));
  mxSetField(plhs[0],0,"nelerefch",mxCreateScalarDouble(info.nelerefch));
  mxSetField(plhs[0],0,"nmagch",mxCreateScalarDouble(info.nmagch));
  mxSetField(plhs[0],0,"nmagrefch",mxCreateScalarDouble(info.nmagrefch));
  mxSetField(plhs[0],0,"nauxch",mxCreateScalarDouble(info.nauxch));
  mxSetField(plhs[0],0,"nparamch",mxCreateScalarDouble(info.nparamch));
  mxSetField(plhs[0],0,"ndigitch",mxCreateScalarDouble(info.ndigitch));
  mxSetField(plhs[0],0,"nflagch",mxCreateScalarDouble(info.nflagch));
  mxSetField(plhs[0],0,"data_type",mxCreateScalarDouble(info.data_type));

  mxSetField(plhs[0],0,"smpfq",mxCreateScalarDouble(info.smpfq));
  mxSetField(plhs[0],0,"hw_low_fr",mxCreateScalarDouble(info.hw_low_fr));
  mxSetField(plhs[0],0,"hw_hig_fr",mxCreateScalarDouble(info.hw_hig_fr));
  mxSetField(plhs[0],0,"hw_comb",mxCreateScalarDouble(info.hw_comb));
  mxSetField(plhs[0],0,"sw_hig_tc",mxCreateScalarDouble(info.sw_hig_tc));
  mxSetField(plhs[0],0,"compensation",mxCreateScalarDouble(info.compensation));
  mxSetField(plhs[0],0,"ntpdata",mxCreateScalarDouble(info.ntpdata));
  mxSetField(plhs[0],0,"no_segments",mxCreateScalarDouble(info.no_segments));

  for (i=0;i<5;i++){
     mxSetField(sgmt,i,"start",mxCreateScalarDouble(info.sgmt[i].start));
     mxSetField(sgmt,i,"ntptot",mxCreateScalarDouble(info.sgmt[i].ntptot));
     mxSetField(sgmt,i,"type",mxCreateScalarDouble(info.sgmt[i].type));
     mxSetField(sgmt,i,"no_samples",mxCreateScalarDouble(info.sgmt[i].no_samples));
     mxSetField(sgmt,i,"st_sample",mxCreateScalarDouble(info.sgmt[i].st_sample));
  }
  mxSetField(plhs[0],0,"sgmt",sgmt);
  
  mxSetField(plhs[0],0,"nsmpl",mxCreateScalarDouble(info.nsmpl));

  for (i=0;i<4096;i++){
     mxSetField(smpl,i,"start",mxCreateScalarDouble(info.smpl[i].start));
     mxSetField(smpl,i,"ntptot",mxCreateScalarDouble(info.smpl[i].ntptot));
     mxSetField(smpl,i,"ntppre",mxCreateScalarDouble(info.smpl[i].ntppre));
     mxSetField(smpl,i,"type",mxCreateScalarDouble(info.smpl[i].type));
     mxSetField(smpl,i,"quality",mxCreateScalarDouble(info.smpl[i].quality));
  }
  mxSetField(plhs[0],0,"smpl",smpl);

  mxSetField(plhs[0],0,"nrefchan",mxCreateScalarDouble(info.nrefchan));
  
  ref_ch = mxCreateDoubleMatrix(640,1,mxREAL);
  ptr = mxGetPr(ref_ch);
  for (i=0;i<640;i++)
      *(ptr+i) = (double)info.ref_ch[i];
  mxSetField(plhs[0],0,"ref_ch",ref_ch);

  mxSetField(plhs[0],0,"ntpref",mxCreateScalarDouble(info.ntpref));
  mxSetField(plhs[0],0,"raw_header_type",mxCreateScalarDouble(info.raw_header_type));
  mxSetField(plhs[0],0,"header_type",mxCreateScalarDouble(info.header_type));
  mxSetField(plhs[0],0,"conf_file",mxCreateString(info.conf_file));
  
  mxSetField(plhs[0],0,"header_size",mxCreateScalarDouble(info.header_size));
  mxSetField(plhs[0],0,"start_reference",mxCreateScalarDouble(info.start_reference));
  mxSetField(plhs[0],0,"start_data",mxCreateScalarDouble(info.start_data));
  mxSetField(plhs[0],0,"rawfile",mxCreateScalarDouble(info.rawfile));


  mxSetField(plhs[0],0,"multiplexed_data",mxCreateScalarDouble(info.multiplexed_data));
  mxSetField(plhs[0],0,"isns",mxCreateScalarDouble(info.isns));

  for (i=0;i<640;i++){
     mxSetField(ch,i,"type",mxCreateScalarDouble(info.ch[i].type));
     mxSetField(ch,i,"number",mxCreateScalarDouble(info.ch[i].number));
     mxSetField(ch,i,"label",mxCreateString(info.ch[i].label));
     mxSetField(ch,i,"flag",mxCreateScalarDouble(info.ch[i].flag));
     mxSetField(ch,i,"amvbit",mxCreateScalarDouble(info.ch[i].amvbit));
     mxSetField(ch,i,"calib",mxCreateScalarDouble(info.ch[i].calib));
     mxSetField(ch,i,"unit",mxCreateString(info.ch[i].unit));
     mxSetField(ch,i,"ncoils",mxCreateScalarDouble(info.ch[i].ncoils));

     wgt = mxCreateDoubleMatrix(10,1,mxREAL);
     ptr = mxGetPr(wgt);
     for (l=0;l<10;l++)
         *(ptr+l) = (double)info.ch[i].wgt[l];
     mxSetField(ch,i,"wgt",wgt);

     pos = mxCreateStructArray(2,dims10x1,2,positionFieldsName);
     for (l=0;l<10;l++){
         r_s = mxCreateStructArray(2,dims1x1,1,vp_vectorFieldsName);
         u_s = mxCreateStructArray(2,dims1x1,1,vp_vectorFieldsName);
         comp = mxCreateDoubleMatrix(3,1,mxREAL);
         ptr = mxGetPr(comp);
         for (k=0;k<3;k++)
            *(ptr+k) = (double)info.ch[i].pos[l].r_s.comp[k];
         mxSetField(r_s,0,"comp",comp);

         comp = mxCreateDoubleMatrix(3,1,mxREAL);
         ptr = mxGetPr(comp);
         for (k=0;k<3;k++)
            *(ptr+k) = (double)info.ch[i].pos[l].u_s.comp[k];
         mxSetField(u_s,0,"comp",comp);

         mxSetField(pos,l,"r_s",r_s);
         mxSetField(pos,l,"u_s",u_s);
     }
     mxSetField(ch,i,"pos",pos);
  }
  mxSetField(plhs[0],0,"ch",ch);

  comp = mxCreateDoubleMatrix(3,1,mxREAL);
  ptr = mxGetPr(comp);
  for (k=0;k<3;k++)
      *(ptr+k) = (double)info.r_center.comp[k];
  mxSetField(r_center,0,"comp",comp);
  mxSetField(plhs[0],0,"r_center",r_center);
 
  comp = mxCreateDoubleMatrix(3,1,mxREAL);
  ptr = mxGetPr(comp);
  for (k=0;k<3;k++)
      *(ptr+k) = (double)info.u_center.comp[k];
  mxSetField(u_center,0,"comp",comp);
  mxSetField(plhs[0],0,"u_center",u_center);

  mxSetField(plhs[0],0,"th_center",mxCreateScalarDouble(info.th_center));
  mxSetField(plhs[0],0,"fi_center",mxCreateScalarDouble(info.fi_center));
  mxSetField(plhs[0],0,"rotation_angle",mxCreateScalarDouble(info.rotation_angle));

  for(i=0;i<3;i++){
      comp = mxCreateDoubleMatrix(3,1,mxREAL);
      ptr = mxGetPr(comp);
      for (k=0;k<3;k++)
         *(ptr+k) = (double)info.cosdir[i].comp[k];
      mxSetField(cosdir,i,"comp",comp);
  }
  mxSetField(plhs[0],0,"cosdir",cosdir);

  mxSetField(plhs[0],0,"irefsys",mxCreateScalarDouble(info.irefsys));
  mxSetField(plhs[0],0,"num_markers",mxCreateScalarDouble(info.num_markers));

  comp = mxCreateDoubleMatrix(64,1,mxREAL);
  ptr = mxGetPr(comp);
  for (k=0;k<64;k++)
      *(ptr+k) = (double)info.i_coil[k];
  mxSetField(plhs[0],0,"i_coil",comp);

  for(i=0;i<64;i++){
         r_s = mxCreateStructArray(2,dims1x1,1,vp_vectorFieldsName);
         u_s = mxCreateStructArray(2,dims1x1,1,vp_vectorFieldsName);
         comp = mxCreateDoubleMatrix(3,1,mxREAL);
         ptr = mxGetPr(comp);
         for (k=0;k<3;k++)
            *(ptr+k) = (double)info.marker[i].r_s.comp[k];
         mxSetField(r_s,0,"comp",comp);

         comp = mxCreateDoubleMatrix(3,1,mxREAL);
         ptr = mxGetPr(comp);
         for (k=0;k<3;k++)
            *(ptr+k) = (double)info.marker[i].u_s.comp[k];
         mxSetField(u_s,0,"comp",comp);

         mxSetField(marker,i,"r_s",r_s);
         mxSetField(marker,i,"u_s",u_s);
  }
  mxSetField(plhs[0],0,"marker",marker);

  mxSetField(plhs[0],0,"best_chi",mxCreateScalarDouble(info.best_chi));
  mxSetField(plhs[0],0,"cup_vertex_center",mxCreateScalarDouble(info.cup_vertex_center));
  mxSetField(plhs[0],0,"cup_fi_center",mxCreateScalarDouble(info.cup_fi_center));
  mxSetField(plhs[0],0,"cup_rotation_angle",mxCreateScalarDouble(info.cup_rotation_angle));
  mxSetField(plhs[0],0,"dist_a1_a2",mxCreateScalarDouble(info.dist_a1_a2));
  mxSetField(plhs[0],0,"dist_inion_nasion",mxCreateScalarDouble(info.dist_inion_nasion));
  mxSetField(plhs[0],0,"max_circ",mxCreateScalarDouble(info.max_circ));
  mxSetField(plhs[0],0,"nasion_vertex_inion",mxCreateScalarDouble(info.nasion_vertex_inion));
  mxSetField(plhs[0],0,"security",mxCreateScalarDouble(info.security));
  mxSetField(plhs[0],0,"ave_alignement",mxCreateScalarDouble(info.ave_alignement));
  mxSetField(plhs[0],0,"itri",mxCreateScalarDouble(info.itri));
  mxSetField(plhs[0],0,"ntpch",mxCreateScalarDouble(info.ntpch));
  mxSetField(plhs[0],0,"ntppre",mxCreateScalarDouble(info.ntppre));
  mxSetField(plhs[0],0,"navrg",mxCreateScalarDouble(info.navrg));
  mxSetField(plhs[0],0,"nover",mxCreateScalarDouble(info.nover));
  mxSetField(plhs[0],0,"nave_filt",mxCreateScalarDouble(info.nave_filt));

  for(i=0;i<15;i++){
        mxSetField(ave_filt,i,"type",mxCreateScalarDouble(info.ave_filt[i].type));
        comp = mxCreateDoubleMatrix(5,1,mxREAL);
        ptr = mxGetPr(comp);
        for (k=0;k<5;k++)
           *(ptr+k) = (double)info.ave_filt[i].param[k];
        mxSetField(ave_filt,i,"param",comp);
  }
  mxSetField(plhs[0],0,"ave_filt",ave_filt);

  for(i=0;i<15;i++){
        mxSetField(tpl_filt,i,"type",mxCreateScalarDouble(info.tpl_filt[i].type));
        comp = mxCreateDoubleMatrix(5,1,mxREAL);
        ptr = mxGetPr(comp);
        for (k=0;k<5;k++)
           *(ptr+k) = (double)info.tpl_filt[i].param[k];
        mxSetField(tpl_filt,i,"param",comp);
  }
  mxSetField(plhs[0],0,"tpl_filt",tpl_filt);

  mxSetField(plhs[0],0,"stdev",mxCreateScalarDouble(info.stdev));
  mxSetField(plhs[0],0,"bas_start",mxCreateScalarDouble(info.bas_start));
  mxSetField(plhs[0],0,"bas_end",mxCreateScalarDouble(info.bas_end));

  comp = mxCreateDoubleMatrix(32,1,mxREAL);
  ptr = mxGetPr(comp);
  for (k=0;k<32;k++)
      *(ptr+k) = (double)info.source_files[k];
  mxSetField(plhs[0],0,"source_files",comp);
  
  mxSetField(plhs[0],0,"ichtpl",mxCreateScalarDouble(info.ichtpl));
  mxSetField(plhs[0],0,"ntptpl",mxCreateScalarDouble(info.ntptpl));
  mxSetField(plhs[0],0,"ifitpl",mxCreateScalarDouble(info.ifitpl));
  mxSetField(plhs[0],0,"corlim",mxCreateScalarDouble(info.corlim));
  
  comp = mxCreateDoubleMatrix(64,1,mxREAL);
  ptr = mxGetPr(comp);
  for (k=0;k<64;k++)
      *(ptr+k) = (double)info.dummy[k];
  mxSetField(plhs[0],0,"dummy",comp);

}

